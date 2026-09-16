// Menghasilkan screenshot aplikasi yang BENAR-BENAR dari UI asli
// (Flutter golden test) untuk keperluan Play Store / promosi.
//
// Cara menjalankan:
//   flutter test --tags=screenshot --update-goldens
// Hasilnya ada di test/goldens/*.png (1080x1920).
//
// Test ini dikecualikan dari CI (--exclude-tags=screenshot) karena
// hanya dipakai saat ingin memperbarui gambar promosi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groq_studio/app.dart';
import 'package:groq_studio/core/controller.dart';
import 'package:groq_studio/core/storage.dart';
import 'package:groq_studio/models/generation_mode.dart';
import 'package:groq_studio/models/settings.dart';
import 'package:groq_studio/theme/app_theme.dart';
import 'package:groq_studio/widgets/mode_selector.dart';
import 'package:groq_studio/widgets/result_view.dart';

// Ukuran file PNG akhir (standar Play Store).
const Size kGolden = Size(1080, 1920);
// Ukuran layar HP dalam logical pixel — supaya tata letaknya tetap proporsional.
const Size kLogical = Size(411, 731);
const double kScale = 1080 / 411; // ≈ 2.63

/// Membingkai aplikasi seolah-olah tampil di layar HP, lalu dirender
/// pada resolusi 1080x1920 supaya tajam untuk materi promosi.
Widget _phoneFrame(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      key: const Key('phone-frame'),
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: kGolden.width,
        height: kGolden.height,
        child: FittedBox(
          alignment: Alignment.topLeft,
          fit: BoxFit.fill,
          child: MediaQuery(
            data: const MediaQueryData(
              size: kLogical,
              devicePixelRatio: kScale,
              padding: EdgeInsets.only(top: 24),
              viewPadding: EdgeInsets.only(top: 24),
              viewInsets: EdgeInsets.zero,
              textScaler: TextScaler.noScaling,
            ),
            child: SizedBox(
              width: kLogical.width,
              height: kLogical.height,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _setPhone(WidgetTester tester) async {
  tester.view.physicalSize = kGolden;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const String _sampleArticle = '''
## Dompet Kos, Hati Tenang: Cara Anak Kos Mengatur Uang

Mengatur keuangan waktu kos itu berat, apalagi kalau uang bulanan datangnya
nggak tentu. Kabar baiknya, kamu nggak butuh sistem yang rumit — cukup tiga
langkah kecil yang dilakukan konsisten.

## Kenapa catatan manual sering gagal

Kebanyakan orang berhenti mencatat karena prosesnya terlalu lama. Begitu
struk menumpuk, semangat pun ikut hilang.

- **Terlalu banyak kolom** — bikin malas membuka aplikasinya
- **Nggak ada pengingat** — baru sadar setelah tanggal tua
- **Lupa tujuan** — tidak ada target yang jelas

## Langkah 1: Pisahkan uang di hari pertama

Begitu uang masuk, langsung bagi ke tiga pos: kebutuhan pokok, tabungan,
dan jajan. Angkanya bebas, yang penting konsisten.

## Langkah 2: Catat sekali foto

Simpan struk dengan memotretnya. Satu detik per transaksi jauh lebih
realistis daripada mengetik nominal satu per satu.

> Kebiasaan kecil yang dilakukan setiap hari mengalahkan sistem hebat yang
> cuma dipakai seminggu.

## Langkah 3: Evaluasi tiap minggu

Luangkan 10 menit di akhir pekan untuk melihat ke mana uangmu pergi.

## Kesimpulan

Mulai dari yang paling kecil. Kalau kamu bisa konsisten dua minggu,
sisanya akan mengikuti.

### FAQ

**Berapa persen ideal untuk tabungan?**
Tidak ada angka pasti. Mulai dari 10% dan naikkan perlahan.

**Bagaimana kalau uang bulanan telat?**
Pakai aturan 50/30/20 sementara sampai kondisi stabil.

**Perlu aplikasi berbayar?**
Tidak. Yang penting konsisten mencatat, bukan alatnya.

Meta description: Cara praktis anak kos mengatur keuangan bulan

an dengan tiga langkah sederhana yang realistis dan mudah dilakukan.
''';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('01 — Halaman utama', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _setPhone(tester);

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(_phoneFrame(GroqStudioApp(controller: controller)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byKey(const Key('phone-frame')),
      matchesGoldenFile('goldens/01_home.png'),
    );
  }, tags: <String>['screenshot']);

  testWidgets('02 — Hasil generate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _setPhone(tester);

    await tester.pumpWidget(
      _phoneFrame(
        MaterialApp(
          theme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          home: const SafeArea(
            child: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(18),
                child: _ResultPreview(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('phone-frame')),
      matchesGoldenFile('goldens/02_hasil.png'),
    );
  }, tags: <String>['screenshot']);

  testWidgets('03 — Riwayat', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'history': jsonEncode(<Map<String, dynamic>>[
        HistorySeed(
          modeId: 'penjelasan',
          modeLabel: 'Penjelasan Aplikasi',
          brief: 'Aplikasi pencatat keuangan anak kos, bisa scan struk',
          output: 'Dompet Kos adalah aplikasi pencatat keuangan…',
          minutesAgo: 25,
        ).toJson(),
        HistorySeed(
          modeId: 'judul',
          modeLabel: 'Judul',
          brief: 'Artikel tentang cara hemat uang untuk mahasiswa baru',
          output: '10 judul artikel hemat uang…',
          minutesAgo: 180,
        ).toJson(),
        HistorySeed(
          modeId: 'caption',
          modeLabel: 'Caption & Hashtag',
          brief: 'Promo kopi susu literan buka cabang baru dekat kampus',
          output: '5 caption Instagram + 15 hashtag…',
          minutesAgo: 60 * 26,
        ).toJson(),
        HistorySeed(
          modeId: 'artikel',
          modeLabel: 'Artikel',
          brief: 'Panduan lengkap budgeting untuk pemula',
          output: 'Artikel 1200 kata tentang budgeting…',
          minutesAgo: 60 * 24 * 3,
          favorite: true,
        ).toJson(),
      ]),
    });

    await _setPhone(tester);
    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(_phoneFrame(GroqStudioApp(controller: controller)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Riwayat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byKey(const Key('phone-frame')),
      matchesGoldenFile('goldens/03_riwayat.png'),
    );
  }, tags: <String>['screenshot']);

  testWidgets('04 — Setelan', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _setPhone(tester);

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(_phoneFrame(GroqStudioApp(controller: controller)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Setelan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byKey(const Key('phone-frame')),
      matchesGoldenFile('goldens/04_setelan.png'),
    );
  }, tags: <String>['screenshot']);

  testWidgets('05 — Mode lengkap', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _setPhone(tester);

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(_phoneFrame(GroqStudioApp(controller: controller)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Geser daftar mode agar mode baru (Script Video, Prompt Gambar,
    // Kalender Konten) ikut terlihat di screenshot.
    await tester.drag(find.byType(ModeSelector), const Offset(-620, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    await expectLater(
      find.byKey(const Key('phone-frame')),
      matchesGoldenFile('goldens/05_mode.png'),
    );
  }, tags: <String>['screenshot']);
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview();

  @override
  Widget build(BuildContext context) {
    return ResultView(
      text: _sampleArticle,
      mode: GenerationMode.fromId('artikel'),
      model: Settings.defaultModel,
      elapsed: const Duration(milliseconds: 4200),
    );
  }
}

/// Data contoh untuk mengisi layar Riwayat saat membuat screenshot.
class HistorySeed {
  HistorySeed({
    required this.modeId,
    required this.modeLabel,
    required this.brief,
    required this.output,
    required this.minutesAgo,
    this.favorite = false,
  });

  final String modeId;
  final String modeLabel;
  final String brief;
  final String output;
  final int minutesAgo;
  final bool favorite;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': modeId + minutesAgo.toString(),
    'modeId': modeId,
    'modeLabel': modeLabel,
    'brief': brief,
    'extra': '',
    'output': output,
    'model': Settings.defaultModel,
    'createdAt': DateTime.now()
        .subtract(Duration(minutes: minutesAgo))
        .toIso8601String(),
    'favorite': favorite,
  };
}
