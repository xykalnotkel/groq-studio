import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xystudio/app.dart';
import 'package:xystudio/core/controller.dart';
import 'package:xystudio/core/constants.dart';
import 'package:xystudio/core/storage.dart';

void main() {
  setUpAll(() {
    // Jangan menembak jaringan saat tes.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Aplikasi terbuka dan menampilkan halaman utama', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hide_channel_popup': true,
    });

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(XyStudioApp(controller: controller));
    // Latar morphing beranimasi terus, jadi jangan pakai pumpAndSettle.
    await tester.pump();
    // Lewati splash screen (2,1 detik).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('XyStudio AI'), findsOneWidget);
    expect(find.text('Judul'), findsWidgets);
    expect(find.text('Buat Judul'), findsOneWidget);
  });

  testWidgets('Mode bisa diganti', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'hide_channel_popup': true,
    });

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(XyStudioApp(controller: controller));
    await tester.pump();
    // Lewati splash screen (2,1 detik).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Buat Judul'), findsOneWidget);

    await tester.tap(find.text('Artikel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Buat Artikel'), findsOneWidget);
  });

  testWidgets('Popup saluran WA muncul & bisa dimatikan', (
    WidgetTester tester,
  ) async {
    // Tanpa preferensi apa pun → popup harus tampil di bukaan pertama.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(XyStudioApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Gabung ${AppInfo.waChannelName}'), findsOneWidget);
    expect(find.text('Jangan tampilkan lagi'), findsOneWidget);
    expect(find.text('Laporkan bug'), findsOneWidget);

    // Centang lalu tutup lewat tombol X.
    await tester.tap(find.text('Jangan tampilkan lagi'));
    await tester.pump();
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.hideChannelPopup, isTrue);
    expect(find.text('Gabung ${AppInfo.waChannelName}'), findsNothing);
  });
}
