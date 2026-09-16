import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/controller.dart';
import 'screens/bootstrap.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

class XyStudioApp extends StatelessWidget {
  const XyStudioApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          themeMode: controller.settings.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: AppBootstrap(controller: controller),
          routes: <String, WidgetBuilder>{
            '/home': (_) => RootShell(controller: controller),
          },
        );
      },
    );
  }
}
