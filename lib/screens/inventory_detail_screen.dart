import 'dart:io';

import 'package:flutter/material.dart';

import '../models/inventory_batch.dart';
import '../models/inventory_event.dart';
import '../models/inventory_item.dart';
import '../models/inventory_photo.dart';
import '../models/protocol.dart';
import '../models/protocol_category.dart';
import '../models/supply_forecast.dart';
import '../services/app_data_service.dart';
import '../services/inventory_photo_service.dart';
import '../services/supply_forecast_service.dart';
import '../theme/app_theme.dart';
import 'inventory_setup/inventory_setup_screen.dart';
import 'inventory_widgets/inventory_action_sheets.dart';
import '../theme/arctic_icons.dart';

class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({
    required this.item,
    required this.protocol,
    required this.dataService,
    super.key,
  });

  final InventoryItem item;
  final Protocol protocol;
  final AppDataService dataService;

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  late InventoryItem _item;

  List<InventoryEvent> _events = [];
  List<InventoryPhoto> _photos = [];
  List<InventoryBatch> _batches = [];

  final SupplyForecastService _forecastService = const SupplyForecastService();
  final InventoryPhotoService _photoService = InventoryPhotoService();

  bool _isLoading = true;
  String? _loadError;

  String get _supplyName {
    final value = _item.displayName?.trim();
    return value != null && value.isNotEmpty ? value : widget.protocol.name;
  }

  int get _unopenedContainerCount =>
      _batches.fold(0, (total, batch) => total + batch.quantity);

  double get _unopenedInventoryAmount =>
      _batches.fold(0.0, (total, batch) => total + batch.totalAmount);

  int get _physicalContainerCount =>
      _unopenedContainerCount + (_item.currentAmount > 0 ? 1 : 0);

  double get _totalInventoryAmount =>
      _item.currentAmount + _unopenedInventoryAmount;

  bool get _isLowStock {
    if (_totalInventoryAmount <= 0) {
      return true;
    }
    return _physicalContainerCount <= _item.lowStockThreshold;
  }

  SupplyForecast get _forecast => _forecastService.calculate(
    item: _item,
    protocol: widget.protocol,
    totalRemaining: _totalInventoryAmount,
    unopenedContainerCount: _unopenedContainerCount,
  );

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final refreshedItem = await widget.dataService
          .getInventoryItemForProtocol(widget.protocol.id);

      final item = refreshedItem ?? _item;

      final results = await Future.wait([
        widget.dataService.getInventoryEventsForItem(item.id),
        widget.dataService.getInventoryPhotosForItem(item.id),
        widget.dataService.getInventoryBatchesForItem(item.id),
      ]);

      final events = results[0] as List<InventoryEvent>;
      final photos = results[1] as List<InventoryPhoto>;
      final batches = results[2] as List<InventoryBatch>;

      if (!mounted) {
        return;
      }

      setState(() {
        _item = item;
        _events = events;
        _photos = photos;
        _batches = batches;
        _isLoading = false;
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

  Future<void> _openEditor() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InventorySetupScreen(
          dataService: widget.dataService,
          protocols: [widget.protocol],
          existingItem: _item,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _addStock() async {
    final result = await showModalBottomSheet<AddStockResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AddStockSheet(
        containerType: _item.containerType,
        unit: _item.unit,
        defaultContainerSize: _item.vialSize,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await widget.dataService.addInventoryStock(
        item: _item,
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

      if (mounted) {
        await _load();
      }
    } catch (error) {
      _showActionError('Could not add stock', error);
    }
  }

  Future<void> _adjustInventory() async {
    final result = await showModalBottomSheet<InventoryAdjustmentResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => InventoryAdjustmentSheet(item: _item),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      final correctedItem = _item.copyWith(
        vialSize: result.containerSize,
        updatedAt: DateTime.now(),
      );

      await widget.dataService.manuallyAdjustInventory(
        item: correctedItem,
        currentAmount: result.currentAmount,
        unopenedQuantity: _item.unopenedQuantity,
        notes: result.notes,
      );

      if (mounted) {
        await _load();
      }
    } catch (error) {
      _showActionError('Could not adjust inventory', error);
    }
  }

  Future<void> _editBatch(InventoryBatch batch) async {
    final result = await showModalBottomSheet<_EditBatchResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditBatchSheet(batch: batch),
    );

    if (result == null || !mounted) {
      return;
    }

    final oldTotal = batch.totalAmount;
    final newTotal = result.containerSize * result.quantity;
    final amountDifference = newTotal - oldTotal;

    final oldCount = _unopenedContainerCount;
    final newCount = oldCount - batch.quantity + result.quantity;

    final updatedBatch = InventoryBatch(
      id: batch.id,
      inventoryItemId: batch.inventoryItemId,
      name: result.name,
      containerSize: result.containerSize,
      unit: batch.unit,
      quantity: result.quantity,
      vendor: result.vendor,
      batch: result.batchNumber,
      purchaseDate: batch.purchaseDate,
      expirationDate: batch.expirationDate,
      cost: batch.cost,
      notes: batch.notes,
      createdAt: batch.createdAt,
      updatedAt: DateTime.now(),
    );

    final nextCapacity = _item.supplyCapacity + amountDifference;
    final updatedItem = _item.copyWith(
      supplyCapacity: nextCapacity < 0 ? 0 : nextCapacity,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.dataService.updateInventoryBatch(updatedBatch);
      await widget.dataService.updateInventoryItem(updatedItem);

      await widget.dataService.saveInventoryEvent(
        InventoryEvent(
          inventoryItemId: _item.id,
          protocolId: _item.protocolId,
          type: InventoryEventType.manualAdjustment,
          amountChanged: amountDifference,
          amountAfter: _item.currentAmount,
          unopenedQuantityAfter: newCount,
          notes:
              'Edited batch ${batch.name}: '
              '${batch.quantity} × ${_formatAmount(batch.containerSize)} ${batch.unit} '
              '→ ${result.quantity} × ${_formatAmount(result.containerSize)} ${batch.unit}.',
          occurredAt: DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      await _load();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Batch updated.')));
    } catch (error) {
      _showActionError('Could not update batch', error);
    }
  }

  Future<void> _openNewVial() async {
    if (_item.currentAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Finish or adjust the current '
            '${_item.containerType.toLowerCase()} before opening another.',
          ),
        ),
      );
      return;
    }

    final available = _batches
        .where((batch) => batch.quantity > 0)
        .toList(growable: false);

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is no unopened inventory available.'),
        ),
      );
      return;
    }

    final selected = available.length == 1
        ? available.first
        : await showModalBottomSheet<InventoryBatch>(
            context: context,
            useSafeArea: true,
            showDragHandle: true,
            builder: (sheetContext) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a batch',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var index = 0; index < available.length; index++) ...[
                      _BatchPickerTile(
                        batch: available[index],
                        onTap: () {
                          Navigator.pop(sheetContext, available[index]);
                        },
                      ),
                      if (index < available.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          );

    if (selected == null || !mounted) {
      return;
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Open ${selected.name}?'),
        content: Text(
          '${_formatAmount(selected.containerSize)} ${selected.unit} • '
          '${selected.quantity} unopened\n\n'
          'MODOSE will open one from this batch and leave '
          '${selected.quantity - 1} unopened.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (shouldOpen != true || !mounted) {
      return;
    }

    try {
      final updated = await widget.dataService.openNewInventoryVial(
        item: _item,
        batchId: selected.id,
      );

      if (!mounted) {
        return;
      }

      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The selected vial could not be opened.'),
          ),
        );
        return;
      }

      await _load();
    } catch (error) {
      _showActionError('Could not open a new vial', error);
    }
  }

  Future<void> _addPhotoFromGallery() async {
    try {
      final photo = await _photoService.pickAndSaveFromGallery(
        inventoryItemId: _item.id,
        dataService: widget.dataService,
      );
      if (photo != null && mounted) {
        await _load();
      }
    } catch (error) {
      _showActionError('Could not add photo', error);
    }
  }

  Future<void> _addPhotoFromCamera() async {
    try {
      final photo = await _photoService.takeAndSavePhoto(
        inventoryItemId: _item.id,
        dataService: widget.dataService,
      );
      if (photo != null && mounted) {
        await _load();
      }
    } catch (error) {
      _showActionError('Could not take photo', error);
    }
  }

  Future<void> _deletePhoto(InventoryPhoto photo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This removes the photo from this inventory item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await _photoService.deletePhoto(
        photo: photo,
        dataService: widget.dataService,
      );
      if (mounted) {
        await _load();
      }
    } catch (error) {
      _showActionError('Could not delete photo', error);
    }
  }

  Future<void> _openPhotoViewer(InventoryPhoto photo) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _InventoryPhotoViewer(
          photo: photo,
          onDelete: () => _deletePhoto(photo),
        ),
      ),
    );
  }

  void _showActionError(String message, Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(widget.protocol.colorValue);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _supplyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${widget.protocol.category.label}: ${widget.protocol.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Inventory actions',
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await _openEditor();
                  break;
                case 'add_stock':
                  await _addStock();
                  break;
                case 'open_vial':
                  await _openNewVial();
                  break;
                case 'adjust':
                  await _adjustInventory();
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
                    _item.currentAmount <= 0 && _unopenedContainerCount > 0,
                child: Row(
                  children: [
                    const Icon(ArcticIcons.science_outlined),
                    const SizedBox(width: 12),
                    Text('Open New ${_item.containerType}'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
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
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              110,
            ),
            children: [
              _HeroOverviewCard(
                item: _item,
                totalInventoryAmount: _totalInventoryAmount,
                unopenedContainerCount: _unopenedContainerCount,
                isLowStock: _isLowStock,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Current ${_item.containerType}',
                icon: ArcticIcons.science_outlined,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Panel(
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Remaining',
                      value:
                          '${_formatAmount(_item.currentAmount)} ${_item.unit}',
                    ),
                    _DetailRow(
                      label: '${_item.containerType} size',
                      value: '${_formatAmount(_item.vialSize)} ${_item.unit}',
                    ),
                    _DetailRow(
                      label: 'Opened',
                      value: _formatDateOrEmpty(_item.currentContainerOpenedAt),
                    ),
                    _DetailRow(
                      label: 'Reconstitution',
                      value: _item.reconstitutionVolumeMl == null
                          ? 'Not recorded'
                          : '${_formatAmount(_item.reconstitutionVolumeMl!)} mL',
                    ),
                    _DetailRow(
                      label: 'Concentration',
                      value: _item.concentration == null
                          ? 'Not available'
                          : '${_formatAmount(_item.concentration!)} '
                                '${_item.unit}/mL',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Unopened Supply',
                icon: ArcticIcons.inventory_2_outlined,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _UnopenedPanel(
                item: _item,
                batches: _batches,
                count: _unopenedContainerCount,
                total: _unopenedInventoryAmount,
                accent: accent,
                onEditBatch: _editBatch,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Supply Forecast',
                icon: ArcticIcons.timeline_outlined,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ForecastPanel(forecast: _forecast, item: _item, accent: accent),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Inventory Details',
                icon: ArcticIcons.info_outline,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Panel(
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Vendor',
                      value: _textOrEmpty(_item.vendor),
                    ),
                    _DetailRow(
                      label: 'Batch / Lot',
                      value: _textOrEmpty(_item.batch),
                    ),
                    _DetailRow(
                      label: 'Expiration',
                      value: _formatDateOrEmpty(_item.expirationDate),
                    ),
                    _DetailRow(
                      label: 'Storage',
                      value: _textOrEmpty(_item.storageInstructions),
                    ),
                    _DetailRow(
                      label: 'Purchase date',
                      value: _formatDateOrEmpty(_item.purchaseDate),
                    ),
                    _DetailRow(
                      label: 'Cost',
                      value: _item.cost == null
                          ? 'Not recorded'
                          : '\$${_item.cost!.toStringAsFixed(2)}',
                    ),
                    _DetailRow(
                      label: 'Notes',
                      value: _textOrEmpty(_item.notes),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Photos',
                icon: ArcticIcons.photo_library_outlined,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _PhotosPanel(
                photos: _photos,
                accent: accent,
                onCamera: _addPhotoFromCamera,
                onGallery: _addPhotoFromGallery,
                onOpenPhoto: _openPhotoViewer,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Inventory History',
                icon: ArcticIcons.history,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              _HistoryPanel(
                events: _events,
                isLoading: _isLoading,
                loadError: _loadError,
                accent: accent,
                onRetry: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroOverviewCard extends StatelessWidget {
  const _HeroOverviewCard({
    required this.item,
    required this.totalInventoryAmount,
    required this.unopenedContainerCount,
    required this.isLowStock,
    required this.accent,
  });

  final InventoryItem item;
  final double totalInventoryAmount;
  final int unopenedContainerCount;
  final bool isLowStock;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            accent.withValues(alpha: 0.24),
            colors.surface.withValues(alpha: 0.96),
          ]
        : [accent.withValues(alpha: 0.12), colors.surface];

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
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(
                label: isLowStock ? 'Low Supply' : 'Healthy',
                icon: isLowStock
                    ? ArcticIcons.warning_amber_rounded
                    : Icons.check_circle_outline,
                accent: isLowStock ? colors.error : accent,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.46),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$unopenedContainerCount unopened',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${_formatAmount(item.currentAmount)} / '
            '${_formatAmount(item.vialSize)} ${item.unit}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'remaining in current ${item.containerType.toLowerCase()}',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: item.currentVialProgress,
              minHeight: 10,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'TOTAL SUPPLY',
                  value: '${_formatAmount(totalInventoryAmount)} ${item.unit}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroMetric(
                  label: 'UNOPENED',
                  value: '$unopenedContainerCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).cardTheme.color ?? colors.surface;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: child,
    );
  }
}

class _UnopenedPanel extends StatelessWidget {
  const _UnopenedPanel({
    required this.item,
    required this.batches,
    required this.count,
    required this.total,
    required this.accent,
    required this.onEditBatch,
  });

  final InventoryItem item;
  final List<InventoryBatch> batches;
  final int count;
  final double total;
  final Color accent;
  final ValueChanged<InventoryBatch> onEditBatch;

  @override
  Widget build(BuildContext context) {
    final available = batches
        .where((batch) => batch.quantity > 0)
        .toList(growable: false);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count ${_containerLabel(item.containerType, count)} • '
            '${_formatAmount(total)} ${item.unit}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Low-stock threshold',
            value:
                '${item.lowStockThreshold} '
                '${_containerLabel(item.containerType, item.lowStockThreshold)}',
          ),
          _DetailRow(
            label: 'Shipping lead time',
            value:
                '${item.shippingDays} '
                '${item.shippingDays == 1 ? 'day' : 'days'}',
            showDivider: false,
          ),
          if (available.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < available.length; index++) ...[
              _BatchInventoryTile(
                batch: available[index],
                accent: accent,
                onEdit: () => onEditBatch(available[index]),
              ),
              if (index < available.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _BatchInventoryTile extends StatelessWidget {
  const _BatchInventoryTile({
    required this.batch,
    required this.accent,
    required this.onEdit,
  });

  final InventoryBatch batch;
  final Color accent;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final details = <String>[
      '${_formatAmount(batch.containerSize)} ${batch.unit}',
      '${batch.quantity} unopened',
      if (batch.vendor != null && batch.vendor!.trim().isNotEmpty)
        batch.vendor!.trim(),
      if (batch.batch != null && batch.batch!.trim().isNotEmpty)
        'Lot ${batch.batch!.trim()}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.05),
          colors.surfaceContainerLowest,
        ),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(ArcticIcons.science_outlined, size: 19, color: accent),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details.join(' • '),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit batch',
            visualDensity: VisualDensity.compact,
            icon: Icon(ArcticIcons.edit_outlined, size: 19, color: accent),
          ),
        ],
      ),
    );
  }
}

class _EditBatchResult {
  const _EditBatchResult({
    required this.name,
    required this.containerSize,
    required this.quantity,
    this.vendor,
    this.batchNumber,
  });

  final String name;
  final double containerSize;
  final int quantity;
  final String? vendor;
  final String? batchNumber;
}

class _EditBatchSheet extends StatefulWidget {
  const _EditBatchSheet({required this.batch});

  final InventoryBatch batch;

  @override
  State<_EditBatchSheet> createState() => _EditBatchSheetState();
}

class _EditBatchSheetState extends State<_EditBatchSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _vendorController;
  late final TextEditingController _batchController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.batch.name);
    _sizeController = TextEditingController(
      text: _formatAmount(widget.batch.containerSize),
    );
    _quantityController = TextEditingController(
      text: widget.batch.quantity.toString(),
    );
    _vendorController = TextEditingController(text: widget.batch.vendor ?? '');
    _batchController = TextEditingController(text: widget.batch.batch ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _vendorController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final containerSize = double.tryParse(_sizeController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());

    if (name.isEmpty) {
      _showError('Batch name is required.');
      return;
    }

    if (containerSize == null || containerSize <= 0) {
      _showError('Enter a valid container strength.');
      return;
    }

    if (quantity == null || quantity < 0) {
      _showError('Enter a valid unopened quantity.');
      return;
    }

    Navigator.pop(
      context,
      _EditBatchResult(
        name: name,
        containerSize: containerSize,
        quantity: quantity,
        vendor: _optionalText(_vendorController.text),
        batchNumber: _optionalText(_batchController.text),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Batch',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Correct this batch directly. Changes update unopened totals '
              'and are recorded as a manual inventory adjustment.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Batch name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Strength',
                      suffixText: widget.batch.unit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Unopened',
                      suffixText: widget.batch.quantity == 1
                          ? 'container'
                          : 'containers',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _vendorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vendor (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Lot / batch number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Batch'),
              ),
            ),
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
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
                      '${_formatAmount(batch.containerSize)} ${batch.unit} • '
                      '${batch.quantity} unopened',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
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

class _ForecastPanel extends StatelessWidget {
  const _ForecastPanel({
    required this.forecast,
    required this.item,
    required this.accent,
  });

  final SupplyForecast forecast;
  final InventoryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasForecast = forecast.averageDailyUsage > 0;

    final urgencyColor = switch (forecast.daysRemaining) {
      <= 14 => colors.error,
      <= 30 => colors.tertiary,
      <= 60 => colors.secondary,
      _ => accent,
    };

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasForecast
                ? '${forecast.daysRemaining} '
                      '${forecast.daysRemaining == 1 ? 'day' : 'days'} remaining'
                : 'Forecast unavailable',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            hasForecast
                ? 'Reorder by ${_formatDate(forecast.reorderDate)}'
                : 'MODOSE needs compatible dose and inventory units.',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: forecast.percentRemaining.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
            ),
          ),
          if (hasForecast) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_formatAmount(forecast.averageDailyUsage)} '
              '${item.unit}/day • '
              'depletes ${_formatDate(forecast.depletionDate)}',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotosPanel extends StatelessWidget {
  const _PhotosPanel({
    required this.photos,
    required this.accent,
    required this.onCamera,
    required this.onGallery,
    required this.onOpenPhoto,
  });

  final List<InventoryPhoto> photos;
  final Color accent;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<InventoryPhoto> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Panel(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 92,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (sheetContext) => Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(ArcticIcons.photo_camera_outlined),
                            title: const Text('Take Photo'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onCamera();
                            },
                          ),
                          ListTile(
                            leading: const Icon(ArcticIcons.collections_outlined),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onGallery();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Ink(
                  width: 82,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(ArcticIcons.add_a_photo_outlined, color: accent),
                ),
              ),
            ),
            if (photos.isEmpty) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 190,
                child: Center(
                  child: Text(
                    'Add vial, packaging, receipt, or COA photos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ] else
              for (final photo in photos) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => onOpenPhoto(photo),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Container(
                    width: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.60),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Image.file(
                        File(photo.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            ArcticIcons.broken_image_outlined,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _InventoryPhotoViewer extends StatelessWidget {
  const _InventoryPhotoViewer({required this.photo, required this.onDelete});

  final InventoryPhoto photo;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        actions: [
          IconButton(
            tooltip: 'Delete photo',
            onPressed: () async {
              await onDelete();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(ArcticIcons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Image.file(File(photo.imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.events,
    required this.isLoading,
    required this.loadError,
    required this.accent,
    required this.onRetry,
  });

  final List<InventoryEvent> events;
  final bool isLoading;
  final String? loadError;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loadError != null) {
            return Column(
              children: [
                Text(
                  'Could not load inventory history.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(onPressed: onRetry, child: const Text('Try Again')),
              ],
            );
          }

          if (events.isEmpty) {
            return Text(
              'No inventory history yet.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }

          return Column(
            children: [
              for (var index = 0; index < events.length; index++) ...[
                _InventoryEventRow(event: events[index], accent: accent),
                if (index < events.length - 1)
                  const Divider(height: AppSpacing.lg),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InventoryEventRow extends StatelessWidget {
  const _InventoryEventRow({required this.event, required this.accent});

  final InventoryEvent event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isPositive = event.amountChanged > 0;
    final isNegative = event.amountChanged < 0;
    final prefix = isPositive ? '+' : '';
    final amountText = event.amountChanged == 0
        ? null
        : '$prefix${_formatAmount(event.amountChanged)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(_eventIcon(event.type), size: 17, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.type.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDateTime(event.occurredAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (event.notes != null && event.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(event.notes!, style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
        ),
        if (amountText != null)
          Text(
            amountText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isNegative ? Theme.of(context).colorScheme.error : accent,
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: colors.outlineVariant),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _eventIcon(InventoryEventType type) {
  return switch (type) {
    InventoryEventType.created => ArcticIcons.add_box_outlined,
    InventoryEventType.doseDeducted => Icons.remove_circle_outline,
    InventoryEventType.doseRestored => ArcticIcons.restore,
    InventoryEventType.vialOpened => ArcticIcons.science_outlined,
    InventoryEventType.stockAdded => ArcticIcons.inventory_2_outlined,
    InventoryEventType.manualAdjustment => ArcticIcons.tune,
    InventoryEventType.archived => ArcticIcons.archive_outlined,
  };
}

String _containerLabel(String containerType, int count) {
  final value = containerType.trim().toLowerCase();

  if (count == 1) {
    return value;
  }

  if (value == 'box') {
    return 'boxes';
  }

  if (value.endsWith('s')) {
    return value;
  }

  return '${value}s';
}

String _textOrEmpty(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Not recorded';
  }
  return value.trim();
}

String _formatDateOrEmpty(DateTime? value) {
  if (value == null) {
    return 'Not recorded';
  }
  return _formatDate(value);
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _formatDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${_formatDate(value)} • $hour:$minute $period';
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

