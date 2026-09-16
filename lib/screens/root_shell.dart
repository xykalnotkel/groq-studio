import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../widgets/join_channel_dialog.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

/// Kerangka utama: empat tab (Buat, Riwayat, Papan, Setelan).
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    // Popup ajakan gabung saluran WA tampil setelah halaman siap.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await JoinChannelDialog.maybeShow(context, widget.controller);
    });
  }

  void _goTo(int index) => setState(() => _index = index);

  void _onBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tekan sekali lagi untuk keluar')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            HomeScreen(
              controller: widget.controller,
              onOpenSettings: () => _goTo(3),
            ),
            HistoryScreen(controller: widget.controller),
            LeaderboardScreen(controller: widget.controller),
            SettingsScreen(controller: widget.controller),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded),
              label: 'Buat',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard_rounded),
              label: 'Papan',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Setelan',
            ),
          ],
        ),
      ),
    );
  }
}
