import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/milestone_achievement.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  const MilestoneCelebrationDialog({
    required this.achievement,
    super.key,
  });

  final MilestoneAchievement achievement;

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState
    extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    return switch (widget.achievement.kind) {
      MilestoneKind.weightLoss => ArcticIcons.monitor_weight_outlined,
      MilestoneKind.goalWeight => ArcticIcons.flag_rounded,
      MilestoneKind.doseCount => Icons.check_circle_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              34,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.30),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.16),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(
                      0,
                      0.35,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      _icon,
                      size: 38,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'MILESTONE',
                  style: TextStyle(
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.achievement.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.achievement.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    height: 1.45,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Keep Going',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      primary: colors.primary,
                      secondary: colors.tertiary,
                      accent: colors.secondary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(77);
    final colors = [primary, secondary, accent];

    for (var index = 0; index < 42; index++) {
      final x = random.nextDouble() * size.width;
      final startY = -30.0 - random.nextDouble() * 180;
      final fallDistance = size.height + 260;
      final y = startY + (fallDistance * progress);

      final drift =
          math.sin((progress * math.pi * 3) + index) *
          (8 + random.nextDouble() * 16);

      final rotation = progress * math.pi * (2 + random.nextDouble() * 4);

      final paint = Paint()
        ..color = colors[index % colors.length].withValues(
          alpha: (1 - progress * 0.55).clamp(0.0, 1.0),
        );

      canvas.save();
      canvas.translate(x + drift, y);
      canvas.rotate(rotation);

      final width = 5.0 + random.nextDouble() * 5;
      final height = 8.0 + random.nextDouble() * 8;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.accent != accent;
  }
}
