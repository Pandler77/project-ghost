import 'package:flutter/material.dart';

import '../../models/protocol.dart';
import '../../theme/app_theme.dart';

class EditProtocolDetailsScreen extends StatefulWidget {
  const EditProtocolDetailsScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditProtocolDetailsScreen> createState() =>
      _EditProtocolDetailsScreenState();
}

class _EditProtocolDetailsScreenState extends State<EditProtocolDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.protocol.name);
    _doseController = TextEditingController(text: widget.protocol.dose);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();

    if (name.isEmpty || dose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and dose are required.')),
      );
      return;
    }

    Navigator.pop(context, widget.protocol.copyWith(name: name, dose: dose));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protocol')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Protocol details',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Protocol name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dose',
                hintText: '3 mg',
                border: OutlineInputBorder(),
              ),
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
