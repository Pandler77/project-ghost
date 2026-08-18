import 'package:flutter/material.dart';

import '../models/inventory_batch.dart';
import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class GhostSupplyCard extends StatelessWidget {
  const GhostSupplyCard({
    required this.items,
    required this.protocols,
    required this.batchesByItemId,
    required this.onTap,
    super.key,
  });

  final List<InventoryItem> items;
  final List<Protocol> protocols;
  final Map<String, List<InventoryBatch>> batchesByItemId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final visibleItems = items.take(3).toList();

    final lowSupplyCount = items.where(_isLowStock).length;

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
                      'ArcticDose Supply™',
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
                    ? '${items.length} '
                          '${items.length == 1 ? 'supply' : 'supplies'} tracked'
                    : '$lowSupplyCount '
                          '${lowSupplyCount == 1 ? 'supply needs' : 'supplies need'} attention',
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
                    batches:
                        batchesByItemId[visibleItems[index].id] ?? const [],
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

  List<InventoryBatch> _batchesForItem(InventoryItem item) {
    return batchesByItemId[item.id] ?? const [];
  }

  int _unopenedCount(InventoryItem item) {
    return _batchesForItem(
      item,
    ).fold<int>(0, (total, batch) => total + batch.quantity);
  }

  int _physicalContainerCount(InventoryItem item) {
    return _unopenedCount(item) + (item.currentAmount > 0 ? 1 : 0);
  }

  bool _isLowStock(InventoryItem item) {
    final unopenedAmount = _batchesForItem(
      item,
    ).fold<double>(0, (total, batch) => total + batch.totalAmount);

    final totalAmount = item.currentAmount + unopenedAmount;

    if (totalAmount <= 0) {
      return true;
    }

    return _physicalContainerCount(item) <= item.lowStockThreshold;
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
  const _SupplyRow({
    required this.item,
    required this.protocolName,
    required this.batches,
  });

  final InventoryItem item;
  final String protocolName;
  final List<InventoryBatch> batches;

  int get _unopenedCount {
    return batches.fold<int>(0, (total, batch) => total + batch.quantity);
  }

  double get _unopenedAmount {
    return batches.fold<double>(0, (total, batch) => total + batch.totalAmount);
  }

  double get _totalAmount {
    return item.currentAmount + _unopenedAmount;
  }

  int get _physicalContainerCount {
    return _unopenedCount + (item.currentAmount > 0 ? 1 : 0);
  }

  bool get _isLowStock {
    if (_totalAmount <= 0) {
      return true;
    }

    return _physicalContainerCount <= item.lowStockThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerName = item.containerType.toLowerCase();
    final unopenedLabel = _unopenedCount == 1
        ? containerName
        : _pluralize(containerName);

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
            if (_isLowStock)
              Icon(
                ArcticIcons.warning_amber_rounded,
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
              ? 'No $containerName open • '
                    '$_unopenedCount unopened $unopenedLabel'
              : '${_formatNumber(item.currentAmount)} / '
                    '${_formatNumber(item.vialSize)} ${item.unit} active • '
                    '$_unopenedCount unopened',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatNumber(_totalAmount)} ${item.unit} total',
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

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _pluralize(String value) {
    if (value == 'box') {
      return 'boxes';
    }

    if (value.endsWith('s')) {
      return value;
    }

    return '${value}s';
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
