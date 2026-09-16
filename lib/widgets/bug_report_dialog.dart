import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';

/// Formulir laporan bug — pengguna menyusun laporan di dalam aplikasi dulu,
/// baru dikirim ke WhatsApp XyVerse sebagai pesan rapi.
///
/// v3.1: menggantikan link wa.me kosong tanpa konteks.
class BugReportDialog extends StatefulWidget {
  const BugReportDialog({super.key});

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deviceController = TextEditingController();
  final _versionController = TextEditingController(text: AppInfo.version);
  final _storyController = TextEditingController();
  String _mode = 'Tidak spesifik';

  static const List<String> _modes = <String>[
    'Tidak spesifik',
    'Judul',
    'Caption',
    'Artikel',
    'Ide Konten',
    'Pengaturan / Riwayat',
    'Suara (Dengarkan)',
  ];

  @override
  void dispose() {
    _deviceController.dispose();
    _versionController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final buffer = StringBuffer()
      ..writeln('Halo XyVerse! Saya mau lapor bug di XyStudio AI:')
      ..writeln()
      ..writeln('• Perangkat / HP: ${_deviceController.text.trim()}')
      ..writeln('• Versi aplikasi: ${_versionController.text.trim()}')
      ..writeln('• Mode yang dipakai: $_mode')
      ..writeln(
        '• Sistem: ${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion}',
      );
    final story = _storyController.text.trim();
    if (story.isNotEmpty) {
      buffer
        ..writeln('• Cerita singkat:')
        ..writeln(story);
    }

    final url = Uri.parse('https://wa.me/${AppInfo.bugReportPhone}')
        .replace(queryParameters: <String, String>{'text': buffer.toString()});

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan dibuka di WhatsApp — tinggal kirim'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp tidak bisa dibuka. Laporkan lewat menu Tentang.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        size: 20,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Laporkan bug',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Isi dulu di sini, lalu kirim via WhatsApp',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _deviceController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Perangkat / HP',
                    hintText: 'cth. Samsung Galaxy A54, Android 15',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Isi nama perangkat kamu'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _versionController,
                        decoration: const InputDecoration(
                          labelText: 'Versi aplikasi',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Isi versi aplikasi'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _mode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Mode yang dipakai',
                        ),
                        items: <DropdownMenuItem<String>>[
                          for (final mode in _modes)
                            DropdownMenuItem<String>(
                              value: mode,
                              child: Text(
                                mode,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _mode = value ?? _mode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _storyController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Ceritakan bugnya',
                    hintText:
                        'Apa yang kamu lakukan, apa yang terjadi, dan apa '
                        'yang seharusnya terjadi…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Ceritakan dulu bugnya, ya'
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Laporan dikirim ke WhatsApp ${AppInfo.bugReportPhone}. '
                  'Kamu boleh lampirkan screenshot di chat.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _send,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Kirim via WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Buka dialog laporan bug dari mana saja.
Future<void> showBugReportDialog(BuildContext context, {String? source}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const BugReportDialog(),
  );
}
