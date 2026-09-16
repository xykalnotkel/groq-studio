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
  }) {
    final system = <String>[
      'Kamu adalah Groq Studio, penulis dan content strategist profesional '
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
    ].join('\n');

    final buffer = StringBuffer()
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

    return BuiltPrompt(system: system, user: buffer.toString());
  }

  /// Token maksimal yang dipakai untuk sebuah mode.
  static int maxTokensFor(GenerationMode mode) => mode.maxTokens;

  /// Temperatur efektif: nilai mode dipadukan dengan slider pengguna.
  static double temperatureFor(GenerationMode mode, Settings settings) {
    final merged = (mode.temperature + settings.temperature) / 2;
    return merged.clamp(0.0, 2.0);
  }
}
