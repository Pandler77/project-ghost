import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/protocol.dart';
import '../services/app_data_service.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'calculator_hub_screen.dart';
import 'dose_history_screen.dart';
import 'inventory_screen.dart';
import 'progress_photo_screen.dart';
import 'weight_history_screen.dart';
import '../theme/arctic_icons.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({
    required this.dataService,
    required this.protocols,
    required this.measurementSystem,
    required this.onDataChanged,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;
  final MeasurementSystem measurementSystem;
  final VoidCallback onDataChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          110,
        ),
        children: [
          _ToolsHeader(colors: colors),

          const SizedBox(height: AppSpacing.lg),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.90,
            children: [
              // Premium tools stay together on the first row.
              _ToolCard(
                icon: ArcticIcons.inventory_2_outlined,
                title: 'Arctic Supply™',
                subtitle: 'Inventory tracking',
                premium: true,
                visual: const _InventoryMiniVisual(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryScreen(
                        dataService: dataService,
                        protocols: protocols,
                      ),
                    ),
                  );
                },
              ),

              _ToolCard(
                icon: ArcticIcons.analytics_outlined,
                title: 'Analytics',
                subtitle: 'Trends and insights',
                premium: true,
                visual: const _TrendMiniVisual(
                  points: [0.74, 0.60, 0.67, 0.40, 0.52, 0.27, 0.38, 0.18],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsScreen(
                        dataService: dataService,
                        protocols: protocols,
                        measurementSystem: measurementSystem,
                      ),
                    ),
                  );
                },
              ),

              _ToolCard(
                icon: ArcticIcons.history_outlined,
                title: 'Dose History',
                subtitle: 'Doses and activity over time',
                visual: const _TrendMiniVisual(
                  points: [0.72, 0.52, 0.66, 0.42, 0.35, 0.58, 0.39, 0.46],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoseHistoryScreen(
                        dataService: dataService,
                        protocols: protocols,
                      ),
                    ),
                  );
                },
              ),

              _ToolCard(
                icon: ArcticIcons.calculate_outlined,
                title: 'Arctic Calculator',
                subtitle: 'Dose, dilution, and target tools',
                visual: const _CalculatorMiniVisual(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalculatorHubScreen(
                        dataService: dataService,
                        measurementSystem: measurementSystem,
                      ),
                    ),
                  );
                },
              ),

              _ToolCard(
                icon: ArcticIcons.monitor_weight_outlined,
                title: 'Weight History',
                subtitle: 'Trends, goals, and progress',
                visual: const _WeightMiniVisual(),
                onTap: () async {
                  final didChange = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeightHistoryScreen(
                        dataService: dataService,
                        measurementSystem: measurementSystem,
                      ),
                    ),
                  );

                  if (didChange == true) {
                    onDataChanged();
                  }
                },
              ),

              _ToolCard(
                icon: ArcticIcons.photo_library_outlined,
                title: 'Progress Photos',
                subtitle: 'Visual progress sessions',
                visual: const _PhotosMiniVisual(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgressPhotosScreen(
                        dataService: dataService,
                        measurementSystem: measurementSystem,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          const _ComingSoonCard(),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.onTap,
    this.premium = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget visual;
  final bool premium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: premium
                  ? colors.primary.withValues(alpha: 0.38)
                  : colors.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 5),
                color: colors.shadow.withValues(alpha: 0.035),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ToolIcon(icon: icon),
                  const Spacer(),
                  if (premium) const _PremiumBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.primary,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ChevronButton(onTap: onTap),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(height: 46, width: double.infinity, child: visual),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: ArcticPalette.accentGradient(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: AppIcon.md, color: Colors.white),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'PREMIUM',
        style: TextStyle(
          fontSize: AppTypography.micro,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.25,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.70),
        ),
      ),
      child: Icon(Icons.chevron_right, size: 19, color: colors.onSurface),
    );
  }
}

