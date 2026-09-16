package com.xyverse.xystudio

/** Katalog mode overlay — sama dengan aplikasi, supaya generate dari gelembung utuh. */
data class OverlayMode(
    val id: String,
    val label: String,
    val instruction: String,
    val engines: List<String> = emptyList(),
    val maxTokens: Int = 2048,
)

object OverlayCatalog {
    val modes: List<OverlayMode> = listOf(
        OverlayMode(
            "judul", "Judul",
            "Buatkan 10 opsi judul/headline yang menarik dari brief. " +
                "Nomor, maks 12 kata, variasikan gaya. Tandai 3 terbaik [FAVORIT] plus alasan.",
        ),
        OverlayMode(
            "deskripsi", "Deskripsi",
            "Tulis deskripsi singkat (2 paragraf) lalu 5 poin Kenapa ini menarik.",
        ),
        OverlayMode(
            "artikel", "Artikel",
            "Tulis artikel lengkap: judul, pembuka, 4-6 subjudul, kesimpulan, FAQ 3 soal, " +
                "dan baris Meta description maks 155 karakter.",
            maxTokens = 4096,
        ),
        OverlayMode(
            "penjelasan", "Penjelasan Aplikasi",
            "Jelaskan aplikasi/produk: Apa ini, masalah, fitur utama, untuk siapa, cara pakai, kenapa beda.",
        ),
        OverlayMode(
            "store", "Play Store",
            "Listing toko aplikasi: nama, subtitle, deskripsi singkat, deskripsi lengkap tanpa emoji, keyword, What's New.",
        ),
        OverlayMode(
            "caption", "Caption & Hashtag",
            "5 caption berbeda tanpa emoji, CTA, 15 hashtag, 3 ide teks story.",
        ),
        OverlayMode(
            "bio", "Bio Sosmed / Akun",
            "Bio IG, TikTok, X, WhatsApp, plus display name dan username. Tanpa emoji.",
        ),
        OverlayMode(
            "nama", "Ide Nama",
            "15 ide nama + makna + kemudahan diingat. Tandai 3 [FAVORIT].",
        ),
        OverlayMode(
            "rilis", "Catatan Rilis",
            "Catatan rilis versi lengkap, singkat, dan media sosial.",
        ),
        OverlayMode(
            "iklan", "Copy Iklan",
            "Hook, body, CTA, versi Meta, versi Google Ads. Tanpa klaim berlebihan.",
        ),
        OverlayMode(
            "email", "Email & Pengumuman",
            "Subjek, isi email, versi singkat chat, versi follow-up.",
        ),
        OverlayMode(
            "ide", "Brainstorming",
            "15 ide, 3 terbaik dijabarkan, langkah 7 hari, risiko, pertanyaan sebelum mulai.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "script", "Script Video",
            "Hook 3 detik, script [VISUAL]+dialog, CTA, judul, catatan editing.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "gambar", "Prompt Gambar",
            "Prompt utama English, 3 variasi, parameter engine, negative prompt, tips.",
            engines = listOf("Midjourney", "Flux", "SDXL", "DALL-E"),
        ),
        OverlayMode(
            "video-prompt", "Prompt Video",
            "Prompt video English, 3 variasi shot, parameter engine, negative prompt.",
            engines = listOf("Sora", "Veo", "Runway", "Kling"),
        ),
        OverlayMode(
            "kalender", "Kalender Konten",
            "3 pilar, kalender 14 hari, evergreen, serial, metrik.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "terjemah", "Terjemah & Parafrase",
            "Terjemahan natural, 3 parafrase (formal/santai/ringkas), catatan istilah.",
        ),
        OverlayMode(
            "produk", "Deskripsi Produk",
            "Judul, ringkasan, bullet manfaat, deskripsi, spesifikasi, keyword SEO, promo.",
        ),
        OverlayMode(
            "thread", "Thread X / Twitter",
            "Hook, thread 8-12 tweet, penutup, kutipan, hashtag. Maks 240 karakter per tweet.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "seo", "Riset Keyword & SEO",
            "Keyword utama, turunan, meta title/description, outline, judul, FAQ.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "riset", "Riset Web",
            "Riset topik brief: ringkasan eksekutif, temuan, perbandingan, keterbatasan. " +
                "Jujur jika data terbatas.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "url", "Baca & Ringkas URL",
            "Ringkas URL atau teks yang ditempel: TL;DR, ringkasan, poin kunci. Jangan mengarang.",
            maxTokens = 3072,
        ),
        OverlayMode(
            "cs", "Balas Chat Pembeli",
            "3 versi balasan CS: empati, singkat, lengkap. Plus 3 template cepat.",
        ),
        OverlayMode(
            "custom", "Prompt Bebas",
            "Ikuti instruksi pengguna apa adanya.",
            maxTokens = 4096,
        ),
    )

    fun labels(): List<String> = modes.map { it.label }
}
