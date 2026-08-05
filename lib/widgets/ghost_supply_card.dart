import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../theme/app_theme.dart';

class GhostSupplyCard extends StatelessWidget {
  const GhostSupplyCard({
    required this.items,
    required this.protocols,
    required this.onTap,
    super.key,
  });

  final List<InventoryItem> items;
  final List<Protocol> protocols;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleItems = items.take(3).toList();

    final lowSupplyCount = items.where((item) => item.isLowStock).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ghost Supply™',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'BETA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                items.isEmpty
                    ? 'No supplies configured.'
                    : lowSupplyCount == 0
                    ? '${items.length} ${items.length == 1 ? 'supply' : 'supplies'} tracked'
                    : '$lowSupplyCount ${lowSupplyCount == 1 ? 'supply needs' : 'supplies need'} attention',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                _EmptySupplyState(colorScheme: colorScheme)
              else
                for (var index = 0; index < visibleItems.length; index++) ...[
                  _SupplyRow(
                    item: visibleItems[index],
                    protocolName: _protocolName(visibleItems[index].protocolId),
                  ),
                  if (index < visibleItems.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: colorScheme.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _protocolName(String protocolId) {
    for (final protocol in protocols) {
      if (protocol.id == protocolId) {
        return protocol.name;
      }
    }

    return 'Unknown Protocol';
  }
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({required this.item, required this.protocolName});

  final InventoryItem item;
  final String protocolName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                protocolName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (item.isLowStock)
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: colorScheme.error,
              ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: item.currentVialProgress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 6),
        Text(
          item.currentAmount <= 0
              ? 'No ${item.containerType.toLowerCase()} open • '
                    '${item.unopenedQuantity} unopened'
              : '${_formatNumber(item.currentAmount)} / '
                    '${_formatNumber(item.vialSize)} ${item.unit} • '
                    '${item.unopenedQuantity} unopened',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _EmptySupplyState extends StatelessWidget {
  const _EmptySupplyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        'Tap to set up inventory tracking.',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
