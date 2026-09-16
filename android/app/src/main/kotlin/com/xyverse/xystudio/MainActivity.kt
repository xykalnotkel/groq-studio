package com.xyverse.xystudio

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Activity utama XyStudio AI.
 *
 * v3.1 menambahkan dua kanal native:
 *  * `xystudio/pip`    — Picture-in-Picture (mode mengambang) agar aplikasi
 *    tetap terlihat walau pengguna meninggalkan aplikasi.
 *  * `xystudio/launch` — menerima intent mode dari widget layar beranda
 *    (judul/caption/artikel/ide) dan meneruskannya ke Flutter.
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
            when (call.method) {
                "enterPip" -> result.success(enterPip())
                "pipSupported" -> result.success(pipSupported())
                else -> result.notImplemented()
            }
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
                // Otomatis melayang saat pengguna meninggalkan aplikasi.
                builder.setAutoEnterEnabled(true)
            }
            enterPictureInPictureMode(builder.build())
        } catch (exception: Exception) {
            false
        }
    }

    companion object {
        const val PIP_CHANNEL = "xystudio/pip"
        const val LAUNCH_CHANNEL = "xystudio/launch"
        const val EXTRA_MODE = "xystudio_mode"
    }
}
