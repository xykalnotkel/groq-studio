import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';
import 'bug_report_dialog.dart';

/// Dialog Tentang aplikasi, lengkap dengan credit **Built in XyVerse**.
Future<void> showAboutAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const _AboutDialog(),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  Future<void> _open(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: AppTheme.brand,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/app_icon_512.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppInfo.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versi ${AppInfo.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: <Color>[
                    AppColors.violet.withValues(alpha: 0.16),
                    AppColors.cyan.withValues(alpha: 0.16),
                  ],
                ),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.3),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final dark = theme.brightness == Brightness.dark;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Image.asset(
                        dark
                            ? 'assets/xyverse_icon_white.png'
                            : 'assets/xyverse_icon_black.png',
                        height: 16,
                        width: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        AppInfo.credit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Studio menulis AI untuk judul, artikel, caption, script video, '
              'dan prompt gambar. Ditenagai Groq.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),
            _AboutTile(
              icon: Icons.campaign_rounded,
              label: 'Gabung ${AppInfo.waChannelName}',
              color: const Color(0xFF25D366),
              onTap: () => _open(context, AppInfo.waChannelUrl),
            ),
            _AboutTile(
              icon: Icons.bug_report_rounded,
              label: 'Laporkan bug',
              // v3.1: formulir dulu, baru kirim ke WhatsApp.
              onTap: () => showBugReportDialog(context),
            ),
            _AboutTile(
              icon: Icons.code_rounded,
              label: 'Source code di GitHub',
              onTap: () => _open(context, AppInfo.githubUrl),
            ),
            _AboutTile(
              icon: Icons.vpn_key_rounded,
              label: 'Ambil API key Groq',
              onTap: () => _open(context, AppInfo.keysUrl),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 19, color: color ?? theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 17),
      onTap: onTap,
    );
  }
}
