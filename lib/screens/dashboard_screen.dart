import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/dose_service.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/today_doses_card.dart';
import '../widgets/weekly_preview_card.dart';
import '../widgets/weight_card.dart';
import 'add_protocol_screen.dart';
import 'calendar/widgets/day_schedule_sheet.dart';
import '../widgets/onboarding_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.protocols,
    required this.onProtocolAdded,
    required this.dataService,
    required this.displayName,
    super.key,
  });

  final List<Protocol> protocols;
  final Future<void> Function(Protocol protocol) onProtocolAdded;
  final AppDataService dataService;
  final String displayName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DoseService _doseService = DoseService();

  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();

  List<Dose> _doses = [];
  List<WeightRecord> _weightRecords = [];

  Timer? _refreshTimer;

  bool _isLoadingWeight = true;

  @override
  void initState() {
    super.initState();

    _loadDashboardData();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadDoseData();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.protocols != widget.protocols) {
      _loadDoseData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_loadDoseData(), _loadWeightData()]);
  }

  Future<void> _loadDoseData() async {
    final refreshedDoses = _doseService.getTodaysDoses(widget.protocols);

    final savedRecords = await widget.dataService.getDoseRecordsForDate(
      DateTime.now(),
    );

    final recordsByDose = <String, DoseRecord>{
      for (final record in savedRecords)
        _doseKey(record.protocolId, record.scheduledFor): record,
    };

    for (final dose in refreshedDoses) {
      final record =
          recordsByDose[_doseKey(dose.protocolId, dose.scheduledFor)];

      if (record?.status == DoseRecordStatus.taken) {
        dose.completedAt = record!.completedAt;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _doses = refreshedDoses;
    });
  }

  Future<void> _loadWeightData() async {
    final records = await widget.dataService.getWeightRecords();

    if (!mounted) {
      return;
    }

    setState(() {
      _weightRecords = records;
      _isLoadingWeight = false;
    });
  }

  Future<void> _toggleDose(Dose dose) async {
    if (dose.isCompleted) {
      await widget.dataService.deleteDoseRecord(
        protocolId: dose.protocolId,
        scheduledFor: dose.scheduledFor,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        dose.completedAt = null;
      });

      return;
    }

    final completedAt = DateTime.now();

    final record = DoseRecord(
      id:
          '${dose.protocolId}-'
          '${dose.scheduledFor.microsecondsSinceEpoch}',
      protocolId: dose.protocolId,
      scheduledFor: dose.scheduledFor,
      scheduledAmount: dose.amount,
      actualAmount: dose.amount,
      completedAt: completedAt,
      status: DoseRecordStatus.taken,
    );

    await widget.dataService.saveDoseRecord(record);

    if (!mounted) {
      return;
    }

    setState(() {
      dose.completedAt = completedAt;
    });
  }

  Future<void> _openWeeklyDay(DateTime date) async {
    try {
      final records = await widget.dataService.getDoseRecordsForDate(date);

      if (!mounted) {
        return;
      }

      final recordsByDose = <String, DoseRecord>{
        for (final record in records)
          _doseKey(record.protocolId, record.scheduledFor): record,
      };

      final scheduledProtocols = _scheduleService.protocolsForDate(
        widget.protocols,
        date,
      );

      final items = <ScheduledDoseItem>[];

      for (final protocol in scheduledProtocols) {
        final scheduledFor = _scheduleService.scheduledDateTime(protocol, date);

        items.add(
          ScheduledDoseItem(
            protocol: protocol,
            scheduledFor: scheduledFor,
            record: recordsByDose[_doseKey(protocol.id, scheduledFor)],
          ),
        );
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DayScheduleSheet(date: date, items: items),
      );

      await _loadDoseData();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load this date: $error')),
      );
    }
  }

  Future<void> _openAddProtocol() async {
    final protocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => const AddProtocolScreen()),
    );

    if (protocol == null || !mounted) {
      return;
    }

    await widget.onProtocolAdded(protocol);

    if (!mounted) {
      return;
    }

    await _loadDoseData();
  }

  Future<void> _openWeightDialog() async {
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightEntryDialog(
        initialWeight: _weightRecords.isEmpty
            ? null
            : _weightRecords.first.weight,
        isFirstEntry: _weightRecords.isEmpty,
      ),
    );

    if (weight == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    final record = WeightRecord(
      id: now.microsecondsSinceEpoch.toString(),
      weight: weight,
      recordedAt: now,
    );

    await widget.dataService.saveWeightRecord(record);

    if (!mounted) {
      return;
    }

    await _loadWeightData();
  }

  String _doseKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|'
        '${scheduledFor.toIso8601String()}';
  }

  @override
  Widget build(BuildContext context) {
    final hasProtocols = widget.protocols.isNotEmpty;
    final hasWeight = _weightRecords.isNotEmpty;

    final currentWeight = hasWeight ? _weightRecords.first.weight : null;

    final startingWeight = hasWeight ? _weightRecords.last.weight : null;

    return Scaffold(
      floatingActionButton: hasProtocols
          ? FloatingActionButton(
              onPressed: _openAddProtocol,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            110,
          ),
          children: [
            DashboardHeader(name: widget.displayName),

            const SizedBox(height: AppSpacing.lg),

            if (!hasProtocols) ...[
              OnboardingCard(
                hasWeight: hasWeight,
                onAddProtocol: _openAddProtocol,
                onLogWeight: _openWeightDialog,
              ),

              if (hasWeight) ...[
                const SizedBox(height: AppSpacing.lg),

                WeightCard(
                  currentWeight: currentWeight!,
                  startingWeight: startingWeight!,
                  weightRecords: _weightRecords,
                  onLogWeight: _openWeightDialog,
                ),
              ],
            ] else ...[
              TodayDosesCard(doses: _doses, onDosePressed: _toggleDose),

              const SizedBox(height: AppSpacing.lg),

              WeeklyPreviewCard(
                protocols: widget.protocols,
                onDayTapped: _openWeeklyDay,
              ),

              const SizedBox(height: AppSpacing.lg),

              if (_isLoadingWeight)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (!hasWeight)
                _EmptyWeightCard(onLogWeight: _openWeightDialog)
              else
                WeightCard(
                  currentWeight: currentWeight!,
                  startingWeight: startingWeight!,
                  weightRecords: _weightRecords,
                  onLogWeight: _openWeightDialog,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyWeightCard extends StatelessWidget {
  const _EmptyWeightCard({required this.onLogWeight});

  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No weight entries yet.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogWeight,
                icon: const Icon(Icons.add),
                label: const Text('Set Starting Weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({
    required this.initialWeight,
    required this.isFirstEntry,
  });

  final double? initialWeight;
  final bool isFirstEntry;

  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_controller.text.trim());

    if (weight == null || weight <= 0) {
      return;
    }

    Navigator.pop(context, weight);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isFirstEntry ? 'Set Starting Weight' : 'Log Weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Weight',
          suffixText: 'lb',
          hintText: '350.0',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
