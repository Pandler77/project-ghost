import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../theme/app_theme.dart';
import '../../theme/arctic_icons.dart';

class AddStockResult {
  const AddStockResult({
    required this.batchName,
    required this.containerSize,
    required this.quantity,
    this.vendor,
    this.batch,
    this.purchaseDate,
    this.expirationDate,
    this.cost,
    this.notes,
  });

  final String batchName;
  final double containerSize;
  final int quantity;

  final String? vendor;
  final String? batch;

  final DateTime? purchaseDate;
  final DateTime? expirationDate;

  final double? cost;
  final String? notes;
}

class AddStockSheet extends StatefulWidget {
  const AddStockSheet({
    required this.containerType,
    required this.unit,
    required this.defaultContainerSize,
    super.key,
  });

  final String containerType;
  final String unit;
  final double defaultContainerSize;

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  late final TextEditingController _containerSizeController;

  final TextEditingController _batchNameController = TextEditingController();

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  final TextEditingController _vendorController = TextEditingController();

  final TextEditingController _batchController = TextEditingController();

  final TextEditingController _costController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();

    _containerSizeController = TextEditingController(
      text: formatInventoryAmount(widget.defaultContainerSize),
    );
  }

  @override
  void dispose() {
    _containerSizeController.dispose();
    _batchNameController.dispose();
    _quantityController.dispose();
    _vendorController.dispose();
    _batchController.dispose();
    _costController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double? get _containerSize {
    return double.tryParse(_containerSizeController.text.trim());
  }

  int? get _quantity {
    return int.tryParse(_quantityController.text.trim());
  }

  double? get _cost {
    final value = _costController.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  bool get _canSave {
    final batchName = _batchNameController.text.trim();
    final size = _containerSize;
    final quantity = _quantity;

    if (batchName.isEmpty) {
      return false;
    }

    if (size == null || size <= 0) {
      return false;
    }

    if (quantity == null || quantity <= 0) {
      return false;
    }

    if (_costController.text.trim().isNotEmpty && _cost == null) {
      return false;
    }

    return true;
  }

  Future<void> _choosePurchaseDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _purchaseDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  Future<void> _chooseExpirationDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _expirationDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      ArcticIcons.add_box_outlined,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Inventory',
                          style: TextStyle(
                            fontSize: AppTypography.title,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add a new batch of unopened '
                          '${pluralizeInventory(widget.containerType.toLowerCase())}.',
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
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _batchNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Batch name *',
                hintText: 'Example: QSC 100mg Kit',
                prefixIcon: Icon(ArcticIcons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _containerSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Container size',
                      suffixText: widget.unit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: pluralizeInventory(
                        widget.containerType.toLowerCase(),
                      ),
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
                labelText: 'Vendor',
                hintText: 'Optional',
                prefixIcon: Icon(ArcticIcons.store_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _batchController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Batch / lot',
                hintText: 'Optional',
                prefixIcon: Icon(ArcticIcons.qr_code_2_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InventoryBatchDateTile(
              label: 'Purchase date',
              value: _purchaseDate,
              icon: ArcticIcons.shopping_bag_outlined,
              onTap: _choosePurchaseDate,
              onClear: _purchaseDate == null
                  ? null
                  : () {
                      setState(() {
                        _purchaseDate = null;
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            InventoryBatchDateTile(
              label: 'Expiration date',
              value: _expirationDate,
              icon: ArcticIcons.event_busy_outlined,
              onTap: _chooseExpirationDate,
              onClear: _expirationDate == null
                  ? null
                  : () {
                      setState(() {
                        _expirationDate = null;
                      });
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Cost',
                hintText: 'Optional',
                prefixText: '\$ ',
                prefixIcon: Icon(ArcticIcons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSave
                    ? () {
                        Navigator.pop(
                          context,
                          AddStockResult(
                            batchName: _batchNameController.text.trim(),
                            containerSize: _containerSize!,
                            quantity: _quantity!,
                            vendor: optionalInventoryText(
                              _vendorController.text,
                            ),
                            batch: optionalInventoryText(
                              _batchController.text,
                            ),
                            purchaseDate: _purchaseDate,
                            expirationDate: _expirationDate,
                            cost: _cost,
                            notes: optionalInventoryText(
                              _notesController.text,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(ArcticIcons.add_box_outlined),
                label: const Text(
                  'Add Inventory',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class InventoryBatchDateTile extends StatelessWidget {
  const InventoryBatchDateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.60)),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value == null
                          ? 'Not set'
                          : formatInventoryDate(value!),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryAdjustmentResult {
  const InventoryAdjustmentResult({
    required this.containerSize,
    required this.currentAmount,
    required this.notes,
  });

  final double containerSize;
  final double currentAmount;
  final String? notes;
}

class InventoryAdjustmentSheet extends StatefulWidget {
  const InventoryAdjustmentSheet({
    required this.item,
    super.key,
  });

  final InventoryItem item;

  @override
  State<InventoryAdjustmentSheet> createState() =>
      _InventoryAdjustmentSheetState();
}

class _InventoryAdjustmentSheetState
    extends State<InventoryAdjustmentSheet> {
  late final TextEditingController _containerSizeController;
  late final TextEditingController _currentAmountController;

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _containerSizeController = TextEditingController(
      text: formatInventoryAmount(widget.item.vialSize),
    );

    _currentAmountController = TextEditingController(
      text: formatInventoryAmount(widget.item.currentAmount),
    );
  }

  @override
  void dispose() {
    _containerSizeController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double? get _containerSize {
    return double.tryParse(_containerSizeController.text.trim());
  }

  double? get _currentAmount {
    return double.tryParse(_currentAmountController.text.trim());
  }

  bool get _canSave {
    final containerSize = _containerSize;
    final currentAmount = _currentAmount;

    if (containerSize == null || containerSize <= 0) {
      return false;
    }

    if (currentAmount == null || currentAmount < 0) {
      return false;
    }

    return currentAmount <= containerSize;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      ArcticIcons.tune_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adjust Inventory',
                          style: TextStyle(
                            fontSize: AppTypography.title,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Correct the active '
                          '${widget.item.containerType.toLowerCase()} '
                          'when MODOSE does not match what you physically have.',
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
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _containerSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: '${widget.item.containerType} size',
                suffixText: widget.item.unit,
                helperText:
                    'The full amount this '
                    '${widget.item.containerType.toLowerCase()} '
                    'originally contained.',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _currentAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Current amount',
                suffixText: widget.item.unit,
                helperText: _containerSize == null
                    ? null
                    : 'Maximum '
                        '${formatInventoryAmount(_containerSize!)} '
                        '${widget.item.unit}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Example: Entered the wrong vial size during setup',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSave
                    ? () {
                        Navigator.pop(
                          context,
                          InventoryAdjustmentResult(
                            containerSize: _containerSize!,
                            currentAmount: _currentAmount!,
                            notes: optionalInventoryText(
                              _notesController.text,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Save Adjustment',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

String? optionalInventoryText(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String pluralizeInventory(String value) {
  if (value == 'box') {
    return 'boxes';
  }

  if (value.endsWith('s')) {
    return value;
  }

  return '${value}s';
}

String formatInventoryAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String formatInventoryDate(DateTime value) {
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

