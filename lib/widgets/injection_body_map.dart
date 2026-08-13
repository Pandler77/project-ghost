import 'package:flutter/material.dart';

import '../models/injection_site.dart';
import '../theme/app_theme.dart';

class InjectionBodyMap extends StatelessWidget {
  const InjectionBodyMap({
    required this.enabledSites,
    required this.selectedSite,
    required this.onSiteSelected,
    this.previousSite,
    this.showDisabledSites = true,
    super.key,
  });

  final Set<InjectionSite> enabledSites;
  final InjectionSite? selectedSite;
  final InjectionSite? previousSite;
  final ValueChanged<InjectionSite> onSiteSelected;
  final bool showDisabledSites;

  static const List<InjectionSite> _frontSites = [
    InjectionSite.armLeft,
    InjectionSite.armRight,
    InjectionSite.abdomenTopLeft,
    InjectionSite.abdomenTopRight,
    InjectionSite.abdomenBottomLeft,
    InjectionSite.abdomenBottomRight,
    InjectionSite.loveHandleLeft,
    InjectionSite.loveHandleRight,
    InjectionSite.thighLeft,
    InjectionSite.thighRight,
  ];

  static const List<InjectionSite> _backSites = [
    InjectionSite.gluteLeft,
    InjectionSite.gluteRight,
  ];

  @override
  Widget build(BuildContext context) {
    final visibleFrontSites = _frontSites.where(_shouldShowSite).toList();
    final visibleBackSites = _backSites.where(_shouldShowSite).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyViewSection(
          title: 'Front',
          sites: visibleFrontSites,
          enabledSites: enabledSites,
          selectedSite: selectedSite,
          previousSite: previousSite,
          onSiteSelected: onSiteSelected,
        ),
        if (visibleBackSites.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _BodyViewSection(
            title: 'Back',
            sites: visibleBackSites,
            enabledSites: enabledSites,
            selectedSite: selectedSite,
            previousSite: previousSite,
            onSiteSelected: onSiteSelected,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const _MapLegend(),
      ],
    );
  }

  bool _shouldShowSite(InjectionSite site) {
    if (showDisabledSites) {
      return true;
    }

    return enabledSites.contains(site);
  }
}

class _BodyViewSection extends StatelessWidget {
  const _BodyViewSection({
    required this.title,
    required this.sites,
    required this.enabledSites,
    required this.selectedSite,
    required this.previousSite,
    required this.onSiteSelected,
  });

  final String title;
  final List<InjectionSite> sites;
  final Set<InjectionSite> enabledSites;
  final InjectionSite? selectedSite;
  final InjectionSite? previousSite;
  final ValueChanged<InjectionSite> onSiteSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumn = constraints.maxWidth < 340;

              if (useSingleColumn) {
                return Column(
                  children: [
                    for (var index = 0; index < sites.length; index++) ...[
                      _InjectionRegionTile(
                        site: sites[index],
                        enabled: enabledSites.contains(sites[index]),
                        selected: selectedSite == sites[index],
                        previous: previousSite == sites[index],
                        onPressed: () {
                          onSiteSelected(sites[index]);
                        },
                      ),
                      if (index < sites.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final site in sites)
                    SizedBox(
                      width: (constraints.maxWidth - AppSpacing.sm) / 2,
                      child: _InjectionRegionTile(
                        site: site,
                        enabled: enabledSites.contains(site),
                        selected: selectedSite == site,
                        previous: previousSite == site,
                        onPressed: () {
                          onSiteSelected(site);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InjectionRegionTile extends StatelessWidget {
  const _InjectionRegionTile({
    required this.site,
    required this.enabled,
    required this.selected,
    required this.previous,
    required this.onPressed,
  });

  final InjectionSite site;
  final bool enabled;
  final bool selected;
  final bool previous;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = switch ((enabled, selected, previous)) {
      (_, true, _) => colorScheme.errorContainer,
      (_, false, true) => colorScheme.tertiaryContainer,
      (true, false, false) => colorScheme.surfaceContainerHighest,
      (false, false, false) => colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.45,
      ),
    };

    final borderColor = switch ((enabled, selected, previous)) {
      (_, true, _) => colorScheme.error,
      (_, false, true) => colorScheme.tertiary,
      (true, false, false) => colorScheme.outlineVariant,
      (false, false, false) => colorScheme.outlineVariant.withValues(
        alpha: 0.50,
      ),
    };

    final foregroundColor = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: borderColor,
              width: selected || previous ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RegionIndicator(
                enabled: enabled,
                selected: selected,
                previous: previous,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  site.label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: selected || previous
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionIndicator extends StatelessWidget {
  const _RegionIndicator({
    required this.enabled,
    required this.selected,
    required this.previous,
  });

  final bool enabled;
  final bool selected;
  final bool previous;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final color = switch ((enabled, selected, previous)) {
      (_, true, _) => colorScheme.error,
      (_, false, true) => colorScheme.tertiary,
      (true, false, false) => colorScheme.primary,
      (false, false, false) => colorScheme.outline,
    };

    final icon = switch ((enabled, selected, previous)) {
      (_, true, _) => Icons.location_on,
      (_, false, true) => Icons.history,
      (true, false, false) => Icons.circle_outlined,
      (false, false, false) => Icons.block,
    };

    return Icon(icon, size: 18, color: color);
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(
          icon: Icons.location_on,
          label: 'Selected',
          color: colorScheme.error,
        ),
        _LegendItem(
          icon: Icons.history,
          label: 'Previous',
          color: colorScheme.tertiary,
        ),
        _LegendItem(
          icon: Icons.circle_outlined,
          label: 'Available',
          color: colorScheme.primary,
        ),
        _LegendItem(
          icon: Icons.block,
          label: 'Disabled',
          color: colorScheme.outline,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
