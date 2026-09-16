package com.xyverse.xystudio

import android.app.AlertDialog
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.TypedValue
import android.view.ContextThemeWrapper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import kotlin.math.abs
import org.json.JSONObject

/**
 * Overlay mengambang: gelembung bisa digeser, panel bisa diubah ukurannya,
 * dan generate jalan di atas aplikasi lain.
 */
class FloatingService : Service() {

    private var windowManager: WindowManager? = null
    private var root: View? = null
    private var params: WindowManager.LayoutParams? = null
    private var expanded = false
    private var busy = false
    private var apiKey: String = ""
    private val groq = OverlayGroq()
    private var currentMode: OverlayMode = OverlayCatalog.modes.first()
    private var currentEngine: String? = null

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
        apiKey = resolveApiKey(intent?.getStringExtra(EXTRA_API_KEY))
        if (root == null) {
            showOverlay()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        groq.cancel()
        removeOverlay()
        super.onDestroy()
    }

    private fun resolveApiKey(extra: String?): String {
        if (!extra.isNullOrBlank()) {
            prefs().edit().putString(PREF_API, extra).apply()
            return extra
        }
        val saved = prefs().getString(PREF_API, "").orEmpty()
        if (saved.isNotBlank()) return saved
        return try {
            val flutter = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val raw = flutter.getString("flutter.settings", null) ?: return ""
            JSONObject(raw).optString("apiKey", "")
        } catch (_: Exception) {
            ""
        }
    }

    private fun prefs() = getSharedPreferences("xystudio_overlay", MODE_PRIVATE)

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()

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

    private fun showOverlay() {
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            collapsedFlags(),
            PixelFormat.TRANSLUCENT,
        )
        layoutParams.gravity = Gravity.TOP or Gravity.START
        layoutParams.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN
        val stored = prefs()
        layoutParams.x = stored.getInt(PREF_X, dp(24))
        layoutParams.y = stored.getInt(PREF_Y, dp(160))

