import 'package:flutter/material.dart';

import '../../models/injection_site.dart';
import '../../models/rotation_mode.dart';
import '../../theme/app_theme.dart';

class InjectionRotationEditor extends StatelessWidget {
  const InjectionRotationEditor({
    required this.rotationMode,
    required this.enabledSites,
    required this.onRotationModeChanged,
    required this.onSiteChanged,
    super.key,
  });

  final RotationMode rotationMode;
  final Set<InjectionSite> enabledSites;
  final ValueChanged<RotationMode> onRotationModeChanged;
  final void Function(InjectionSite site, bool enabled) onSiteChanged;

  static const List<InjectionSite> _abdomenSites = [
    InjectionSite.abdomenTopLeft,
    InjectionSite.abdomenTopRight,
    InjectionSite.abdomenBottomLeft,
    InjectionSite.abdomenBottomRight,
    InjectionSite.loveHandleLeft,
    InjectionSite.loveHandleRight,
  ];

  static const List<InjectionSite> _otherFrontSites = [
    InjectionSite.armLeft,
    InjectionSite.armRight,
    InjectionSite.thighLeft,
    InjectionSite.thighRight,
  ];

  static const List<InjectionSite> _backSites = [
    InjectionSite.gluteLeft,
    InjectionSite.gluteRight,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Injection Site Rotation',
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose how Ghost should rotate between enabled injection areas.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Rotation mode',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        _RotationModeTile(
          title: 'Sequential',
          subtitle: 'Move through enabled sites in order.',
          icon: Icons.format_list_numbered,
          isSelected: rotationMode == RotationMode.sequential,
          onTap: () {
            onRotationModeChanged(RotationMode.sequential);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _RotationModeTile(
          title: 'Random',
          subtitle: 'Choose from enabled sites while avoiding repeats.',
          icon: Icons.shuffle,
          isSelected: rotationMode == RotationMode.random,
          onTap: () {
            onRotationModeChanged(RotationMode.random);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _SiteSection(
          title: 'Abdomen and love handles',
          sites: _abdomenSites,
          enabledSites: enabledSites,
          onSiteChanged: onSiteChanged,
        ),

        const SizedBox(height: AppSpacing.md),

        _SiteSection(
          title: 'Arms and thighs',
          sites: _otherFrontSites,
          enabledSites: enabledSites,
          onSiteChanged: onSiteChanged,
        ),

        const SizedBox(height: AppSpacing.md),

        _SiteSection(
          title: 'Glutes',
          sites: _backSites,
          enabledSites: enabledSites,
          onSiteChanged: onSiteChanged,
        ),

        const SizedBox(height: AppSpacing.md),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rotation preview',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _previewText(),
                      style: TextStyle(
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _previewText() {
    final orderedSites = [
      ..._abdomenSites,
      ..._otherFrontSites,
      ..._backSites,
    ].where(enabledSites.contains).toList();

    if (orderedSites.length < 2) {
      return 'Select at least two injection sites.';
    }

    final modeText = rotationMode == RotationMode.sequential
        ? 'Sequential rotation'
        : 'Random rotation';

    return '$modeText across ${orderedSites.length} sites.\n'
        'First available site: ${orderedSites.first.label}.';
  }
}

class _SiteSection extends StatelessWidget {
  const _SiteSection({
    required this.title,
    required this.sites,
    required this.enabledSites,
    required this.onSiteChanged,
  });

  final String title;
  final List<InjectionSite> sites;
  final Set<InjectionSite> enabledSites;
  final void Function(InjectionSite site, bool enabled) onSiteChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var index = 0; index < sites.length; index++) ...[
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              title: Text(sites[index].label),
              value: enabledSites.contains(sites[index]),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                onSiteChanged(sites[index], value ?? false);
              },
            ),
            if (index < sites.length - 1)
              Divider(height: 1, color: colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _RotationModeTile extends StatelessWidget {
  const _RotationModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
