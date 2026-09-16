import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/controller.dart';
import 'core/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Jangan biarkan layar jadi abu-abu polos saat ada error render
  // (default Flutter release mode = kotak abu tanpa penjelasan).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Color(0xFF141424),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Tampilan hasil bermasalah. Buka tab Riwayat, atau tekan '
              'Ulangi di halaman Buat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEDEDF5),
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('Flutter error: ${details.exception}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    return true;
  };

  final storage = StorageService();
  final controller = AppController(storage);

  runZonedGuarded<void>(() async {
    await controller.load();
    runApp(XyStudioApp(controller: controller));
  }, (error, stack) => debugPrint('Bootstrap error: $error'));
}
