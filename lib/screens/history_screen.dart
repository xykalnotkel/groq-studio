import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../models/generation_mode.dart';
import '../models/history_item.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/morphing_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/markdown_lite.dart';
import '../widgets/option_sheets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HistoryItem> get _items {
    final query = _query.trim().toLowerCase();
    final items = widget.controller.history;
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.brief.toLowerCase().contains(query) ||
              item.output.toLowerCase().contains(query) ||
              item.modeLabel.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = _items;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: MorphingScaffoldBody(
            seed: 11,
            opacity: 0.42,
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Riwayat',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ),
                              if (widget.controller.history.isNotEmpty)
                                IconButton(
                                  tooltip: 'Hapus semua',
                                  onPressed: () => _confirmClear(context),
                                  icon: const Icon(Icons.delete_sweep_rounded),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _search,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Cari di riwayat…',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHistory(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Dismissible(
                            key: ValueKey<String>(item.id),
                            direction: DismissDirection.endToStart,
                            background: _DeleteBackground(),
                            onDismissed: (_) async {
                              await widget.controller.deleteHistory(item.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Riwayat dihapus'),
                                ),
                              );
                            },
                            child: _HistoryTile(
                              item: item,
                              onTap: () => _openDetail(context, item),
                              onToggleFavorite: () =>
                                  widget.controller.toggleFavorite(item.id),
                            ),
                          );
                        },
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

  void _openDetail(BuildContext context, HistoryItem item) {
    Navigator.of(context).push<void>(
      MorphPageRoute<void>(
        builder: (_) =>
            HistoryDetailScreen(item: item, controller: widget.controller),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua riwayat?'),
        content: const Text(
          'Semua hasil yang tersimpan di perangkat ini akan dihapus. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await widget.controller.clearHistory();
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = GenerationMode.fromId(item.modeId);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Hero(
            tag: 'hist-mode-${item.id}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(mode.icon, size: 20, color: mode.color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mode.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        item.modeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: mode.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_wordCount(item.output)} kata • ${item.model}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onToggleFavorite,
            icon: Icon(
              item.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: item.favorite ? AppColors.amber : null,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  static int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (sameDay) return 'Hari ini $time';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppTheme.brand,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Riwayat masih kosong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setiap hasil yang kamu buat otomatis tersimpan di sini, '
              'jadi tidak perlu takut hilang.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layar detail sebuah item riwayat.
class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    super.key,
    required this.item,
    required this.controller,
  });

  final HistoryItem item;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = GenerationMode.fromId(item.modeId);
    return Scaffold(
      appBar: AppBar(
        title: Text(item.modeLabel),
        actions: <Widget>[
          IconButton(
            tooltip: item.favorite ? 'Hapus favorit' : 'Jadikan favorit',
            onPressed: () => controller.toggleFavorite(item.id),
            icon: Icon(
              item.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: item.favorite ? AppColors.amber : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: mode.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(mode.icon, size: 24, color: mode.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.modeLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        item.model,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel('Brief kamu'),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                item.brief,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.5),
              ),
            ),
            if (item.extra.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              const SectionLabel('Tambahan'),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  item.extra,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionLabel('Hasil'),
            _DetailResult(item: item, mode: mode),
          ],
        ),
      ),
    );
  }
}

class _DetailResult extends StatelessWidget {
  const _DetailResult({required this.item, required this.mode});

  final HistoryItem item;
  final GenerationMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: mode.color.withValues(alpha: 0.35)),
        color: mode.color.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MarkdownLite(item.output, textStyle: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: item.output));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teks berhasil disalin')),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded, size: 17),
                label: const Text('Salin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    shareText(item.output, subject: item.modeLabel),
                icon: const Icon(Icons.share_rounded, size: 17),
                label: const Text('Bagikan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
