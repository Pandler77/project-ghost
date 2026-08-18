import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../models/protocol_status.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_color_picker.dart';

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
              'This color identifies the protocol throughout ArcticDose.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppColorPicker(
              selectedColorValue: _selectedColorValue,
              onColorChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedColorValue = value;
                });
              },
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
