package com.xyverse.xystudio

import android.Manifest
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Activity utama XyStudio AI.
 *
 * Kanal native:
 *  * `xystudio/pip`    — overlay SYSTEM_ALERT_WINDOW + PiP
 *  * `xystudio/launch` — widget, share, dan "proses teks"
 *  * `xystudio/voice`  — dikte brief di dalam aplikasi
 */
class MainActivity : FlutterActivity() {

    private var launchChannel: MethodChannel? = null
    private var pendingMode: String? = null
    private var pendingShared: String? = null
    private var voiceResult: MethodChannel.Result? = null
    private var appRecognizer: SpeechRecognizer? = null

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
                "getSharedText" -> {
                    val text = pendingShared ?: extractShared(intent)
                    pendingShared = null
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VOICE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listen" -> startAppListen(result)
                "stop" -> {
                    stopAppListen()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureShare(intent)
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
        setIntent(intent)
        val mode = intent.getStringExtra(EXTRA_MODE)
        if (!mode.isNullOrEmpty()) {
            pendingMode = mode
            launchChannel?.invokeMethod("onLaunchMode", mode)
        }
        val shared = extractShared(intent)
        if (!shared.isNullOrBlank()) {
            pendingShared = shared
            launchChannel?.invokeMethod("onSharedText", shared)
        }
    }

    private fun extractShared(intent: Intent?): String? {
        if (intent == null) return null
        val send = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!send.isNullOrBlank()) return send.trim()
        val process = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        if (!process.isNullOrBlank()) return process.trim()
        return null
    }

    private fun captureShare(intent: Intent?) {
        val text = extractShared(intent)
        if (!text.isNullOrBlank()) pendingShared = text
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

    private fun requestMicPermission() {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), 43)
        }
    }

    private fun startFloating(title: String, snippet: String, apiKey: String) {
        if (!hasOverlayPermission()) {
            requestOverlayPermission()
            return
        }
        requestNotificationPermission()
        requestMicPermission()
        FloatingService.start(this, title, snippet, apiKey)
    }

    private fun startAppListen(result: MethodChannel.Result) {
        if (voiceResult != null) {
            result.error("busy", "Dikte sedang berjalan.", null)
            return
        }
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            requestMicPermission()
            result.error("permission", "Izinkan mikrofon dulu, lalu ketuk Dikte lagi.", null)
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.error("unavailable", "HP ini tidak punya pengenal suara.", null)
            return
        }
        voiceResult = result
        try {
            appRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            appRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onError(error: Int) {
                    finishVoice(null, "Dikte gagal. Coba lagi.")
                }
                override fun onResults(results: Bundle?) {
                    val spoken = results
                        ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.firstOrNull()
                    finishVoice(spoken, null)
                }
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            intent.putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale("id", "ID").toLanguageTag())
            appRecognizer?.startListening(intent)
        } catch (_: Exception) {
            finishVoice(null, "Dikte tidak bisa dimulai.")
        }
    }

    private fun finishVoice(text: String?, error: String?) {
        val pending = voiceResult
        voiceResult = null
        stopAppListen()
        if (pending == null) return
        if (!error.isNullOrBlank() && text.isNullOrBlank()) {
            pending.error("listen", error, null)
        } else {
            pending.success(text.orEmpty())
        }
    }

    private fun stopAppListen() {
        try {
            appRecognizer?.stopListening()
        } catch (_: Exception) {
        }
        try {
            appRecognizer?.destroy()
        } catch (_: Exception) {
        }
        appRecognizer = null
    }

    override fun onDestroy() {
        stopAppListen()
        super.onDestroy()
    }

    companion object {
        const val PIP_CHANNEL = "xystudio/pip"
        const val LAUNCH_CHANNEL = "xystudio/launch"
        const val VOICE_CHANNEL = "xystudio/voice"
        const val EXTRA_MODE = "xystudio_mode"
    }
}
