import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol aksi utama — v3.1 "quiet": gradien kaca tenang, tanpa morph.
///
/// Keadaan sibuk hanya mengganti warna + label (tanpa animasi bentuk).
class MorphingActionButton extends StatelessWidget {
  const MorphingActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.busy = false,
    this.streaming = false,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final bool streaming;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final stopping = busy || streaming;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: stopping
              ? const LinearGradient(
                  colors: <Color>[Color(0xFFEF4444), Color(0xFFB91C1C)],
                )
              : AppTheme.brand,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (stopping ? const Color(0xFFEF4444) : AppColors.violet)
                  .withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (busy && !streaming)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    stopping ? Icons.stop_rounded : icon,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  stopping ? 'Hentikan' : label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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

/// Garis tipis penanda streaming — statis dan tenang.
class MorphingProgressLine extends StatelessWidget {
  const MorphingProgressLine({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.75),
            color.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}
