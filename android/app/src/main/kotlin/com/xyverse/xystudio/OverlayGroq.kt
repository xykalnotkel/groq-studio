package com.xyverse.xystudio

import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

/** Klien Groq ringan untuk overlay (SSE). */
class OverlayGroq {

    private val main = Handler(Looper.getMainLooper())
    private val cancelled = AtomicBoolean(false)
    private val generation = AtomicInteger(0)
    @Volatile private var connection: HttpURLConnection? = null

    fun cancel() {
        cancelled.set(true)
        try {
            connection?.disconnect()
        } catch (_: Exception) {
        }
        connection = null
    }

    fun generate(
        apiKey: String,
        mode: OverlayMode,
        brief: String,
        engine: String?,
        onDelta: (String) -> Unit,
        onDone: (String) -> Unit,
        onError: (String) -> Unit,
    ) {
        val id = generation.incrementAndGet()
        cancelled.set(false)
        thread(name = "xystudio-overlay-groq") {
            fun alive() = id == generation.get()
            val models = listOf(
                "openai/gpt-oss-20b",
                "openai/gpt-oss-120b",
                "qwen/qwen3.8-27b",
                "allam-2-7b",
            )
            var lastError = "Semua model gagal."
            var assembled = ""
            for (model in models) {
                if (!alive()) return@thread
                if (cancelled.get()) {
                    main.post { if (alive()) onDone(assembled) }
                    return@thread
                }
                try {
                    assembled = streamOnce(id, apiKey, model, mode, brief, engine, onDelta)
                    if (!alive()) return@thread
                    if (assembled.isNotBlank()) {
                        main.post { if (alive()) onDone(assembled) }
                        return@thread
                    }
                } catch (error: Exception) {
                    if (!alive()) return@thread
                    if (cancelled.get()) {
                        main.post { if (alive()) onDone(assembled) }
                        return@thread
                    }
                    lastError = readable(error)
                    val retryable = (error is OverlayGroqException &&
                        (error.code == 429 || error.code >= 500)) ||
                        lastError.contains("jaringan") ||
                        lastError.contains("koneksi")
                    if (!retryable) {
                        main.post { if (alive()) onError(lastError) }
                        return@thread
                    }
                }
            }
            main.post {
                if (!alive()) return@post
                if (assembled.isNotBlank()) onDone(assembled) else onError(lastError)
            }
        }
    }

    private fun streamOnce(
        id: Int,
        apiKey: String,
        model: String,
        mode: OverlayMode,
        brief: String,
        engine: String?,
        onDelta: (String) -> Unit,
    ): String {
        val body = payload(model, mode, brief, engine)
        val conn = (URL("https://api.groq.com/openai/v1/chat/completions").openConnection() as HttpURLConnection)
        connection = conn
        conn.requestMethod = "POST"
        conn.connectTimeout = 20000
        conn.readTimeout = 90000
        conn.doOutput = true
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("Authorization", "Bearer $apiKey")
        conn.setRequestProperty("Accept", "text/event-stream")
        conn.setRequestProperty("Cache-Control", "no-cache")
        conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }

        val code = conn.responseCode
        if (code !in 200..299) {
            val err = (conn.errorStream ?: conn.inputStream)
                ?.bufferedReader()?.readText().orEmpty()
            conn.disconnect()
            throw OverlayGroqException(messageFor(code, err), code)
        }

        val assembled = StringBuilder()
        BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use { reader ->
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                if (cancelled.get() || id != generation.get()) break
                val raw = line ?: continue
                if (!raw.startsWith("data:")) continue
                val data = raw.substring(5).trim()
                if (data == "[DONE]") break
                val delta = extractDelta(data) ?: continue
                assembled.append(delta)
                val snapshot = assembled.toString()
                main.post { if (id == generation.get()) onDelta(snapshot) }
            }
        }
        conn.disconnect()
        connection = null
        return assembled.toString()
    }

    private fun payload(model: String, mode: OverlayMode, brief: String, engine: String?): String {
        val system = """
            Kamu adalah XyStudio AI, penulis profesional.
            Aturan wajib:
            1. Balas HANYA dengan hasil yang diminta, tanpa basa-basi.
            2. Markdown rapi: ## judul, - poin, **tebal**.
            3. Bahasa keluaran: Bahasa Indonesia.
            4. DILARANG memakai emoji atau simbol dekoratif.
        """.trimIndent()
        val user = buildString {
            if (!engine.isNullOrBlank()) {
                append("ENGINE TARGET: ").append(engine).append('\n')
                append("Sesuaikan parameter dengan engine tersebut.\n\n")
            }
            append("TUGAS:\n").append(mode.instruction).append("\n\n")
            append("OBJEK / BRIEF PENGGUNA:\n\"\"\"\n").append(brief.trim()).append("\n\"\"\"")
        }
        val root = JSONObject()
        root.put("model", model)
        root.put("stream", true)
        root.put("max_tokens", mode.maxTokens.coerceAtMost(2048))
        val gptOss = model.startsWith("openai/gpt-oss")
        if (gptOss) {
            val merged = "INSTRUKSI SISTEM (patuhi sepenuhnya):\n$system\n\n$user"
            root.put(
                "messages",
                JSONArray().put(JSONObject().put("role", "user").put("content", merged)),
            )
            root.put("temperature", 0.6)
            root.put("include_reasoning", false)
            root.put("reasoning_effort", "medium")
        } else {
            val messages = JSONArray()
                .put(JSONObject().put("role", "system").put("content", system))
                .put(JSONObject().put("role", "user").put("content", user))
            root.put("messages", messages)
            root.put("temperature", 0.8)
        }
        return root.toString()
    }

    private fun extractDelta(data: String): String? {
        return try {
            val json = JSONObject(data)
            val choices = json.optJSONArray("choices") ?: return null
            if (choices.length() == 0) return null
            val delta = choices.getJSONObject(0).optJSONObject("delta") ?: return null
            if (!delta.has("content") || delta.isNull("content")) null
            else delta.optString("content")
        } catch (_: Exception) {
            null
        }
    }

    private fun messageFor(code: Int, body: String): String {
        val api = try {
            JSONObject(body).optJSONObject("error")?.optString("message").orEmpty()
        } catch (_: Exception) {
            ""
        }
        return when (code) {
            401, 403 -> "API key tidak valid. Isi ulang di Setelan."
            429 -> "Kuota Groq sedang penuh. Coba sebentar lagi."
            else -> if (code >= 500) "Server Groq bermasalah ($code)."
            else if (api.isNotBlank()) api
            else "Gagal menghubungi Groq ($code)."
        }
    }

    private fun readable(error: Exception): String {
        if (error is OverlayGroqException) return error.message ?: "Gagal."
        val text = error.message.orEmpty()
        if (text.contains("Unable to resolve") || text.contains("Failed to connect")) {
            return "Tidak ada koneksi internet."
        }
        return "Gagal: $text"
    }
}

class OverlayGroqException(message: String, val code: Int) : Exception(message)
