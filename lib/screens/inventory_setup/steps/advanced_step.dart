import 'package:flutter/material.dart';

import '../widgets/step_header.dart';

class AdvancedStep extends StatelessWidget {
  const AdvancedStep({
    required this.vendorController,
    required this.batchController,
    required this.notesController,
    required this.currentContainerOpenedAt,
    required this.hasOpenContainer,
    required this.onOpenedDateChanged,
    super.key,
  });

  final TextEditingController vendorController;
  final TextEditingController batchController;
  final TextEditingController notesController;

  final DateTime? currentContainerOpenedAt;
  final bool hasOpenContainer;
  final ValueChanged<DateTime?> onOpenedDateChanged;

  Future<void> _chooseOpenedDate(BuildContext context) async {
    if (!hasOpenContainer) {
      return;
    }

    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: currentContainerOpenedAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (selected == null) {
      return;
    }

    onOpenedDateChanged(DateTime(selected.year, selected.month, selected.day));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeader(
          title: 'Advanced details',
          subtitle:
              'These fields are optional. You can skip them and add them later.',
          currentStep: 6,
          totalSteps: 6,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Opened date, vendor, batch, and notes are optional. '
                  'Add only what is useful to you.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Current container',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: hasOpenContainer
                ? () {
                    _chooseOpenedDate(context);
                  }
                : null,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    color: hasOpenContainer
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Opened date',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          !hasOpenContainer
                              ? 'No container is currently open.'
                              : currentContainerOpenedAt == null
                              ? 'Not set'
                              : _formatDate(currentContainerOpenedAt!),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (hasOpenContainer && currentContainerOpenedAt != null)
                    IconButton(
                      tooltip: 'Clear opened date',
                      onPressed: () {
                        onOpenedDateChanged(null);
                      },
                      icon: const Icon(Icons.close),
                    )
                  else if (hasOpenContainer)
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        if (hasOpenContainer) ...[
          const SizedBox(height: 8),
          Text(
            'Ghost sets this automatically when inventory rollover opens '
            'a new container. You can correct it here.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: vendorController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Vendor',
            hintText: 'Optional',
            prefixIcon: Icon(Icons.store_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: batchController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Batch number',
            hintText: 'Optional',
            prefixIcon: Icon(Icons.qr_code_2_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: notesController,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Storage details, purchase date, or anything else',
            alignLabelWithHint: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(Icons.notes_outlined),
            ),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'You can edit these details from Ghost Supply at any time.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