class _InventoryMiniVisual extends StatelessWidget {
  const _InventoryMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const heights = [
      16.0,
      27.0,
      21.0,
      35.0,
      18.0,
      23.0,
      39.0,
      20.0,
      29.0,
      17.0,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < heights.length; index++) ...[
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: heights[index],
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: index.isEven ? 0.30 : 0.56,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          if (index < heights.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _CalculatorMiniVisual extends StatelessWidget {
  const _CalculatorMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CalculatorSymbol(symbol: '+', color: colors.primary),
          _VerticalMiniDivider(color: colors.outlineVariant),
          _CalculatorSymbol(symbol: '−', color: colors.primary),
          _VerticalMiniDivider(color: colors.outlineVariant),
          _CalculatorSymbol(symbol: '×', color: colors.primary),
          _VerticalMiniDivider(color: colors.outlineVariant),
          _CalculatorSymbol(symbol: '÷', color: colors.primary),
        ],
      ),
    );
  }
}

class _CalculatorSymbol extends StatelessWidget {
  const _CalculatorSymbol({required this.symbol, required this.color});

  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _VerticalMiniDivider extends StatelessWidget {
  const _VerticalMiniDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: color.withValues(alpha: 0.65),
    );
  }
}

class _PhotosMiniVisual extends StatelessWidget {
  const _PhotosMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                ArcticIcons.person_outline,
                size: 25,
                color: colors.primary.withValues(alpha: 0.60),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: colors.primary.withValues(alpha: 0.20)),
            ),
            child: Icon(Icons.add, size: 20, color: colors.primary),
          ),
        ),
      ],
    );
  }
}

class _WeightMiniVisual extends StatelessWidget {
  const _WeightMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _MiniLinePainter(
        color: colors.primary,
        points: const [0.78, 0.70, 0.77, 0.58, 0.66, 0.39, 0.50, 0.24],
        showPoints: true,
      ),
    );
  }
}

class _TrendMiniVisual extends StatelessWidget {
  const _TrendMiniVisual({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _MiniLinePainter(
        color: colors.primary,
        points: points,
        showPoints: false,
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  _MiniLinePainter({
    required this.color,
    required this.points,
    required this.showPoints,
  });

  final Color color;
  final List<double> points;
  final bool showPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    const padding = 3.0;

    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = padding + usableWidth * (index / (points.length - 1));
      final y = padding + usableHeight * points[index].clamp(0.0, 1.0);
      offsets.add(Offset(x, y));
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);

    for (var index = 1; index < offsets.length; index++) {
      final previous = offsets[index - 1];
      final current = offsets[index];
      final midpointX = (previous.dx + current.dx) / 2;

      path.cubicTo(
        midpointX,
        previous.dy,
        midpointX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    if (showPoints) {
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var index = 1; index < offsets.length; index += 2) {
        canvas.drawCircle(offsets[index], 2.8, pointPaint);
      }
    }

    final finalPointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offsets.last, 3.5, finalPointPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.showPoints != showPoints ||
        oldDelegate.points.length != points.length) {
      return true;
    }

    for (var index = 0; index < points.length; index++) {
      if (oldDelegate.points[index] != points[index]) {
        return true;
      }
    }

    return false;
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 5),
            color: colors.shadow.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ToolIcon(icon: ArcticIcons.auto_awesome_outlined),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: AppTypography.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'More tools are already planned.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ComingSoonChip(
                icon: ArcticIcons.file_download_outlined,
                label: 'Data Export',
              ),
              _ComingSoonChip(icon: ArcticIcons.insights_outlined, label: 'Reports'),
              _ComingSoonChip(icon: ArcticIcons.favorite_border, label: 'Health'),
              _ComingSoonChip(
                icon: ArcticIcons.auto_graph_outlined,
                label: 'Insights',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcon.xs, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsHeader extends StatelessWidget {
  const _ToolsHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final gradientColors = ArcticPalette.headerGradient(context).colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: brightness == Brightness.dark
              ? ArcticPalette.lavender.withValues(alpha: 0.22)
              : ArcticPalette.purple.withValues(alpha: 0.14),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.24)
                : ArcticPalette.purple.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tools',
            style: TextStyle(
              fontSize: AppTypography.pageTitle,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Everything you need to track and manage your progress.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
