import 'package:flutter/material.dart';

import '../../models/protocol_status.dart';
import '../../theme/app_theme.dart';

class ProtocolFilterChips extends StatelessWidget {
  const ProtocolFilterChips({
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onSortPressed,
    super.key,
  });

  final ProtocolStatus? selectedStatus;
  final ValueChanged<ProtocolStatus?> onStatusChanged;
  final VoidCallback onSortPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusChip(
            label: 'All',
            selected: selectedStatus == null,
            onPressed: () => onStatusChanged(null),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusChip(
            label: 'Active',
            selected: selectedStatus == ProtocolStatus.active,
            onPressed: () {
              onStatusChanged(ProtocolStatus.active);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusChip(
            label: 'Paused',
            selected: selectedStatus == ProtocolStatus.paused,
            onPressed: () {
              onStatusChanged(ProtocolStatus.paused);
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusChip(
            label: 'Archived',
            selected: selectedStatus == ProtocolStatus.archived,
            onPressed: () {
              onStatusChanged(ProtocolStatus.archived);
            },
          ),
        ),
        const SizedBox(width: 6),
        _SortChip(onPressed: onSortPressed),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w700,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const Icon(Icons.sort, size: 20),
      ),
    );
  }
}
