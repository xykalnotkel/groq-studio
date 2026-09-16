package com.xyverse.xystudio

import android.Manifest
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
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
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
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import java.util.Locale
import kotlin.math.abs
import org.json.JSONObject

/**
 * Overlay mengambang: studio mini di atas aplikasi lain.
 * Chip mode, bahasa, nada, generate, dengar, dikte, tempel, bagikan.
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
    private var currentLang: OverlayOption = OverlayCatalog.languages.first()
    private var currentTone: OverlayOption = OverlayCatalog.tones.first()
    private var lastResult: String = ""
    private var speaking = false
    private var listening = false
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var recognizer: SpeechRecognizer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startInForeground()
        tts = TextToSpeech(this) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) {
                tts?.setSpeechRate(1.0f)
                tts?.setPitch(1.0f)
                if (Build.VERSION.SDK_INT >= 21) {
                    tts?.setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build(),
                    )
                }
                applyTtsLanguage()
            }
        }
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
        stopMic()
        stopSpeak()
        try {
            tts?.shutdown()
        } catch (_: Exception) {
        }
        tts = null
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
        val extra = view.findViewById<EditText>(R.id.overlay_extra)
        val result = view.findViewById<TextView>(R.id.overlay_result)
        val generate = view.findViewById<TextView>(R.id.overlay_generate)
        val langView = view.findViewById<TextView>(R.id.overlay_lang)
        val toneView = view.findViewById<TextView>(R.id.overlay_tone)
        val resize = view.findViewById<View>(R.id.overlay_resize)
        val listen = view.findViewById<TextView>(R.id.overlay_listen)
        val mic = view.findViewById<TextView>(R.id.overlay_mic)
        val paste = view.findViewById<TextView>(R.id.overlay_paste)
        val share = view.findViewById<TextView>(R.id.overlay_share)
        val preview = view.findViewById<TextView>(R.id.overlay_preview)

        rebuildModes(view)
        rebuildEngines(view)
        langView.text = currentLang.label
        toneView.text = currentTone.label

        langView.setOnClickListener {
            showChooser("Bahasa hasil", OverlayCatalog.languages.map { it.label }) { index ->
                currentLang = OverlayCatalog.languages[index]
                langView.text = currentLang.label
                applyTtsLanguage()
            }
        }
        toneView.setOnClickListener {
            showChooser("Gaya", OverlayCatalog.tones.map { it.label }) { index ->
                currentTone = OverlayCatalog.tones[index]
                toneView.text = currentTone.label
            }
        }

        view.findViewById<ImageButton>(R.id.overlay_close).setOnClickListener { stopSelf() }
        view.findViewById<ImageButton>(R.id.overlay_panel_close).setOnClickListener {
            collapse(view, layoutParams)
        }
        view.findViewById<View>(R.id.overlay_size_s).setOnClickListener {
            applyPreset(view, layoutParams, 0)
        }
        view.findViewById<View>(R.id.overlay_size_m).setOnClickListener {
            applyPreset(view, layoutParams, 1)
        }
        view.findViewById<View>(R.id.overlay_size_l).setOnClickListener {
            applyPreset(view, layoutParams, 2)
        }

        generate.setOnClickListener {
            setInputFocus(layoutParams, view, false)
            if (busy) {
                groq.cancel()
                busy = false
                generate.text = getString(R.string.overlay_generate)
                return@setOnClickListener
            }
            startGenerate(brief, extra, result, generate)
        }
        view.findViewById<View>(R.id.overlay_copy).setOnClickListener {
            val text = resultText(result)
            if (text.isBlank()) {
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
        share.setOnClickListener {
            val text = resultText(result)
            if (text.isBlank()) {
                toast("Belum ada hasil")
                return@setOnClickListener
            }
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                startActivity(
                    Intent.createChooser(send, "Bagikan hasil").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            } catch (_: Exception) {
                toast("Tidak ada aplikasi untuk berbagi")
            }
        }
        listen.setOnClickListener {
            if (speaking) {
                stopSpeak()
                listen.text = getString(R.string.overlay_listen)
            } else {
                val text = resultText(result)
                if (text.isBlank()) {
                    toast("Belum ada hasil")
                    return@setOnClickListener
                }
                speak(text, listen)
            }
        }
        mic.setOnClickListener { toggleMic(brief, mic) }
        paste.setOnClickListener { pasteClipboard(brief) }
        preview.setOnClickListener {
            if (!expanded) expand(view, layoutParams)
        }

        brief.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) setInputFocus(layoutParams, view, true)
        }
        brief.setOnClickListener { setInputFocus(layoutParams, view, true) }
        extra.setOnFocusChangeListener { _, hasFocus ->
            if (hasFocus) setInputFocus(layoutParams, view, true)
        }
        extra.setOnClickListener { setInputFocus(layoutParams, view, true) }

        attachDrag(view.findViewById(R.id.overlay_title), view, layoutParams)
        attachDrag(fab, view, layoutParams, toggleOnTap = true)
        attachResize(resize, view, layoutParams)
    }

    private fun resultText(result: TextView): String {
        val text = result.text?.toString().orEmpty().trim()
        if (text.isBlank()) return ""
        if (text == getString(R.string.overlay_result_empty)) return ""
        if (text == getString(R.string.overlay_writing)) return ""
        return text
    }

    private fun makeChip(label: String, selected: Boolean, onClick: () -> Unit): TextView {
        val v = TextView(this)
        v.text = label
        v.setTextColor(0xFFFFFFFF.toInt())
        v.textSize = 11.5f
        v.setTypeface(Typeface.DEFAULT_BOLD)
        v.setPadding(dp(10), dp(6), dp(10), dp(6))
        v.background = ContextCompat.getDrawable(
            this,
            if (selected) R.drawable.overlay_chip_on else R.drawable.overlay_chip_bg,
        )
        val lp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        )
        lp.marginEnd = dp(6)
        v.layoutParams = lp
        v.setOnClickListener { onClick() }
        return v
    }

    private fun rebuildModes(view: View) {
        val row = view.findViewById<LinearLayout>(R.id.overlay_modes)
        row.removeAllViews()
        OverlayCatalog.modes.forEach { mode ->
            row.addView(
                makeChip(mode.label, mode.id == currentMode.id) {
                    currentMode = mode
                    currentEngine = mode.engines.firstOrNull()
                    rebuildModes(view)
                    rebuildEngines(view)
                },
            )
        }
    }

    private fun rebuildEngines(view: View) {
        val scroll = view.findViewById<View>(R.id.overlay_engines_scroll)
        val row = view.findViewById<LinearLayout>(R.id.overlay_engines)
        row.removeAllViews()
        val engines = currentMode.engines
        if (engines.isEmpty()) {
            scroll.visibility = View.GONE
            currentEngine = null
            return
        }
        scroll.visibility = View.VISIBLE
        engines.forEach { engine ->
            row.addView(
                makeChip(engine, engine == currentEngine) {
                    currentEngine = engine
                    rebuildEngines(view)
                },
            )
        }
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
                    val w = (startW + (event.rawX - downX)).toInt()
                        .coerceIn(dp(280), screenW() - dp(16))
                    val h = (startH + (event.rawY - downY)).toInt()
                        .coerceIn(dp(380), screenH() - dp(80))
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
        root.findViewById<View>(R.id.overlay_preview).visibility = View.GONE
        highlightPreset(root, prefs().getInt(PREF_PRESET, 1))
        layoutParams.flags = focusedFlags()
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
    }

    private fun collapse(root: View, layoutParams: WindowManager.LayoutParams) {
        expanded = false
        setInputFocus(layoutParams, root, false)
        root.findViewById<View>(R.id.overlay_panel).visibility = View.GONE
        layoutParams.width = WindowManager.LayoutParams.WRAP_CONTENT
        layoutParams.height = WindowManager.LayoutParams.WRAP_CONTENT
        layoutParams.flags = collapsedFlags()
        try {
            windowManager?.updateViewLayout(root, layoutParams)
        } catch (_: Exception) {
        }
        savePos(layoutParams)
        updatePreview(root)
    }

    private fun updatePreview(root: View) {
        val preview = root.findViewById<TextView>(R.id.overlay_preview)
        if (expanded) {
            preview.visibility = View.GONE
            return
        }
        val text = when {
            busy -> getString(R.string.overlay_writing)
            lastResult.isNotBlank() -> lastResult.take(90)
            else -> ""
        }
        if (text.isBlank()) {
            preview.visibility = View.GONE
        } else {
            preview.visibility = View.VISIBLE
            preview.text = text
        }
    }

    private fun applyPreset(
        root: View,
        layoutParams: WindowManager.LayoutParams,
        preset: Int,
        persist: Boolean = true,
    ) {
        val (w, h) = when (preset) {
            0 -> dp(300) to dp(440)
            2 -> dp(380) to dp(660)
            else -> dp(340) to dp(560)
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

    private fun setInputFocus(
        layoutParams: WindowManager.LayoutParams,
        root: View,
        focus: Boolean,
    ) {
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

    private fun startGenerate(
        brief: EditText,
        extra: EditText,
        result: TextView,
        generate: TextView,
    ) {
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
        lastResult = ""
        generate.text = getString(R.string.overlay_stop)
        result.text = getString(R.string.overlay_writing)
        groq.generate(
            apiKey = apiKey,
            mode = currentMode,
            brief = text,
            engine = currentEngine,
            extra = extra.text?.toString().orEmpty(),
            language = currentLang.id,
            tone = currentTone.id,
            onDelta = { snapshot ->
                result.text = snapshot
                lastResult = snapshot
                root?.let { updatePreview(it) }
            },
            onDone = { finalText ->
                busy = false
                generate.text = getString(R.string.overlay_generate)
                lastResult = if (finalText.isBlank()) {
                    getString(R.string.overlay_empty_result)
                } else {
                    finalText
                }
                result.text = lastResult
                root?.let { updatePreview(it) }
            },
            onError = { message ->
                busy = false
                generate.text = getString(R.string.overlay_generate)
                val current = result.text?.toString().orEmpty()
                if (current.isNotBlank() && current != getString(R.string.overlay_writing)) {
                    lastResult = current
                    result.text = current
                    toast(message)
                } else {
                    result.text = message
                }
                root?.let { updatePreview(it) }
            },
        )
    }

    private fun ttsLocale(): Locale {
        return when (currentLang.id) {
            "en" -> Locale.US
            "ms" -> Locale("ms", "MY")
            "ja" -> Locale.JAPAN
            "zh" -> Locale.SIMPLIFIED_CHINESE
            "ar" -> Locale("ar", "SA")
            "es" -> Locale("es", "ES")
            else -> Locale("id", "ID")
        }
    }

    private fun applyTtsLanguage() {
        val engine = tts ?: return
        if (!ttsReady) return
        val wanted = ttsLocale()
        val result = engine.setLanguage(wanted)
        if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
            engine.language = Locale("id", "ID")
        }
    }

    private fun speak(text: String, listen: TextView) {
        if (!ttsReady || tts == null) {
            toast("Suara belum siap. Coba lagi sebentar.")
            return
        }
        applyTtsLanguage()
        val cleaned = text
            .replace(Regex("```[\\s\\S]*?```"), " ")
            .replace(Regex("#{1,6}\\s*"), "")
            .replace(Regex("\\*\\*([^*]+)\\*\\*"), "$1")
            .replace(Regex("\\*([^*]+)\\*"), "$1")
            .trim()
        if (cleaned.isBlank()) {
            toast("Tidak ada teks untuk dibacakan")
            return
        }
        speaking = true
        listen.text = getString(R.string.overlay_stop)
        tts?.setOnUtteranceProgressListener(object : android.speech.tts.UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) {
                speaking = false
                listen.post { listen.text = getString(R.string.overlay_listen) }
            }
            override fun onError(utteranceId: String?) {
                speaking = false
                listen.post {
                    listen.text = getString(R.string.overlay_listen)
                    toast("Gagal membacakan teks")
                }
            }
        })
        val params = Bundle()
        params.putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
        params.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
        val spoken = tts?.speak(cleaned.take(3900), TextToSpeech.QUEUE_FLUSH, params, "xy-overlay")
        if (spoken != TextToSpeech.SUCCESS) {
            speaking = false
            listen.text = getString(R.string.overlay_listen)
            toast("Mesin suara menolak memutar. Cek volume media HP.")
        }
    }

    private fun stopSpeak() {
        speaking = false
        try {
            tts?.stop()
        } catch (_: Exception) {
        }
        root?.findViewById<TextView>(R.id.overlay_listen)?.text = getString(R.string.overlay_listen)
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun toggleMic(brief: EditText, mic: TextView) {
        if (listening) {
            stopMic()
            return
        }
        if (!hasMicPermission()) {
            toast("Buka aplikasi, izinkan mikrofon, lalu nyalakan mengambang lagi.")
            return
        }
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            toast("HP ini tidak punya pengenal suara.")
            return
        }
        try {
            if (recognizer == null) {
                recognizer = SpeechRecognizer.createSpeechRecognizer(this)
                recognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onError(error: Int) {
                        listening = false
                        mic.text = getString(R.string.overlay_mic)
                        toast("Dikte gagal. Coba lagi.")
                    }
                    override fun onResults(results: Bundle?) {
                        listening = false
                        mic.text = getString(R.string.overlay_mic)
                        val spoken = results
                            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull()
                            .orEmpty()
                        if (spoken.isNotBlank()) {
                            val current = brief.text?.toString().orEmpty()
                            brief.setText(
                                if (current.isBlank()) spoken else "$current $spoken",
                            )
                            brief.setSelection(brief.text?.length ?: 0)
                        }
                    }
                    override fun onPartialResults(partialResults: Bundle?) {}
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
            }
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            intent.putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, ttsLocale().toLanguageTag())
            intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            listening = true
            mic.text = getString(R.string.overlay_mic_on)
            recognizer?.startListening(intent)
        } catch (_: Exception) {
            listening = false
            mic.text = getString(R.string.overlay_mic)
            toast("Dikte tidak bisa dimulai.")
        }
    }

    private fun stopMic() {
        listening = false
        try {
            recognizer?.stopListening()
        } catch (_: Exception) {
        }
        try {
            recognizer?.destroy()
        } catch (_: Exception) {
        }
        recognizer = null
        root?.findViewById<TextView>(R.id.overlay_mic)?.text = getString(R.string.overlay_mic)
    }

    private fun pasteClipboard(brief: EditText) {
        val clip = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        val text = clip.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString()?.trim().orEmpty()
        if (text.isBlank()) {
            toast("Papan klip kosong")
            return
        }
        brief.setText(text)
        brief.setSelection(brief.text?.length ?: 0)
        toast("Teks dari papan klip ditempel")
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
