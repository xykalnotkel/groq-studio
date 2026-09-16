import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../widgets/about_dialog.dart';
import '../core/controller.dart';
import '../models/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/morphing_background.dart';

import 'package:url_launcher/url_launcher.dart';

import '../widgets/option_sheets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _key = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _key.text = widget.controller.settings.apiKey;
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    FocusScope.of(context).unfocus();
    final value = _key.text.trim();
    await widget.controller.updateSettings(
      widget.controller.settings.copyWith(apiKey: value),
    );
    await widget.controller.refreshModels();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value.isEmpty ? 'API key dihapus' : 'API key tersimpan 🔐',
        ),
      ),
    );
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await widget.controller.testConnection(
      overrideKey: _key.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final settings = widget.controller.settings;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: MorphingScaffoldBody(
            seed: 23,
            opacity: 0.42,
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                children: <Widget>[
                  Text(
                    'Setelan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── API key ────────────────────────────────────────────
                  const SectionLabel('Koneksi Groq'),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextField(
                          controller: _key,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          onSubmitted: (_) => _saveKey(),
                          decoration: InputDecoration(
                            hintText: 'gsk_xxxxxxxxxxxxxxxxxxxx',
                            labelText: 'API key Groq',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _testing ? null : _test,
                                icon: _testing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.wifi_tethering_rounded,
                                        size: 18,
                                      ),
                                label: const Text('Tes koneksi'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GradientButton(
                                label: 'Simpan',
                                icon: Icons.save_rounded,
                                onPressed: _saveKey,
                              ),
                            ),
                          ],
                        ),
                        if (_testResult != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary
                                  .withValues(alpha: 0.10),
                            ),
                            child: Text(
                              _testResult!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await Clipboard.setData(
                              const ClipboardData(text: AppInfo.keysUrl),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Link console Groq disalin. '
                                  'Tempel di browser untuk ambil API key.',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.link_rounded, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppInfo.keysUrl,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                                const Icon(Icons.copy_all_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Key disimpan di perangkat kamu dan dikirim langsung ke '
                          'api.groq.com. Untuk rilis publik, sebaiknya key '
                          'disuntikkan saat build dengan '
                          '--dart-define=GROQ_API_KEY=...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Model ──────────────────────────────────────────────
                  const SectionLabel('Model'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppTheme.brand,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.memory_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            widget.controller.currentModelInfo.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            widget.controller.currentModelInfo.id,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              showModelSheet(context, widget.controller),
                        ),
                        ListTile(
                          leading: const Icon(Icons.bolt_rounded),
                          title: const Text(
                            'Tampilkan kata demi kata (streaming)',
                          ),
                          subtitle: const Text(
                            'Hasil muncul langsung saat ditulis model',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: Switch(
                            value: settings.streaming,
                            onChanged: (value) =>
                                widget.controller.updateSettings(
                                  settings.copyWith(streaming: value),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Keluaran ───────────────────────────────────────────
                  const SectionLabel('Gaya keluaran'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: <Widget>[
                        _PickerTile<OutputLanguage>(
                          icon: Icons.translate_rounded,
                          title: 'Bahasa',
                          value: settings.language.label,
                          options: OutputLanguage.values,
                          selected: settings.language,
                          labelOf: (option) => option.label,
                          onPicked: (picked) =>
                              widget.controller.updateSettings(
                                settings.copyWith(language: picked),
                              ),
                        ),
                        _PickerTile<ToneOption>(
                          icon: Icons.style_rounded,
                          title: 'Nada / gaya',
                          value: settings.tone.label,
                          options: ToneOption.values,
                          selected: settings.tone,
                          labelOf: (option) => option.label,
                          subtitleOf: (option) => option.instruction,
                          onPicked: (picked) => widget.controller
                              .updateSettings(settings.copyWith(tone: picked)),
                        ),
                        _PickerTile<LengthOption>(
                          icon: Icons.straighten_rounded,
                          title: 'Panjang',
                          value: settings.length.label,
                          options: LengthOption.values,
                          selected: settings.length,
                          labelOf: (option) => option.label,
                          subtitleOf: (option) => option.instruction,
                          onPicked: (picked) =>
                              widget.controller.updateSettings(
                                settings.copyWith(length: picked),
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.speed_rounded, size: 20),
                                  const SizedBox(width: 12),
                                  const Expanded(child: Text('Kreativitas')),
                                  Text(
                                    settings.temperature.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: settings.temperature.clamp(0.0, 1.5),
                                min: 0,
                                max: 1.5,
                                divisions: 15,
                                onChanged: (value) =>
                                    widget.controller.updateSettings(
                                      settings.copyWith(temperature: value),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tampilan ───────────────────────────────────────────
                  const SectionLabel('Tampilan'),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                          label: Text('Terang'),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                          label: Text('Gelap'),
                        ),
                      ],
                      selected: <ThemeMode>{settings.themeMode},
                      onSelectionChanged: (selection) =>
                          widget.controller.updateSettings(
                            settings.copyWith(themeMode: selection.first),
                          ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Data ───────────────────────────────────────────────
                  const SectionLabel('Data & lain-lain'),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.delete_sweep_rounded),
                          title: const Text('Hapus semua riwayat'),
                          subtitle: Text(
                            '${widget.controller.history.length} hasil tersimpan',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () async {
                            await widget.controller.clearHistory();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Riwayat dikosongkan'),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.restart_alt_rounded),
                          title: const Text('Kembalikan setelan bawaan'),
                          subtitle: const Text(
                            'API key yang tersimpan tetap dipertahankan',
                            style: TextStyle(fontSize: 11),
                          ),
                          onTap: () async {
                            await widget.controller.updateSettings(
                              Settings(
                                apiKey: widget.controller.settings.apiKey,
                              ),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Setelan dikembalikan ke bawaan'),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.campaign_rounded,
                            color: Color(0xFF25D366),
                          ),
                          title: const Text('Gabung Saluran WA'),
                          subtitle: Text(
                            AppInfo.waChannelName,
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                          ),
                          onTap: () => _openUrl(context, AppInfo.waChannelUrl),
                        ),
                        ListTile(
                          leading: const Icon(Icons.bug_report_rounded),
                          title: const Text('Laporkan bug'),
                          subtitle: const Text(
                            'Chat WhatsApp XyVerse',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                          ),
                          onTap: () => _openUrl(context, AppInfo.bugReportUrl),
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline_rounded),
                          title: const Text('Tentang aplikasi'),
                          subtitle: Text(
                            '${AppInfo.name} v${AppInfo.version} • ${AppInfo.credit}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => showAboutAppDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '${AppInfo.name} v${AppInfo.version} • ${AppInfo.credit} 💜',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickerTile<T> extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onPicked,
    this.subtitleOf,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final String? Function(T option)? subtitleOf;
  final ValueChanged<T> onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
      onTap: () async {
        final picked = await showPickerSheet<T>(
          context: context,
          title: title,
          options: options,
          selected: selected,
          label: labelOf,
          subtitle: subtitleOf,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Tidak bisa membuka $url')));
  }
}
