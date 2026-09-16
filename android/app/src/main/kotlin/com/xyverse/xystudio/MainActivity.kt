package com.xyverse.xystudio

import android.Manifest
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Activity utama XyStudio AI.
 *
 * Kanal native:
 *  * `xystudio/pip`    — Picture-in-Picture + overlay SYSTEM_ALERT_WINDOW
 *    (izin "tampil di atas aplikasi lain") supaya aplikasi tetap terlihat
 *    walau pengguna meninggalkan aplikasi.
 *  * `xystudio/launch` — intent mode dari widget layar beranda.
 */
class MainActivity : FlutterActivity() {

    private var launchChannel: MethodChannel? = null
    private var pendingMode: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PIP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            handlePipCall(call, result)
        }

        launchChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCH_CHANNEL)
        launchChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchMode" -> {
                    val mode = pendingMode ?: intent?.getStringExtra(EXTRA_MODE)
                    pendingMode = null
                    result.success(mode)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handlePipCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enterPip" -> result.success(enterPip())
            "pipSupported" -> result.success(pipSupported())
            "hasOverlayPermission" -> result.success(hasOverlayPermission())
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(true)
            }
            "startFloating" -> {
                val title = call.argument<String>("title") ?: getString(R.string.app_name)
                val snippet = call.argument<String>("snippet")
                    ?: getString(R.string.overlay_default_snippet)
                val apiKey = call.argument<String>("apiKey") ?: ""
                startFloating(title, snippet, apiKey)
                result.success(true)
            }
            "stopFloating" -> {
                FloatingService.stop(this)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val mode = intent.getStringExtra(EXTRA_MODE)
        if (!mode.isNullOrEmpty()) {
            pendingMode = mode
            launchChannel?.invokeMethod("onLaunchMode", mode)
        }
    }

    private fun pipSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun enterPip(): Boolean {
        if (!pipSupported()) return false
        return try {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setAutoEnterEnabled(true)
            }
            enterPictureInPictureMode(builder.build())
        } catch (_: Exception) {
            false
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
        }
        requestNotificationPermission()
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 42)
            }
        }
    }

    private fun startFloating(title: String, snippet: String, apiKey: String) {
        if (!hasOverlayPermission()) {
            requestOverlayPermission()
            return
        }
        requestNotificationPermission()
        FloatingService.start(this, title, snippet, apiKey)
    }

    companion object {
        const val PIP_CHANNEL = "xystudio/pip"
        const val LAUNCH_CHANNEL = "xystudio/launch"
        const val EXTRA_MODE = "xystudio_mode"
    }
}
