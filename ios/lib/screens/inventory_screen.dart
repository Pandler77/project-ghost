import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/protocol_category.dart';
import '../services/app_data_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'inventory_detail_screen.dart';
import 'inventory_setup/inventory_setup_screen.dart';
import 'inventory_widgets/inventory_action_sheets.dart';
import '../models/inventory_batch.dart';
import 'premium_screen.dart';
import '../theme/arctic_icons.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    required this.dataService,
    required this.protocols,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settingsService = SettingsService();

  List<InventoryItem> _items = [];
  final Map<String, List<InventoryBatch>> _batchesByItemId = {};

  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';
  bool _showBetaInformation = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _loadBetaInformationPreference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final protocolName = _protocolName(item.protocolId).toLowerCase();
      final displayName = item.displayName?.toLowerCase() ?? '';

      final vendor = item.vendor?.toLowerCase() ?? '';

      final batch = item.batch?.toLowerCase() ?? '';

      final containerType = item.containerType.toLowerCase();

      return displayName.contains(query) ||
          protocolName.contains(query) ||
          vendor.contains(query) ||
          batch.contains(query) ||
          containerType.contains(query);
    }).toList();
  }

  Future<void> _loadInventory() async {
    try {
      final items = await widget.dataService.getInventoryItems();

      final batchEntries = await Future.wait(
        items.map((item) async {
          final batches = await widget.dataService.getInventoryBatchesForItem(
            item.id,
          );
          return MapEntry(item.id, batches);
        }),
      );

      final batchesByItemId = <String, List<InventoryBatch>>{
        for (final entry in batchEntries) entry.key: entry.value,
      };

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _batchesByItemId
          ..clear()
          ..addAll(batchesByItemId);
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _loadBetaInformationPreference() async {
    final dismissed = await _settingsService.getGhostSupplyBetaDismissed();

    if (!mounted) {
      return;
    }

    setState(() {
      _showBetaInformation = !dismissed;
    });
  }

  Future<void> _dismissBetaInformation() async {
    await _settingsService.saveGhostSupplyBetaDismissed(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _showBetaInformation = false;
    });
  }

  Future<void> _openSetup({InventoryItem? item}) async {
    final availableProtocols = item == null
        ? widget.protocols.where((protocol) {
            return !_items.any(
              (inventory) => inventory.protocolId == protocol.id,
            );
          }).toList()
        : widget.protocols;

    if (item == null && availableProtocols.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Every protocol already has ArcticDose Supply configured.',
          ),
        ),
      );

      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InventorySetupScreen(
          dataService: widget.dataService,
          protocols: availableProtocols,
          existingItem: item,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadInventory();
    }
  }

  Future<void> _addStock(InventoryItem item) async {
    final result = await showModalBottomSheet<AddStockResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return AddStockSheet(
          containerType: item.containerType,
          unit: item.unit,
          defaultContainerSize: item.vialSize,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await widget.dataService.addInventoryStock(
        item: item,
        batchName: result.batchName,
        containerSize: result.containerSize,
        quantity: result.quantity,
        vendor: result.vendor,
        batchNumber: result.batch,
        purchaseDate: result.purchaseDate,
        expirationDate: result.expirationDate,
        cost: result.cost,
        notes: result.notes,
      );

      if (!mounted) {
        return;
      }

      await _loadInventory();
    } catch (error) {
      _showActionError('Could not add stock', error);
    }
  }

  Future<void> _adjustInventory(InventoryItem item) async {
    final result = await showModalBottomSheet<InventoryAdjustmentResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return InventoryAdjustmentSheet(item: item);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      final correctedItem = item.copyWith(
        vialSize: result.containerSize,
        updatedAt: DateTime.now(),
      );

      await widget.dataService.manuallyAdjustInventory(
        item: correctedItem,
        currentAmount: result.currentAmount,
        unopenedQuantity: item.unopenedQuantity,
        notes: result.notes,
      );

      if (!mounted) {
        return;
      }

      await _loadInventory();
    } catch (error) {
      _showActionError('Could not adjust inventory', error);
    }
  }

  Future<void> _openNewVial(InventoryItem item) async {
    if (item.currentAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Finish or adjust the current '
            '${item.containerType.toLowerCase()} before opening another.',
          ),
        ),
      );
      return;
    }

    final availableBatches = _batchesForItem(
      item,
    ).where((batch) => batch.quantity > 0).toList(growable: false);

    if (availableBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no unopened inventory available.'),
        ),
      );
      return;
    }

    InventoryBatch? selectedBatch;

    if (availableBatches.length == 1) {
      selectedBatch = availableBatches.first;
    } else {
      selectedBatch = await showModalBottomSheet<InventoryBatch>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a batch',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the named batch you are opening from.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (
                  var index = 0;
                  index < availableBatches.length;
                  index++
                ) ...[
                  _BatchPickerTile(
                    batch: availableBatches[index],
                    onTap: () {
                      Navigator.pop(sheetContext, availableBatches[index]);
                    },
                  ),
                  if (index < availableBatches.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          );
        },
      );
    }

    if (selectedBatch == null || !mounted) {
      return;
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Open ${selectedBatch!.name}?'),
          content: Text(
            '${_formatNumber(selectedBatch.containerSize)} '
            '${selectedBatch.unit} • '
            '${selectedBatch.quantity} unopened\n\n'
            'ArcticDose will open one from this batch and leave '
            '${selectedBatch.quantity - 1} unopened.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true || !mounted) {
      return;
    }

    try {
      final updatedItem = await widget.dataService.openNewInventoryVial(
        item: item,
        batchId: selectedBatch.id,
      );

      if (!mounted) {
        return;
      }

      if (updatedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The selected vial could not be opened.'),
          ),
        );
        return;
      }

      await _loadInventory();
    } catch (error) {
      _showActionError('Could not open a new vial', error);
    }
  }

  void _showActionError(String message, Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove ArcticDose Supply?'),
          content: const Text(
            'This removes the ArcticDose Supply record. '
            'The protocol and dose history will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.dataService.deleteInventoryItem(item.id);

    if (!mounted) {
      return;
    }

    await _loadInventory();
  }

  String _protocolName(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol.name;
      }
    }

    return 'Unknown Protocol';
  }

  Protocol? _protocolForId(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol;
      }
    }

    return null;
  }

  List<InventoryBatch> _batchesForItem(InventoryItem item) {
    return _batchesByItemId[item.id] ?? const [];
  }

  int _unopenedCountForItem(InventoryItem item) {
    return _batchesForItem(
      item,
    ).fold<int>(0, (total, batch) => total + batch.quantity);
  }

  Future<void> _openDetail(InventoryItem item) async {
    final protocol = _protocolForId(item.protocolId);

    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The linked protocol could not be found.'),
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryDetailScreen(
          item: item,
          protocol: protocol,
          dataService: widget.dataService,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadInventory();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dataService.hasPremium) {
      return _PremiumInventoryPreview(dataService: widget.dataService);
    }
    return Scaffold(
      appBar: AppBar(title: const _GhostSupplyTitle()),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(ArcticIcons.error_outline, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Could not load ArcticDose Supply.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });

                  _loadInventory();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          48,
        ),
        children: [
          if (_showBetaInformation) ...[
            _GhostSupplyBetaInformation(onDismiss: _dismissBetaInformation),
            const SizedBox(height: AppSpacing.md),
          ],
          _EmptyInventoryState(
            onAddPressed: () {
              _openSetup();
            },
          ),
        ],
      );
    }

    final filteredItems = _filteredItems;

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          48,
        ),
        children: [
          if (_showBetaInformation) ...[
            _GhostSupplyBetaInformation(onDismiss: _dismissBetaInformation),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search supplies',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: FilledButton.tonal(
                  onPressed: () {
                    _openSetup();
                  },
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (filteredItems.isEmpty)
            const _NoMatchingInventory()
          else
            for (var index = 0; index < filteredItems.length; index++) ...[
              _InventoryCard(
                item: filteredItems[index],
                protocol: _protocolForId(filteredItems[index].protocolId),
                protocolName: _protocolName(filteredItems[index].protocolId),
                unopenedContainerCount: _unopenedCountForItem(
                  filteredItems[index],
                ),
                formatNumber: _formatNumber,
                onOpen: () {
                  _openDetail(filteredItems[index]);
                },
                onEdit: () {
                  _openSetup(item: filteredItems[index]);
                },
                onAddStock: () {
                  _addStock(filteredItems[index]);
                },
                onOpenNewVial: () {
                  _openNewVial(filteredItems[index]);
                },
                onAdjust: () {
                  _adjustInventory(filteredItems[index]);
                },
                onDelete: () {
                  _deleteItem(filteredItems[index]);
                },
              ),
              if (index < filteredItems.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _GhostSupplyTitle extends StatelessWidget {
  const _GhostSupplyTitle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('ArcticDose Supply™'),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.protocol,
    required this.protocolName,
    required this.unopenedContainerCount,
    required this.formatNumber,
    required this.onOpen,
    required this.onEdit,
    required this.onAddStock,
    required this.onOpenNewVial,
    required this.onAdjust,
    required this.onDelete,
  });

  final InventoryItem item;
  final Protocol? protocol;
  final String protocolName;
  final int unopenedContainerCount;
  final String Function(double value) formatNumber;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback onOpenNewVial;
  final VoidCallback onAdjust;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = protocol == null
        ? colors.primary
        : Color(protocol!.colorValue);

    final supplyName = item.displayName?.trim().isNotEmpty == true
        ? item.displayName!.trim()
        : protocolName;

    final categoryLabel = protocol == null
        ? 'Protocol'
        : protocol!.category.label;

    final containerName = item.containerType.toLowerCase();
    final lowSupply =
        (unopenedContainerCount + (item.currentAmount > 0 ? 1 : 0)) <=
        item.lowStockThreshold;

    final cardBackground = Color.alphaBlend(
      accent.withValues(alpha: 0.10),
      colors.surface,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: accent.withValues(alpha: 0.42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$categoryLabel: $protocolName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Supply options',
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'add_stock':
                          onAddStock();
                          break;
                        case 'open_vial':
                          onOpenNewVial();
                          break;
                        case 'adjust':
                          onAdjust();
                          break;
                        case 'remove':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit Supply'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_stock',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.add_box_outlined),
                            SizedBox(width: 12),
                            Text('Add Stock'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'open_vial',
                        enabled:
                            item.currentAmount <= 0 &&
                            unopenedContainerCount > 0,
                        child: Row(
                          children: [
                            const Icon(ArcticIcons.science_outlined),
                            const SizedBox(width: 12),
                            Text('Open New ${item.containerType}'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'adjust',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.tune),
                            SizedBox(width: 12),
                            Text('Adjust Inventory'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.delete_outline),
                            SizedBox(width: 12),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: item.currentVialProgress,
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.currentAmount > 0
                          ? '${formatNumber(item.currentAmount)} / '
                                '${formatNumber(item.vialSize)} ${item.unit} left'
                          : 'No $containerName open',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ContainerCount(
                    containerType: item.containerType,
                    count: unopenedContainerCount,
                    accent: accent,
                  ),
                ],
              ),
              if (lowSupply) ...[
                const SizedBox(height: 8),
                _WarningIndicator(
                  label: unopenedContainerCount == 0 && item.currentAmount <= 0
                      ? 'Out of stock'
                      : 'Low supply',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchPickerTile extends StatelessWidget {
  const _BatchPickerTile({required this.batch, required this.onTap});

  final InventoryBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final details = <String>[
      '${batch.quantity} unopened',
      if (batch.vendor != null && batch.vendor!.trim().isNotEmpty)
        batch.vendor!.trim(),
      if (batch.batch != null && batch.batch!.trim().isNotEmpty)
        'Lot ${batch.batch!.trim()}',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(ArcticIcons.inventory_2_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatBatchAmount(batch.containerSize)} '
                      '${batch.unit} • ${details.join(' • ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatBatchAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class _ContainerCount extends StatelessWidget {
  const _ContainerCount({
    required this.containerType,
    required this.count,
    required this.accent,
  });

  final String containerType;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ContainerPlaceholder(containerType: containerType, accent: accent),
          const SizedBox(width: 6),
          Text(
            '$count unopened',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ContainerPlaceholder extends StatelessWidget {
  const _ContainerPlaceholder({
    required this.containerType,
    required this.accent,
  });

  final String containerType;
  final Color accent;

  IconData get _icon {
    switch (containerType.trim().toLowerCase()) {
      case 'vial':
        return ArcticIcons.science_outlined;
      case 'bottle':
        return ArcticIcons.local_drink_outlined;
      case 'pen':
        return ArcticIcons.edit_outlined;
      case 'box':
        return ArcticIcons.inventory_2_outlined;
      case 'tube':
        return ArcticIcons.medication_liquid_outlined;
      case 'package':
        return ArcticIcons.all_inbox_outlined;
      default:
        return ArcticIcons.inventory_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, size: 16, color: accent);
  }
}

class _WarningIndicator extends StatelessWidget {
  const _WarningIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ArcticIcons.warning_amber_rounded, size: 16, color: colors.error),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.error,
          ),
        ),
      ],
    );
  }
}

class _GhostSupplyBetaInformation extends StatefulWidget {
  const _GhostSupplyBetaInformation({required this.onDismiss});

  final Future<void> Function() onDismiss;

  @override
  State<_GhostSupplyBetaInformation> createState() =>
      _GhostSupplyBetaInformationState();
}

class _GhostSupplyBetaInformationState
    extends State<_GhostSupplyBetaInformation> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(ArcticIcons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ArcticDose Supply Beta Information',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ArcticDose Supply is currently in beta. Automatic '
                    'deductions work best when the protocol dose and '
                    'inventory use compatible units.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Commonly supported units',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const _BetaUnitRow(label: 'Mass', units: 'mcg, mg, g'),
                  const _BetaUnitRow(label: 'Volume', units: 'mL'),
                  const _BetaUnitRow(
                    label: 'Count',
                    units:
                        'IU, units, tablets, capsules, pills, softgels, drops',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Custom units can still be tracked. Automatic '
                    'deduction may be unavailable unless the protocol '
                    'and inventory units match.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BetaUnitRow extends StatelessWidget {
  const _BetaUnitRow({required this.label, required this.units});

  final String label;
  final String units;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 17,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $units',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingInventory extends StatelessWidget {
  const _NoMatchingInventory();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(ArcticIcons.search_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No matching inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching by protocol, vendor, batch, or container type.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(ArcticIcons.inventory_2_outlined, size: 64),

            const SizedBox(height: AppSpacing.md),

            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                const Text(
                  'Set up ArcticDose Supply™',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'BETA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Track current amounts, unopened '
              'containers, and low-stock alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumInventoryPreview extends StatelessWidget {
  const _PremiumInventoryPreview({required this.dataService});

  final AppDataService dataService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const _GhostSupplyTitle()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              ArcticIcons.inventory_2_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart inventory tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track what remains, unopened '
              'containers, and reorder timing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            const _PremiumFeature(
              icon: Icons.remove_circle_outline,
              text: 'Automatic deductions when doses are completed',
            ),
            const _PremiumFeature(
              icon: ArcticIcons.inventory_outlined,
              text: 'Track current and unopened containers',
            ),
            const _PremiumFeature(
              icon: ArcticIcons.warning_amber_outlined,
              text: 'Low-stock and reorder alerts',
            ),
            const _PremiumFeature(
              icon: ArcticIcons.local_shipping_outlined,
              text: 'Estimated shipping and depletion timing',
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PremiumScreen(dataService: dataService),
                  ),
                );
              },
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
