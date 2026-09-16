import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/controller.dart';
import '../models/generation_mode.dart';
import '../models/settings.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/morphing_action_button.dart';
import '../widgets/morphing_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mode_selector.dart';
import '../widgets/option_sheets.dart';
import '../widgets/result_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenSettings,
  });

  final AppController controller;
  final VoidCallback onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  GenerationMode _mode = GenerationMode.values.first;
  String? _engine;
  final TextEditingController _brief = TextEditingController();
  final TextEditingController _extra = TextEditingController();

  static const MethodChannel _pipChannel = MethodChannel('xystudio/pip');
  static const MethodChannel _launchChannel = MethodChannel('xystudio/launch');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // v3.1: buka aplikasi dari widget beranda → langsung ke mode terkait.
    _launchChannel.setMethodCallHandler(_handleLaunchCall);
    _launchChannel
        .invokeMethod<String>('getLaunchMode')
        .then(_applyWidgetMode)
        .catchError((Object _) {}); // tanpa implementasi native (web/test).
  }

  Future<dynamic> _handleLaunchCall(MethodCall call) async {
    if (call.method == 'onLaunchMode') {
      _applyWidgetMode(call.arguments as String?);
    }
    return null;
  }

  void _applyWidgetMode(String? id) {
    if (id == null || id.isEmpty) return;
    final mode = GenerationMode.fromId(id);
    if (mode.id != id) return; // id tidak dikenal — abaikan.
    if (!mounted) return;
    setState(() => _mode = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dibuka dari widget: ${mode.label}')),
    );
  }

  /// Mode mengambang: minta izin "tampil di atas aplikasi lain", lalu
  /// tampilkan gelembung overlay + PiP (kalau perangkat mendukung).
  Future<void> _enterPip() async {
    try {
      final hasOverlay =
          await _pipChannel.invokeMethod<bool>('hasOverlayPermission') ?? false;
      if (!hasOverlay) {
        await _pipChannel.invokeMethod<bool>('requestOverlayPermission');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izinkan "Tampilkan di atas aplikasi lain", lalu tekan tombol mengambang lagi.',
            ),
          ),
        );
        return;
      }

      final snippet = controller.output.trim();
      await _pipChannel.invokeMethod('startFloating', <String, String>{
        'title': AppInfo.name,
        'apiKey': controller.apiKey,
        'snippet': snippet.isEmpty
            ? 'Siap menulis di atas aplikasi lain.'
            : (snippet.length > 120
                  ? '${snippet.substring(0, 120)}…'
                  : snippet),
      });

      final pipOk = await _pipChannel.invokeMethod<bool>('enterPip') ?? false;
      if (!mounted) return;
      if (!pipOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mengambang aktif. Ketuk gelembung untuk generate, geser untuk pindah, K/S/B atau sudut kanan bawah untuk ukuran.',
            ),
          ),
        );
      }
    } catch (_) {
      // Platform non-Android — abaikan diam-diam.
    }
  }

  @override
  void dispose() {
    _brief.dispose();
    _extra.dispose();
    super.dispose();
  }

  AppController get controller => widget.controller;

  void _generate() {
    if (!controller.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Isi API key Groq dulu di tab Setelan ya'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: widget.onOpenSettings,
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    controller.generate(
      mode: _mode,
      brief: _brief.text,
      extra: _extra.text,
      engine: _engine,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: IgnorePointer(child: MorphingBackground(opacity: 0.5)),
              ),
              CustomScrollView(
                slivers: <Widget>[
                  _Header(
                    controller: controller,
                    onOpenSettings: widget.onOpenSettings,
                    onEnterPip: _enterPip,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 150),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        const SectionLabel('Mau dibuatin apa?'),
                        ModeSelector(
                          selected: _mode,
                          onSelected: (mode) => setState(() {
                            _mode = mode;
                            _engine = mode.engines.isEmpty
                                ? null
                                : mode.engines.first;
                          }),
                        ),
                        if (_mode.usesEngines) ...<Widget>[
                          const SizedBox(height: 14),
                          _EnginePicker(
                            engines: _mode.engines,
                            selected: _engine,
                            color: _mode.color,
                            onSelected: (engine) =>
                                setState(() => _engine = engine),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SectionLabel(
                          _mode.inputLabel,
                          trailing: TextButton.icon(
                            onPressed: () {
                              _brief.clear();
                              _extra.clear();
                            },
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Kosongkan'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        _BriefCard(
                          mode: _mode,
                          brief: _brief,
                          extra: _extra,
                          controller: controller,
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Hasil'),
                        _buildResultSection(context),
                      ]),
                    ),
                  ),
                ],
              ),
              _ActionBar(
                controller: controller,
                mode: _mode,
                onGenerate: _generate,
                onStop: controller.stop,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultSection(BuildContext context) {
    late final Widget child;
    late final String key;

    if (controller.status == GenerationStatus.error) {
      key = 'error';
      child = _ErrorCard(
        message: controller.errorMessage ?? 'Terjadi kesalahan.',
        onRetry: _generate,
      );
    } else if (controller.output.trim().isEmpty && controller.isBusy) {
      key = 'loading';
      child = _LoadingCard(mode: _mode, message: controller.statusMessage);
    } else if (controller.output.trim().isEmpty) {
      key = 'empty';
      child = _TipsCard(onPick: (text) => setState(() => _brief.text = text));
    } else {
      key = 'result';
      child = ResultView(
        text: controller.output,
        mode: _mode,
        model: controller.answeredByLabel,
        elapsed: controller.elapsed,
        streaming: controller.status == GenerationStatus.streaming,
        onRegenerate: controller.regenerate,
        onStop: controller.stop,
        controller: controller,
      );
    }

    // Morph halus antar keadaan (kosong → loading → hasil → error).
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.emphasized,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: morphTransition,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: <Widget>[...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey<String>(key),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onOpenSettings,
    required this.onEnterPip,
  });

  final AppController controller;
  final VoidCallback onOpenSettings;
  final VoidCallback onEnterPip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 132,
      backgroundColor: dark ? const Color(0xFF0A0A14) : const Color(0xFFF4F4FA),
      flexibleSpace: FlexibleSpaceBar(
        background: MorphingBackground(
          seed: 7,
          opacity: dark ? 0.65 : 0.42,
          duration: const Duration(seconds: 18),
          colors: const <Color>[
            AppColors.indigo,
            AppColors.violet,
            AppColors.pink,
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        title: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.brand,
                borderRadius: BorderRadius.circular(13),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _ModelChip(controller: controller),
              ),
            ),
            const SizedBox(width: 2),
            if (defaultTargetPlatform == TargetPlatform.android)
              IconButton(
                tooltip: 'Mengambang: generate di atas aplikasi lain, bisa digeser dan diubah ukurannya',
                onPressed: onEnterPip,
                icon: const Icon(Icons.picture_in_picture_alt_rounded),
              ),
            IconButton(
              tooltip: 'Setelan',
              onPressed: onOpenSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = controller.currentModelInfo.label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showModelSheet(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline),
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.memory_rounded, size: 14),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input
// ─────────────────────────────────────────────────────────────────────────────
class _BriefCard extends StatelessWidget {
  const _BriefCard({
    required this.mode,
    required this.brief,
    required this.extra,
    required this.controller,
  });

  final GenerationMode mode;
  final TextEditingController brief;
  final TextEditingController extra;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = controller.settings;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: brief,
            maxLines: 5,
            minLines: 3,
            textCapitalization: mode.kind == ModeKind.standard
                ? TextCapitalization.sentences
                : TextCapitalization.none,
            keyboardType: mode.kind == ModeKind.urlSummary
                ? TextInputType.url
                : TextInputType.multiline,
            autocorrect: mode.kind != ModeKind.urlSummary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            decoration: InputDecoration(
              hintText: mode.placeholder,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                height: 1.5,
              ),
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
            ),
          ),
          if (mode.kind != ModeKind.urlSummary) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: extra,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: mode.usesEngines
                    ? 'Tambahan: gaya visual, negative prompt, catatan (opsional)'
                    : 'Tambahan: target audiens, kata kunci, catatan (opsional)',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SettingChip(
                icon: Icons.translate_rounded,
                label: settings.language.label,
                onTap: () async {
                  final picked = await showPickerSheet<OutputLanguage>(
                    context: context,
                    title: 'Bahasa hasil',
                    options: OutputLanguage.values,
                    selected: settings.language,
                    label: (option) => option.label,
                  );
                  if (picked != null) {
                    await controller.updateSettings(
                      settings.copyWith(language: picked),
                    );
                  }
                },
              ),
              _SettingChip(
                icon: Icons.style_rounded,
                label: settings.tone.label,
                onTap: () async {
                  final picked = await showPickerSheet<ToneOption>(
                    context: context,
                    title: 'Gaya penulisan',
                    options: ToneOption.values,
                    selected: settings.tone,
                    label: (option) => option.label,
                    subtitle: (option) => option.instruction,
                  );
                  if (picked != null) {
                    await controller.updateSettings(
                      settings.copyWith(tone: picked),
                    );
                  }
                },
              ),
              _SettingChip(
                icon: Icons.straighten_rounded,
                label: settings.length.label,
                onTap: () async {
                  final picked = await showPickerSheet<LengthOption>(
                    context: context,
                    title: 'Panjang hasil',
                    options: LengthOption.values,
                    selected: settings.length,
                    label: (option) => option.label,
                    subtitle: (option) => option.instruction,
                  );
                  if (picked != null) {
                    await controller.updateSettings(
                      settings.copyWith(length: picked),
                    );
                  }
                },
              ),
              _SettingChip(
                icon: Icons.speed_rounded,
                label: 'Kreativitas ${settings.temperature.toStringAsFixed(1)}',
                onTap: () => _showTemperatureSheet(context, controller),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTemperatureSheet(
    BuildContext context,
    AppController controller,
  ) async {
    final theme = Theme.of(context);
    var value = controller.settings.temperature;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.speed_rounded),
                        const SizedBox(width: 10),
                        Text(
                          'Tingkat kreativitas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          value.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rendah = lebih konsisten & fokus. Tinggi = lebih liar & kreatif.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    Slider(
                      value: value,
                      min: 0,
                      max: 1.5,
                      divisions: 15,
                      onChanged: (next) => setSheetState(() => value = next),
                    ),
                    GradientButton(
                      label: 'Terapkan',
                      icon: Icons.check_rounded,
                      onPressed: () async {
                        await controller.updateSettings(
                          controller.settings.copyWith(temperature: value),
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SettingChip extends StatelessWidget {
  const _SettingChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hasil
// ─────────────────────────────────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.onPick});

  final ValueChanged<String> onPick;

  static const List<String> _samples = <String>[
    'Saya baru saja bikin aplikasi pengingat minum air, jelasin aplikasinya',
    'Aplikasi to-do list dengan AI yang bisa memecah tugas besar jadi langkah kecil',
    'Kursus desain grafis untuk pemula yang ingin freelance',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belum ada hasil',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pilih mode di atas, tulis sedikit tentang idemu, lalu tekan tombol di bawah. '
            'Contoh yang bisa kamu pakai:',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ..._samples.map(
            (sample) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onPick(sample),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sample,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.mode, this.message});

  final GenerationMode mode;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: mode.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message ?? 'Sedang menulis…',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List<Widget>.generate(4, (index) {
            // Garis kerangka statis yang tenang — tanpa shimmer.
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: mode.color.withValues(alpha: index.isEven ? 0.16 : 0.10),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar({required this.delay, required this.color});

  final int delay;
  final Color color;

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.color.withValues(
              alpha: 0.10 + 0.18 * _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderColor: theme.colorScheme.error.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Gagal',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.controller,
    required this.mode,
    required this.onGenerate,
    required this.onStop,
  });

  final AppController controller;
  final GenerationMode mode;
  final VoidCallback onGenerate;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final busy = controller.isBusy;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: (dark ? const Color(0xFF0A0A14) : const Color(0xFFF4F4FA))
              .withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.6),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: MorphingActionButton(
            label: 'Buat ${mode.label}',
            icon: Icons.auto_awesome_rounded,
            busy: busy && controller.output.isEmpty,
            streaming: controller.status == GenerationStatus.streaming,
            onPressed: busy ? onStop : onGenerate,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pilihan engine (prompt gambar / prompt video)
// ─────────────────────────────────────────────────────────────────────────────
class _EnginePicker extends StatelessWidget {
  const _EnginePicker({
    required this.engines,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final List<String> engines;
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Engine target',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final engine in engines)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(engine),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: engine == selected
                        ? LinearGradient(
                            colors: <Color>[
                              color.withValues(alpha: 0.95),
                              color.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    color: engine == selected
                        ? null
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          ),
                    border: Border.all(
                      color: engine == selected
                          ? color
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    engine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: engine == selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
