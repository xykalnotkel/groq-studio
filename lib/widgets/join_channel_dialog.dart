import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/controller.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Popup ajakan gabung ke saluran WhatsApp XyVerse.
///
/// * Tombol **X** di pojok untuk menutup.
/// * Centang **Jangan tampilkan lagi** disimpan permanen di perangkat.
/// * Tombol **Laporkan bug** membuka chat WhatsApp.
class JoinChannelDialog extends StatefulWidget {
  const JoinChannelDialog({super.key, required this.controller});

  final AppController controller;

  /// Tampilkan popup bila memang waktunya (dan belum dimatikan pengguna).
  static Future<void> maybeShow(
    BuildContext context,
    AppController controller,
  ) async {
    if (!controller.shouldShowChannelPopup) return;
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: AppMotion.normal,
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.emphasized,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, _) => JoinChannelDialog(controller: controller),
    );
  }

  @override
  State<JoinChannelDialog> createState() => _JoinChannelDialogState();
}

class _JoinChannelDialogState extends State<JoinChannelDialog> {
  bool _dontShowAgain = false;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
    }
  }

  Future<void> _close() async {
    if (_dontShowAgain) {
      await widget.controller.setHideChannelPopup(true);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width > 460 ? 420.0 : size.width - 32;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // ── Gambar header ────────────────────────────────────
                SizedBox(
                  height: 178,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset('assets/wa_channel.png', fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              theme.colorScheme.surface.withValues(alpha: 0.95),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _CircleButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Tutup',
                          onTap: _close,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Isi ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Gabung ${AppInfo.waChannelName}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dapatkan kabar fitur baru, template prompt, dan tips '
                        'nulis pakai AI — langsung di WhatsApp kamu. Gratis.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Benefit(
                        icon: Icons.bolt_rounded,
                        text: 'Update fitur duluan sebelum rilis',
                      ),
                      _Benefit(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Template prompt & ide konten gratis',
                      ),
                      _Benefit(
                        icon: Icons.forum_rounded,
                        text: 'Tanya jawab langsung bareng pengguna lain',
                      ),
                      const SizedBox(height: 16),

                      // Tombol utama
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF25D366),
                                Color(0xFF12A94B),
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashFactory: InkSparkle.splashFactory,
                              onTap: () => _open(AppInfo.waChannelUrl),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.group_add_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 9),
                                  Text(
                                    'Gabung Sekarang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Centang "jangan tampilkan lagi"
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            setState(() => _dontShowAgain = !_dontShowAgain),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: <Widget>[
                              AnimatedContainer(
                                duration: AppMotion.fast,
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  gradient: _dontShowAgain
                                      ? AppTheme.brand
                                      : null,
                                  border: Border.all(
                                    color: _dontShowAgain
                                        ? Colors.transparent
                                        : theme.colorScheme.outline,
                                    width: 1.6,
                                  ),
                                ),
                                child: _dontShowAgain
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Jangan tampilkan lagi',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Laporkan bug
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _open(AppInfo.bugReportUrl),
                          icon: const Icon(Icons.bug_report_rounded, size: 17),
                          label: const Text('Laporkan bug'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF25D366)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.42),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
