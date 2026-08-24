import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

import '../widgets/step_header.dart';
import '../../../theme/arctic_icons.dart';

class AdvancedStep extends StatelessWidget {
  const AdvancedStep({
    required this.vendorController,
    required this.batchController,
    required this.notesController,
    required this.reconstitutionVolumeController,
    required this.storageInstructionsController,
    required this.costController,
    required this.currentContainerOpenedAt,
    required this.expirationDate,
    required this.purchaseDate,
    required this.hasOpenContainer,
    required this.containerType,
    required this.unit,
    required this.onOpenedDateChanged,
    required this.onExpirationDateChanged,
    required this.onPurchaseDateChanged,
    required this.onAdvancedFieldChanged,
    super.key,
  });

  final TextEditingController vendorController;
  final TextEditingController batchController;
  final TextEditingController notesController;
  final TextEditingController reconstitutionVolumeController;
  final TextEditingController storageInstructionsController;
  final TextEditingController costController;

  final DateTime? currentContainerOpenedAt;
  final DateTime? expirationDate;
  final DateTime? purchaseDate;

  final bool hasOpenContainer;
  final String containerType;
  final String unit;

  final ValueChanged<DateTime?> onOpenedDateChanged;
  final ValueChanged<DateTime?> onExpirationDateChanged;
  final ValueChanged<DateTime?> onPurchaseDateChanged;
  final VoidCallback onAdvancedFieldChanged;

  bool get _supportsReconstitution {
    return containerType.trim().toLowerCase() == 'vial';
  }

  Future<void> _chooseOpenedDate(BuildContext context) async {
    if (!hasOpenContainer) return;

    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: currentContainerOpenedAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selected == null) return;

    onOpenedDateChanged(DateTime(selected.year, selected.month, selected.day));
  }

  Future<void> _chooseExpirationDate(BuildContext context) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: expirationDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );

    if (selected == null) return;

    onExpirationDateChanged(
      DateTime(selected.year, selected.month, selected.day),
    );
  }

  Future<void> _choosePurchaseDate(BuildContext context) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selected == null) return;

    onPurchaseDateChanged(
      DateTime(selected.year, selected.month, selected.day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final infoText = _supportsReconstitution
        ? 'Add reconstitution, dates, vendor details, cost, storage information, and notes if they are useful to you.'
        : 'Add dates, vendor details, cost, storage information, and notes if they are useful to you.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'Advanced details',
          subtitle: 'These fields are optional. You can skip them and add them later.',
          currentStep: 7,
          totalSteps: 7,
        ),
        const SizedBox(height: AppSpacing.lg),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ArcticIcons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  infoText,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Current container',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),

        _DateCard(
          icon: ArcticIcons.event_outlined,
          title: 'Opened date',
          value: !hasOpenContainer
              ? 'No container is currently open.'
              : currentContainerOpenedAt == null
              ? 'Not set'
              : _formatDate(currentContainerOpenedAt!),
          enabled: hasOpenContainer,
          onTap: hasOpenContainer ? () => _chooseOpenedDate(context) : null,
          onClear: hasOpenContainer && currentContainerOpenedAt != null
              ? () => onOpenedDateChanged(null)
              : null,
        ),

        if (hasOpenContainer) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'MODOSE sets this automatically when inventory rollover opens a new container. You can correct it here.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        if (_supportsReconstitution) ...[
          const Text(
            'Reconstitution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: reconstitutionVolumeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onAdvancedFieldChanged(),
            decoration: const InputDecoration(
              labelText: 'Reconstitution volume',
              hintText: 'Optional',
              suffixText: 'mL',
              prefixIcon: Icon(ArcticIcons.water_drop_outlined),
              helperText: 'Used to calculate concentration automatically.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        const Text(
          'Dates',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),

        _DateCard(
          icon: ArcticIcons.event_busy_outlined,
          title: 'Expiration date',
          value: expirationDate == null ? 'Not set' : _formatDate(expirationDate!),
          onTap: () => _chooseExpirationDate(context),
          onClear: expirationDate == null ? null : () => onExpirationDateChanged(null),
        ),

        const SizedBox(height: AppSpacing.sm),

        _DateCard(
          icon: ArcticIcons.shopping_bag_outlined,
          title: 'Purchase date',
          value: purchaseDate == null ? 'Not set' : _formatDate(purchaseDate!),
          onTap: () => _choosePurchaseDate(context),
          onClear: purchaseDate == null ? null : () => onPurchaseDateChanged(null),
        ),

        const SizedBox(height: AppSpacing.lg),

        const Text(
          'Supply details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),

        TextField(
          controller: vendorController,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onAdvancedFieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Vendor',
            hintText: 'Optional',
            prefixIcon: Icon(ArcticIcons.store_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: batchController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => onAdvancedFieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Batch / lot number',
            hintText: 'Optional',
            prefixIcon: Icon(ArcticIcons.qr_code_2_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onAdvancedFieldChanged(),
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
          controller: storageInstructionsController,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onAdvancedFieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Storage instructions',
            hintText: 'Example: Refrigerate after opening',
            alignLabelWithHint: true,
            prefixIcon: Icon(ArcticIcons.ac_unit_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: notesController,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onAdvancedFieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Anything else you want to remember',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(ArcticIcons.notes_outlined),
            ),
            border: OutlineInputBorder(),
          ),
        ),

        if (_supportsReconstitution) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Concentration will be calculated as $unit per mL when a reconstitution volume is provided.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.sm),

        Text(
          'You can edit these details from MODOSE Supply at any time.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.icon,
    required this.title,
    required this.value,
    this.enabled = true,
    this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: enabled ? onTap : null,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $title',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              else if (enabled)
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

