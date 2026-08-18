import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.profileName,
    required this.remainingDoses,
    required this.totalDoses,
    this.onAddProtocol,
    required this.showGreeting,
    required this.showProgressBar,
    super.key,
  });

  final String profileName;
  final int remainingDoses;
  final int totalDoses;
  final VoidCallback? onAddProtocol;
  final bool showGreeting;
  final bool showProgressBar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      < 12 => 'Good morning,',
      < 18 => 'Good afternoon,',
      _ => 'Good evening,',
    };

    final completedCount = (totalDoses - remainingDoses).clamp(0, totalDoses);

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.34),
            colors.primaryContainer.withValues(alpha: 0.16),
          ]
        : [
            colors.primary.withValues(alpha: 0.17),
            colors.primaryContainer.withValues(alpha: 0.58),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGreeting) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: AppTypography.pageTitle,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profileName.trim().isEmpty
                            ? 'ArcticDose'
                            : profileName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ] else
                const Spacer(),
              if (onAddProtocol != null)
                _AddProtocolButton(onPressed: onAddProtocol!),
            ],
          ),
          if (showProgressBar && totalDoses > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _ProgressLabel(color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            _DoseProgressBar(
              completedCount: completedCount,
              totalCount: totalDoses,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                '$completedCount / $totalDoses Doses Completed',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ] else if (showProgressBar && totalDoses == 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'No doses scheduled today',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProtocolButton extends StatelessWidget {
  const _AddProtocolButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.06 : 0.28),
            blurRadius: isDark ? 12 : 16,
            spreadRadius: isDark ? 0 : 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? colors.primary.withValues(alpha: 0.08) : null,
              gradient: isDark
                  ? null
                  : LinearGradient(
                      colors: [
                        colors.primary,
                        colors.primary.withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: isDark
                    ? colors.primary.withValues(alpha: 0.42)
                    : Colors.white.withValues(alpha: 0.28),
                width: isDark ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 19,
                  color: isDark ? colors.primary : Colors.white,
                ),
                const SizedBox(width: 7),
                Text(
                  'Add Protocol',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w800,
                    color: isDark ? colors.primary : Colors.white,
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

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: colors.primary.withValues(alpha: 0.30),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'TODAY\'S PROGRESS',
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 1,
            color: colors.primary.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }
}

class _DoseProgressBar extends StatelessWidget {
  const _DoseProgressBar({
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < totalCount; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 12,
                decoration: BoxDecoration(
                  gradient: index < completedCount
                      ? LinearGradient(
                          colors: [
                            colors.primary,
                            colors.primary.withValues(alpha: 0.72),
                          ],
                        )
                      : null,
                  color: index < completedCount
                      ? null
                      : colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: index < completedCount
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            if (index < totalCount - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}
