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
                visual: const _AnalyticsMiniVisual(),
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
                visual: const _DoseTimelineMiniVisual(),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Expanded(child: _MiniSupplyVial(fill: 0.82)),
          SizedBox(width: 7),
          Expanded(child: _MiniSupplyVial(fill: 0.54)),
          SizedBox(width: 7),
          Expanded(child: _MiniSupplyVial(fill: 0.31)),
          SizedBox(width: 7),
          Expanded(child: _MiniSupplyBox()),
        ],
      ),
    );
  }
}

class _MiniSupplyVial extends StatelessWidget {
  const _MiniSupplyVial({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.36),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fill,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ArcticPalette.accentGradient(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniSupplyBox extends StatelessWidget {
  const _MiniSupplyBox();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 27,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Center(
        child: Icon(
          ArcticIcons.inventory_outlined,
          size: 16,
          color: colors.primary,
        ),
      ),
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
        Expanded(
          child: _MiniPhotoFrame(
            icon: ArcticIcons.person_outline,
            accent: colors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _MiniPhotoFrame(
                icon: ArcticIcons.person_outline,
                accent: ArcticPalette.ice,
              ),
              Positioned(
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    size: 13,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniPhotoFrame(
            icon: ArcticIcons.photo_camera_outlined,
            accent: ArcticPalette.lavender,
          ),
        ),
      ],
    );
  }
}

class _MiniPhotoFrame extends StatelessWidget {
  const _MiniPhotoFrame({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(icon, size: 22, color: accent.withValues(alpha: 0.72)),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 5,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightMiniVisual extends StatelessWidget {
  const _WeightMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              ArcticIcons.monitor_weight_outlined,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: CustomPaint(
              painter: _MiniLinePainter(
                color: colors.primary,
                points: const [0.80, 0.72, 0.74, 0.61, 0.53, 0.46, 0.34, 0.25],
                showPoints: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMiniVisual extends StatelessWidget {
  const _AnalyticsMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const bars = [0.34, 0.58, 0.46, 0.76, 0.60, 0.88];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < bars.length; index++) ...[
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: bars[index],
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? colors.primary.withValues(alpha: 0.22)
                            : ArcticPalette.ice.withValues(alpha: 0.28),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                if (index < bars.length - 1) const SizedBox(width: 5),
              ],
            ],
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniLinePainter(
                color: colors.primary,
                points: const [0.74, 0.60, 0.65, 0.42, 0.49, 0.22],
                showPoints: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseTimelineMiniVisual extends StatelessWidget {
  const _DoseTimelineMiniVisual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            right: 14,
            child: Container(
              height: 2,
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DoseTimelineNode(icon: Icons.check_rounded, active: true),
              _DoseTimelineNode(icon: Icons.check_rounded, active: true),
              _DoseTimelineNode(icon: Icons.remove_rounded, active: false),
              _DoseTimelineNode(icon: Icons.check_rounded, active: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseTimelineNode extends StatelessWidget {
  const _DoseTimelineNode({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 27,
      height: 27,
      decoration: BoxDecoration(
        color: active ? colors.primary.withValues(alpha: 0.12) : colors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? colors.primary.withValues(alpha: 0.42)
              : colors.outlineVariant.withValues(alpha: 0.70),
          width: 1.2,
        ),
      ),
      child: Icon(
        icon,
        size: 15,
        color: active ? colors.primary : colors.onSurfaceVariant,
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
              _ComingSoonChip(
                icon: ArcticIcons.insights_outlined,
                label: 'Reports',
              ),
              _ComingSoonChip(
                icon: ArcticIcons.favorite_border,
                label: 'Health',
              ),
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
