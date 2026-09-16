import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groq_studio/app.dart';
import 'package:groq_studio/core/controller.dart';
import 'package:groq_studio/core/storage.dart';

void main() {
  setUpAll(() {
    // Jangan menembak jaringan saat tes.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Aplikasi terbuka dan menampilkan halaman utama', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(GroqStudioApp(controller: controller));
    // Latar morphing beranimasi terus, jadi jangan pakai pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Groq Studio'), findsOneWidget);
    expect(find.text('Judul'), findsWidgets);
    expect(find.text('Buat Judul'), findsOneWidget);
  });

  testWidgets('Mode bisa diganti', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final controller = AppController(StorageService());
    await controller.load();

    await tester.pumpWidget(GroqStudioApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Buat Judul'), findsOneWidget);

    await tester.tap(find.text('Artikel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Buat Artikel'), findsOneWidget);
  });
}
