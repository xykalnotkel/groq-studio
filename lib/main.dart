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

  // Tangkap error yang tidak tertangani supaya aplikasi tidak "diam" saja.
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
    runApp(GroqStudioApp(controller: controller));
  }, (error, stack) => debugPrint('Bootstrap error: $error'));
}
