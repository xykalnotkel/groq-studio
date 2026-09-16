import 'dart:async';

import 'package:flutter/material.dart';

import '../core/controller.dart';
import 'root_shell.dart';
import 'splash_screen.dart';

/// Menampilkan splash screen sebentar, lalu masuk ke aplikasi.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.registerLaunch());
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinished: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }
    return RootShell(controller: widget.controller);
  }
}
