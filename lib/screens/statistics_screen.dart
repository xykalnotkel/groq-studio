import 'package:flutter/material.dart';

import '../core/controller.dart';
import '../core/stats.dart';
import '../models/generation_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/morphing_background.dart';

/// Halaman statistik pemakaian: total generate, kata, karakter,
/// mode favorit, streak harian, grafik 7 hari, dan tombol reset.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset statistik?'),
        content: const Text(
          'Semua angka pemakaian (total generate, kata, grafik, streak) '
          'akan dikembalikan ke nol. Riwayat hasil tidak ikut terhapus.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await controller.resetStats();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Statistik sudah direset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphingScaffoldBody(
        seed: 41,
        opacity: 0.4,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final stats = controller.stats;
              final favoriteId = stats.favoriteModeId;
              final favoriteLabel = favoriteId == null
                  ? 'Belum ada'
                  : GenerationMode.fromId(favoriteId).label;

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Statistik',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: stats.totalGenerates == 0
                            ? null
                            : () => _confirmReset(context),
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Kartu angka utama.
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatCard(
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.violet,
                          value: '${stats.totalGenerates}',
                          label: 'Total generate',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.amber,
                          value: '${stats.dailyStreak}',
                          label: 'Streak harian',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _StatCard(
                          icon: Icons.text_snippet_rounded,
                          color: AppColors.cyan,
                          value: _formatNumber(stats.totalWords),
                          label: 'Total kata',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.straighten_rounded,
                          color: AppColors.pink,
                          value: _formatNumber(stats.totalChars),
                          label: 'Total karakter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppTheme.brand,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Mode favorit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                favoriteLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (favoriteId != null)
                          Text(
                            '${stats.modeCounts[favoriteId]}x pakai',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    '7 hari terakhir',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: SizedBox(
                      height: 150,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _WeekChartPainter(
                          points: stats.lastDays(7),
                          primary: theme.colorScheme.primary,
                          onSurface: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Statistik dihitung dari hasil generate yang berhasil '
                    'dan disimpan hanya di perangkat kamu.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} rb';
    }
    return '$value';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grafik batang sederhana untuk 7 hari terakhir.
class _WeekChartPainter extends CustomPainter {
  _WeekChartPainter({
    required this.points,
    required this.primary,
    required this.onSurface,
  });

  final List<UsageDayPoint> points;
  final Color primary;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    final maxCount = points.fold<int>(
      1,
      (current, point) => point.count > current ? point.count : current,
    );
    final chartHeight = size.height - 28;
    final slot = size.width / points.length;
    final barWidth = slot * 0.5;

    final labelStyle = TextStyle(
      color: onSurface.withValues(alpha: 0.55),
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = TextStyle(
      color: primary,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final centerX = slot * i + slot / 2;
      final height = point.count == 0
          ? 4.0
          : (point.count / maxCount) * (chartHeight - 18);
      final top = chartHeight - height;
      final isToday = i == points.length - 1;

      final paint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                if (point.count == 0)
                  onSurface.withValues(alpha: 0.12)
                else if (isToday)
                  primary
                else
                  primary.withValues(alpha: 0.55),
                if (point.count == 0)
                  onSurface.withValues(alpha: 0.12)
                else
                  primary.withValues(alpha: 0.18),
              ],
            ).createShader(
              Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height),
            );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height),
          const Radius.circular(6),
        ),
        paint,
      );

      if (point.count > 0) {
        _drawText(
          canvas,
          '${point.count}',
          Offset(centerX, top - 8),
          valueStyle,
        );
      }
      _drawText(
        canvas,
        point.shortLabel,
        Offset(centerX, chartHeight + 8),
        labelStyle,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_WeekChartPainter old) => old.points != points;
}
