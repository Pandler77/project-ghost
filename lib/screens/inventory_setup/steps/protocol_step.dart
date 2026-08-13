import 'package:flutter/material.dart';

import '../../../models/inventory_preset.dart';
import '../../../models/protocol.dart';
import '../../../services/inventory_preset_service.dart';
import '../../../theme/app_theme.dart';
import '../widgets/search_protocol_field.dart';
import '../widgets/step_header.dart';

class ProtocolStep extends StatefulWidget {
  const ProtocolStep({
    required this.protocols,
    required this.selectedProtocolId,
    required this.onProtocolSelected,
    super.key,
  });

  final List<Protocol> protocols;
  final String? selectedProtocolId;
  final ValueChanged<Protocol> onProtocolSelected;

  @override
  State<ProtocolStep> createState() => _ProtocolStepState();
}

class _ProtocolStepState extends State<ProtocolStep> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Protocol> get _filteredProtocols {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.protocols;
    }

    return widget.protocols.where((protocol) {
      final preset = InventoryPresetService.instance.findByProtocol(protocol);
      final matchesName = protocol.name.toLowerCase().contains(query);
      final matchesAlias =
          preset?.aliases.any((alias) => alias.toLowerCase().contains(query)) ??
          false;
      return matchesName || matchesAlias;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProtocols = _filteredProtocols;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'What are you tracking?',
          subtitle:
              'Choose an existing protocol. Ghost will use smart defaults when available.',
          currentStep: 1,
          totalSteps: 7,
        ),
        const SizedBox(height: AppSpacing.lg),
        SearchProtocolField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onClear: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (filteredProtocols.isEmpty)
          const _NoMatchingProtocols()
        else
          for (final protocol in filteredProtocols) ...[
            _ProtocolChoiceCard(
              protocol: protocol,
              preset: InventoryPresetService.instance.findByProtocol(protocol),
              isSelected: widget.selectedProtocolId == protocol.id,
              onTap: () {
                widget.onProtocolSelected(protocol);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _ProtocolChoiceCard extends StatelessWidget {
  const _ProtocolChoiceCard({
    required this.protocol,
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final Protocol protocol;
  final InventoryPreset? preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(protocol.colorValue);
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    final subtitle = preset == null
        ? 'Custom setup'
        : '${preset!.containerType} • '
            '${_formatNumber(preset!.defaultSize)} '
            '${preset!.defaultUnit}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.10)
                : baseColor,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.75)
                  : colors.outlineVariant.withValues(alpha: 0.60),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _iconForPreset(preset),
                  color: accent,
                  size: AppIcon.md,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.name,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSelected ? accent : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForPreset(InventoryPreset? preset) {
    return switch (preset?.iconName) {
      'science' => Icons.science_outlined,
      'medication' => Icons.medication_outlined,
      'fitness' => Icons.fitness_center_outlined,
      _ => Icons.inventory_2_outlined,
    };
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class _NoMatchingProtocols extends StatelessWidget {
  const _NoMatchingProtocols();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 42,
            color: colors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No matching protocols',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ghost Supply can only be attached to protocols already created in Ghost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
