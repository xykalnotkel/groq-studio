import 'package:flutter/material.dart';

import 'core/controller.dart';
import 'core/constants.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

class GroqStudioApp extends StatelessWidget {
  const GroqStudioApp({super.key, required this.controller});

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
          home: RootShell(controller: controller),
        );
      },
    );
  }
}