        val themed = ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault)
        val view = LayoutInflater.from(themed).inflate(R.layout.overlay_panel, null)
        bind(view, layoutParams)

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        try {
            windowManager?.addView(view, layoutParams)
        } catch (_: Exception) {
            stopSelf()
            return
        }
        root = view
        params = layoutParams
    }

    private fun bind(view: View, layoutParams: WindowManager.LayoutParams) {
        val fab = view.findViewById<View>(R.id.overlay_fab)
        val brief = view.findViewById<EditText>(R.id.overlay_brief)
        val result = view.findViewById<TextView>(R.id.overlay_result)
        val generate = view.findViewById<TextView>(R.id.overlay_generate)
        val modeView = view.findViewById<TextView>(R.id.overlay_mode)
        val engineView = view.findViewById<TextView>(R.id.overlay_engine)
        val resize = view.findViewById<View>(R.id.overlay_resize)

        fun syncMode() {
            modeView.text = currentMode.label
            val engines = currentMode.engines
            if (engines.isEmpty()) {
                engineView.visibility = View.GONE
                currentEngine = null
            } else {
                if (currentEngine == null || currentEngine !in engines) {
                    currentEngine = engines.first()
                }
                engineView.visibility = View.VISIBLE
                engineView.text = currentEngine
            }
        }
        syncMode()
        modeView.setOnClickListener {
            showChooser("Mode", OverlayCatalog.labels()) { index ->
                currentMode = OverlayCatalog.modes[index]
                currentEngine = currentMode.engines.firstOrNull()
                syncMode()
            }
        }
        engineView.setOnClickListener {
            val engines = currentMode.engines
            if (engines.isEmpty()) return@setOnClickListener
            showChooser("Engine", engines) { index ->
                currentEngine = engines[index]
                engineView.text = currentEngine
            }
        }

        view.findViewById<ImageButton>(R.id.overlay_close).setOnClickListener { stopSelf() }
        view.findViewById<ImageButton>(R.id.overlay_panel_close).setOnClickListener {
            collapse(view, layoutParams)
        }
        view.findViewById<View>(R.id.overlay_size_s).setOnClickListener { applyPreset(view, layoutParams, 0) }
        view.findViewById<View>(R.id.overlay_size_m).setOnClickListener { applyPreset(view, layoutParams, 1) }
        view.findViewById<View>(R.id.overlay_size_l).setOnClickListener { applyPreset(view, layoutParams, 2) }

        generate.setOnClickListener {
            setInputFocus(layoutParams, view, false)
            if (busy) {
                groq.cancel()
                busy = false
                generate.text = getString(R.string.overlay_generate)
                return@setOnClickListener
            }
            startGenerate(brief, result, generate)
        }
        view.findViewById<View>(R.id.overlay_copy).setOnClickListener {
            val text = result.text?.toString().orEmpty()
            if (text.isBlank() || text == getString(R.string.overlay_result_empty)) {
                toast("Belum ada hasil")
                return@setOnClickListener
            }
            val clip = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            clip.setPrimaryClip(ClipData.newPlainText("XyStudio", text))
            toast("Teks disalin")
        }
        view.findViewById<View>(R.id.overlay_open).setOnClickListener {
            startActivity(
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
            )
        }

        brief.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) setInputFocus(layoutParams, view, true)
        }
        brief.setOnClickListener { setInputFocus(layoutParams, view, true) }

        attachDrag(view.findViewById(R.id.overlay_title), view, layoutParams)
        attachDrag(fab, view, layoutParams, toggleOnTap = true)
        attachResize(resize, view, layoutParams)
    }

    private fun overlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun showChooser(title: String, items: List<String>, onPick: (Int) -> Unit) {
        val dialog = AlertDialog.Builder(
            ContextThemeWrapper(this, android.R.style.Theme_DeviceDefault_Dialog_Alert),
        )
            .setTitle(title)
            .setItems(items.toTypedArray()) { _, which -> onPick(which) }
            .create()
        try {
            dialog.window?.setType(overlayType())
            dialog.show()
        } catch (_: Exception) {
            toast("Tidak bisa buka daftar")
        }
    }

    private var dragging = false

    private fun attachDrag(
        handle: View,
        root: View,
        layoutParams: WindowManager.LayoutParams,
        toggleOnTap: Boolean = false,
    ) {
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        handle.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = layoutParams.x
                    startY = layoutParams.y
                    dragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (abs(dx) > 12 || abs(dy) > 12) dragging = true
                    if (dragging) {
                        layoutParams.x = (startX + dx).toInt().coerceAtLeast(0)
                        layoutParams.y = (startY + dy).toInt().coerceAtLeast(0)
                        try {
                            windowManager?.updateViewLayout(root, layoutParams)
                        } catch (_: Exception) {
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (dragging) {
                        savePos(layoutParams)
                    } else if (toggleOnTap) {
                        toggleExpanded(root, layoutParams)
                    }
                    val was = dragging
                    dragging = false
                    was
                }
                MotionEvent.ACTION_CANCEL -> {
                    dragging = false
                    true
                }
                else -> false
            }
        }
    }

    private fun attachResize(handle: View, root: View, layoutParams: WindowManager.LayoutParams) {
        var downX = 0f
        var downY = 0f
        var startW = 0
        var startH = 0
        handle.setOnTouchListener { _, event ->
            val panel = root.findViewById<View>(R.id.overlay_panel)
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startW = panel.width
                    startH = panel.height
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val w = (startW + (event.rawX - downX)).toInt().coerceIn(dp(260), screenW() - dp(16))
                    val h = (startH + (event.rawY - downY)).toInt().coerceIn(dp(340), screenH() - dp(80))
                    val lp = panel.layoutParams
                    lp.width = w
                    lp.height = h
                    panel.layoutParams = lp
                    layoutParams.width = WindowManager.LayoutParams.WRAP_CONTENT
                    layoutParams.height = WindowManager.LayoutParams.WRAP_CONTENT
                    try {
                        windowManager?.updateViewLayout(root, layoutParams)
                    } catch (_: Exception) {
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    prefs().edit()
                        .putInt(PREF_W, panel.layoutParams.width)
                        .putInt(PREF_H, panel.layoutParams.height)
                        .apply()
                    true
                }
                else -> false
            }
        }
    }

    private fun screenW() = resources.displayMetrics.widthPixels
    private fun screenH() = resources.displayMetrics.heightPixels

    private fun toggleExpanded(root: View, layoutParams: WindowManager.LayoutParams) {
        if (expanded) collapse(root, layoutParams) else expand(root, layoutParams)
    }

    private fun expand(root: View, layoutParams: WindowManager.LayoutParams) {
        expanded = true
        val panel = root.findViewById<View>(R.id.overlay_panel)
        val preset = prefs().getInt(PREF_PRESET, 1)
        val storedW = prefs().getInt(PREF_W, 0)
        val storedH = prefs().getInt(PREF_H, 0)
        if (storedW > 0 && storedH > 0) {
            val lp = panel.layoutParams
            lp.width = storedW
            lp.height = storedH
            panel.layoutParams = lp
        } else {
            applyPreset(root, layoutParams, preset, persist = false)
        }
        panel.visibility = View.VISIBLE
        highlightPreset(root, prefs().getInt(PREF_PRESET, 1))
        layoutParams.flags = focusedFlags()
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
    }

    private fun collapse(root: View, layoutParams: WindowManager.LayoutParams) {
        expanded = false
        groq.cancel()
        busy = false
        setInputFocus(layoutParams, root, false)
        root.findViewById<View>(R.id.overlay_panel).visibility = View.GONE
        root.findViewById<TextView>(R.id.overlay_generate).text = getString(R.string.overlay_generate)
        layoutParams.width = WindowManager.LayoutParams.WRAP_CONTENT
        layoutParams.height = WindowManager.LayoutParams.WRAP_CONTENT
        layoutParams.flags = collapsedFlags()
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
        savePos(layoutParams)
    }

    private fun applyPreset(
        root: View,
        layoutParams: WindowManager.LayoutParams,
        preset: Int,
        persist: Boolean = true,
    ) {
        val (w, h) = when (preset) {
            0 -> dp(280) to dp(400)
            2 -> dp(360) to dp(620)
            else -> dp(320) to dp(500)
        }
        val panel = root.findViewById<View>(R.id.overlay_panel)
        val lp = panel.layoutParams
        lp.width = w.coerceAtMost(screenW() - dp(16))
        lp.height = h.coerceAtMost(screenH() - dp(90))
        panel.layoutParams = lp
        highlightPreset(root, preset)
        if (persist) {
            prefs().edit()
                .putInt(PREF_PRESET, preset)
                .putInt(PREF_W, lp.width)
                .putInt(PREF_H, lp.height)
                .apply()
        }
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
    }

    private fun highlightPreset(root: View, preset: Int) {
        val ids = intArrayOf(R.id.overlay_size_s, R.id.overlay_size_m, R.id.overlay_size_l)
        ids.forEachIndexed { index, id ->
            root.findViewById<TextView>(id).setTextColor(
                if (index == preset) 0xFFFFFFFF.toInt() else 0xFFC9C9DC.toInt(),
            )
        }
    }

    private fun collapsedFlags(): Int =
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

    private fun focusedFlags(): Int =
        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

    private fun setInputFocus(layoutParams: WindowManager.LayoutParams, root: View, focus: Boolean) {
        layoutParams.flags = if (expanded || focus) focusedFlags() else collapsedFlags()
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
        val brief = root.findViewById<EditText>(R.id.overlay_brief)
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (focus) {
            brief.requestFocus()
            imm.showSoftInput(brief, InputMethodManager.SHOW_IMPLICIT)
        } else {
            imm.hideSoftInputFromWindow(brief.windowToken, 0)
        }
    }

    private fun startGenerate(brief: EditText, result: TextView, generate: TextView) {
        val text = brief.text?.toString()?.trim().orEmpty()
        if (text.isEmpty()) {
            toast("Tulis brief-nya dulu")
            return
        }
        if (apiKey.isBlank()) {
            result.text = getString(R.string.overlay_need_key)
            return
        }
        busy = true
        generate.text = getString(R.string.overlay_stop)
        result.text = getString(R.string.overlay_writing)
        groq.generate(
            apiKey = apiKey,
            mode = currentMode,
            brief = text,
            engine = currentEngine,
            onDelta = { snapshot -> result.text = snapshot },
            onDone = { finalText ->
                busy = false
                generate.text = getString(R.string.overlay_generate)
                result.text = if (finalText.isBlank()) getString(R.string.overlay_empty_result) else finalText
            },
            onError = { message ->
                busy = false
                generate.text = getString(R.string.overlay_generate)
                val current = result.text?.toString().orEmpty()
                if (current.isNotBlank() && current != getString(R.string.overlay_writing)) {
                    result.text = current
                    toast(message)
                } else {
                    result.text = message
                }
            },
        )
    }

    private fun savePos(layoutParams: WindowManager.LayoutParams) {
        prefs().edit().putInt(PREF_X, layoutParams.x).putInt(PREF_Y, layoutParams.y).apply()
    }

    private fun toast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }

    private fun removeOverlay() {
        try {
            if (root != null) windowManager?.removeView(root)
        } catch (_: Exception) {
        }
        root = null
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
        const val EXTRA_API_KEY = "overlay_api_key"
        const val CHANNEL_ID = "xystudio_overlay"
        const val NOTIF_ID = 3201
        private const val PREF_X = "x"
        private const val PREF_Y = "y"
        private const val PREF_W = "w"
        private const val PREF_H = "h"
        private const val PREF_PRESET = "preset"
        private const val PREF_API = "api_key"

        fun start(context: Context, title: String, snippet: String, apiKey: String) {
            val intent = Intent(context, FloatingService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_SNIPPET, snippet)
                putExtra(EXTRA_API_KEY, apiKey)
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
