import '../models/generation_mode.dart';
import '../models/settings.dart';

/// Hasil rangkaian prompt: system + user message.
class BuiltPrompt {
  const BuiltPrompt({required this.system, required this.user});

  final String system;
  final String user;
}

/// Menyusun prompt dari mode + preferensi pengguna + brief.
class PromptBuilder {
  const PromptBuilder._();

  static BuiltPrompt build({
    required GenerationMode mode,
    required Settings settings,
    required String brief,
    String extra = '',
    String? engine,
    String? sourcesBlock,
  }) {
    final system = <String>[
      'Kamu adalah XyStudio AI, penulis dan content strategist profesional '
          'yang bekerja di dalam aplikasi Android.',
      '',
      'Aturan wajib:',
      '1. Balas HANYA dengan hasil yang diminta. Tanpa pembuka seperti '
          '"Tentu, berikut hasilnya" dan tanpa basa-basi penutup.',
      '2. Gunakan format Markdown yang rapi dan mudah dibaca di layar HP: '
          'judul pakai ##, poin pakai -, penekanan pakai **tebal**.',
      '3. Bahasa keluaran: ${settings.language.label} (kode: ${settings.language.code}).',
      '4. Gaya penulisan: ${settings.tone.instruction}.',
      '5. Panjang: ${settings.length.instruction}.',
      '6. Jika brief pengguna kurang jelas, buat asumsi yang masuk akal dan '
          'langsung kerjakan daripada bertanya balik.',
      '7. Jangan mengarang fakta spesifik seperti harga, alamat, atau '
          'nama orang. Gunakan placeholder bila perlu.',
      '8. DILARANG KERAS menggunakan emoji atau simbol dekoratif apa pun '
          'di seluruh jawaban — tulis teks polos saja.',
    ].join('\n');

    final buffer = StringBuffer();

    if (engine != null && engine.isNotEmpty) {
      buffer
        ..writeln('ENGINE TARGET: $engine')
        ..writeln(
          'Sesuaikan seluruh parameter dan sintaks dengan engine target '
          'tersebut.',
        )
        ..writeln();
    }

    buffer
      ..writeln('TUGAS:')
      ..writeln(mode.instruction)
      ..writeln()
      ..writeln('OBJEK / BRIEF PENGGUNA:')
      ..writeln('"""')
      ..writeln(brief.trim())
      ..writeln('"""');

    if (extra.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('TAMBAHAN (target audiens, kata kunci, catatan):')
        ..writeln('"""')
        ..writeln(extra.trim())
        ..writeln('"""');
    }

    if (sourcesBlock != null && sourcesBlock.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(sourcesBlock);
    }

    return BuiltPrompt(system: system, user: buffer.toString());
  }

  /// Blok sumber untuk mode Riset Web.
  static String researchBlock(String topic, String sources) =>
      'SUMBER WEB (hasil pencarian yang sudah dibuka aplikasi untuk topik '
      '"$topic"):\n\n$sources';

  /// Blok sumber untuk mode Baca & Ringkas URL.
  static String urlBlock(String url, String title, String content) =>
      'ISI HALAMAN (diambil langsung oleh aplikasi dari $url'
      '${title.isEmpty ? '' : ' — "$title"'}):\n\n$content';

  /// Token maksimal yang dipakai untuk sebuah mode.
  static int maxTokensFor(GenerationMode mode) => mode.maxTokens;

  /// Temperatur efektif: nilai mode dipadukan dengan slider pengguna.
  static double temperatureFor(GenerationMode mode, Settings settings) {
    final merged = (mode.temperature + settings.temperature) / 2;
    return merged.clamp(0.0, 2.0);
  }
}
