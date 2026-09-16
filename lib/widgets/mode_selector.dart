import 'package:flutter/material.dart';

import '../models/generation_mode.dart';
import '../theme/motion.dart';

/// Pilihan mode generate (judul, artikel, dst) dalam bentuk kartu geser.
class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GenerationMode selected;
  final ValueChanged<GenerationMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: GenerationMode.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mode = GenerationMode.values[index];
          final active = mode.id == selected.id;
          return AnimatedScale(
            scale: active ? 1 : 0.96,
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
            child: _ModeCard(
              mode: mode,
              active: active,
              onTap: () => onSelected(mode),
            ),
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.active,
    required this.onTap,
  });

  final GenerationMode mode;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 122,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(active ? 24 : 20),
        gradient: active
            ? LinearGradient(
                colors: <Color>[
                  mode.color.withValues(alpha: 0.9),
                  mode.color.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : (dark ? const Color(0xFF141424) : Colors.white),
        border: Border.all(
          color: active
              ? mode.color
              : (dark ? const Color(0xFF23233A) : const Color(0xFFE9E9F2)),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: mode.color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  scale: active ? 1.18 : 1,
                  duration: AppMotion.normal,
                  curve: AppMotion.overshoot,
                  child: Icon(
                    mode.icon,
                    color: active ? Colors.white : mode.color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mode.hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.25,
                    color: active
                        ? Colors.white.withValues(alpha: 0.85)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
