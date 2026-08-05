import 'package:flutter/material.dart';

import '../../../models/inventory_preset.dart';
import '../../../models/protocol.dart';
import '../../../services/inventory_preset_service.dart';
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
          totalSteps: 6,
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 20),
        if (filteredProtocols.isEmpty)
          const _NoMatchingProtocols()
        else ...[
          for (final protocol in filteredProtocols) ...[
            _ProtocolChoiceCard(
              protocol: protocol,
              preset: InventoryPresetService.instance.findByProtocol(protocol),
              isSelected: widget.selectedProtocolId == protocol.id,
              onTap: () {
                widget.onProtocolSelected(protocol);
              },
            ),
            const SizedBox(height: 12),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

    final subtitle = preset == null
        ? 'Custom setup'
        : '${preset!.containerType} • '
              '${_formatNumber(preset!.defaultSize)} '
              '${preset!.defaultUnit}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForPreset(preset), color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary)
              else
                const Icon(Icons.chevron_right),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No matching protocols',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Ghost Supply can only be attached to protocols already created in Ghost.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
