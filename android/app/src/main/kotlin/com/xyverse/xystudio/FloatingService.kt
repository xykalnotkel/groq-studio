package com.xyverse.xystudio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.TextView
import kotlin.math.abs

/**
 * Overlay mengambang (SYSTEM_ALERT_WINDOW) supaya XyStudio tetap terlihat
 * di atas aplikasi lain — bukan cuma Picture-in-Picture.
 */
class FloatingService : Service() {

    private var windowManager: WindowManager? = null
    private var bubble: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var expanded = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startInForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: getString(R.string.app_name)
        val snippet = intent?.getStringExtra(EXTRA_SNIPPET)
            ?: getString(R.string.overlay_default_snippet)
        if (bubble == null) {
            showBubble(title, snippet)
        } else {
            bubble?.findViewById<TextView>(R.id.overlay_title)?.text = title
            bubble?.findViewById<TextView>(R.id.overlay_snippet)?.text = snippet
        }
        return START_STICKY
    }

    override fun onDestroy() {
        removeBubble()
        super.onDestroy()
    }

    private fun startInForeground() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.overlay_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            manager.createNotificationChannel(channel)
        }

        val openApp = PendingIntent.getActivity(
            this,
            11,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            pendingFlags(),
        )
        val stop = PendingIntent.getService(
            this,
            12,
            Intent(this, FloatingService::class.java).setAction(ACTION_STOP),
            pendingFlags(),
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.overlay_notification))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openApp)
            .addAction(0, getString(R.string.overlay_close), stop)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun showBubble(title: String, snippet: String) {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        )
        layoutParams.gravity = Gravity.TOP or Gravity.END
        layoutParams.x = 24
        layoutParams.y = 180

        val view = LayoutInflater.from(this).inflate(R.layout.overlay_bubble, null)
        view.findViewById<TextView>(R.id.overlay_title).text = title
        view.findViewById<TextView>(R.id.overlay_snippet).text = snippet
        view.findViewById<View>(R.id.overlay_card).visibility = View.GONE

        view.findViewById<View>(R.id.overlay_fab).setOnClickListener {
            expanded = !expanded
            view.findViewById<View>(R.id.overlay_card).visibility =
                if (expanded) View.VISIBLE else View.GONE
        }
        view.findViewById<ImageButton>(R.id.overlay_close).setOnClickListener {
            stopSelf()
        }
        view.findViewById<View>(R.id.overlay_open).setOnClickListener {
            val launch = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(launch)
        }

        attachDrag(view, layoutParams)

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        windowManager?.addView(view, layoutParams)
        bubble = view
        params = layoutParams
    }

    private fun attachDrag(view: View, layoutParams: WindowManager.LayoutParams) {
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false

        view.findViewById<View>(R.id.overlay_fab).setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = layoutParams.x
                    startY = layoutParams.y
                    dragging = false
                    false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (abs(dx) > 12 || abs(dy) > 12) dragging = true
                    if (dragging) {
                        // Gravity END: x membesar ke kiri.
                        layoutParams.x = (startX - dx).toInt().coerceAtLeast(0)
                        layoutParams.y = (startY + dy).toInt().coerceAtLeast(0)
                        try {
                            windowManager?.updateViewLayout(view, layoutParams)
                        } catch (_: Exception) {
                        }
                        true
                    } else {
                        false
                    }
                }
                MotionEvent.ACTION_UP -> dragging
                else -> false
            }
        }
    }

    private fun removeBubble() {
        try {
            if (bubble != null) windowManager?.removeView(bubble)
        } catch (_: Exception) {
        }
        bubble = null
        windowManager = null
    }

    private fun pendingFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return flags
    }

    companion object {
        const val ACTION_STOP = "com.xyverse.xystudio.STOP_FLOATING"
        const val EXTRA_TITLE = "overlay_title"
        const val EXTRA_SNIPPET = "overlay_snippet"
        const val CHANNEL_ID = "xystudio_overlay"
        const val NOTIF_ID = 3201

        fun start(context: Context, title: String, snippet: String) {
            val intent = Intent(context, FloatingService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_SNIPPET, snippet)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, FloatingService::class.java))
        }
    }
}
