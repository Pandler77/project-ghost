import 'package:flutter/material.dart';

import '../../models/cycle_unit.dart';
import '../../models/protocol.dart';
import '../../theme/app_theme.dart';
import '../../widgets/protocol_editor/protocol_editor.dart';

class EditCycleScreen extends StatefulWidget {
  const EditCycleScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditCycleScreen> createState() => _EditCycleScreenState();
}

class _EditCycleScreenState extends State<EditCycleScreen> {
  late final TextEditingController _onController;
  late final TextEditingController _offController;

  late bool _useCycle;
  late DateTime _cycleStartDate;
  late CycleUnit _onUnit;
  late CycleUnit _offUnit;
  late bool _repeatCycle;

  @override
  void initState() {
    super.initState();
    _onController = TextEditingController(
      text: widget.protocol.cycleOnDuration.toString(),
    );
    _offController = TextEditingController(
      text: widget.protocol.cycleOffDuration.toString(),
    );
    _useCycle = widget.protocol.useCycle;
    _cycleStartDate =
        widget.protocol.cycleStartDate ?? widget.protocol.schedule.startDate;
    _onUnit = widget.protocol.cycleOnUnit;
    _offUnit = widget.protocol.cycleOffUnit;
    _repeatCycle = widget.protocol.repeatCycle;
  }

  @override
  void dispose() {
    _onController.dispose();
    _offController.dispose();
    super.dispose();
  }

  void _save() {
    final onDuration = int.tryParse(_onController.text.trim());
    final offDuration = int.tryParse(_offController.text.trim());

    if (_useCycle && (onDuration == null || onDuration <= 0)) {
      _showMessage('Enter a valid on-cycle duration.');
      return;
    }

    if (_useCycle && (offDuration == null || offDuration < 0)) {
      _showMessage('Enter a valid off-cycle duration.');
      return;
    }

    Navigator.pop(
      context,
      widget.protocol.copyWith(
        useCycle: _useCycle,
        cycleStartDate: _useCycle
            ? DateTime(
                _cycleStartDate.year,
                _cycleStartDate.month,
                _cycleStartDate.day,
              )
            : null,
        cycleOnDuration: _useCycle ? onDuration! : 1,
        cycleOnUnit: _onUnit,
        cycleOffDuration: _useCycle ? offDuration! : 0,
        cycleOffUnit: _offUnit,
        repeatCycle: _useCycle && _repeatCycle,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            ProtocolCycleEditor(
              useCycle: _useCycle,
              cycleStartDate: _cycleStartDate,
              onDurationController: _onController,
              onUnit: _onUnit,
              offDurationController: _offController,
              offUnit: _offUnit,
              repeatCycle: _repeatCycle,
              onUseCycleChanged: (value) {
                setState(() {
                  _useCycle = value;
                  if (value && widget.protocol.cycleStartDate == null) {
                    _cycleStartDate = widget.protocol.schedule.startDate;
                  }
                });
              },
              onCycleStartDateChanged: (date) {
                setState(() => _cycleStartDate = date);
              },
              onOnUnitChanged: (unit) {
                setState(() => _onUnit = unit);
              },
              onOffUnitChanged: (unit) {
                setState(() => _offUnit = unit);
              },
              onRepeatCycleChanged: (value) {
                setState(() => _repeatCycle = value);
              },
              onValuesChanged: () {
                setState(() {});
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
