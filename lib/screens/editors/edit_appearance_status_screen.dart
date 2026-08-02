import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../models/protocol_status.dart';
import '../../theme/app_theme.dart';
import '../../theme/protocol_colors.dart';

class EditAppearanceStatusScreen extends StatefulWidget {
  const EditAppearanceStatusScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditAppearanceStatusScreen> createState() =>
      _EditAppearanceStatusScreenState();
}

class _EditAppearanceStatusScreenState
    extends State<EditAppearanceStatusScreen> {
  late int _selectedColorValue;
  late ProtocolStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.protocol.colorValue;
    _selectedStatus = widget.protocol.status;
  }

  void _save() {
    Navigator.pop(
      context,
      widget.protocol.copyWith(
        colorValue: _selectedColorValue,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance & Status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Protocol color',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This color identifies the protocol throughout Ghost.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final colorValue in ProtocolColors.available)
                  _ProtocolColorChoice(
                    colorValue: colorValue,
                    isSelected: _selectedColorValue == colorValue,
                    onTap: () {
                      setState(() => _selectedColorValue = colorValue);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<ProtocolStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Protocol status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProtocolStatus.active,
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: ProtocolStatus.paused,
                  child: Text('Paused'),
                ),
                DropdownMenuItem(
                  value: ProtocolStatus.archived,
                  child: Text('Archived'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolColorChoice extends StatelessWidget {
  const _ProtocolColorChoice({
    required this.colorValue,
    required this.isSelected,
    required this.onTap,
  });

  final int colorValue;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select protocol color',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
