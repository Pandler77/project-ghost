import 'package:flutter/material.dart';

import '../models/daily_protocol_item.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily/edit_day_sheet.dart';

class DailyTimelineScreen extends StatefulWidget {
  const DailyTimelineScreen({
    required this.date,
    required this.protocols,
    required this.dataService,
    required this.onDataChanged,
    super.key,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final AppDataService dataService;
  final VoidCallback onDataChanged;

  @override
  State<DailyTimelineScreen> createState() => _DailyTimelineScreenState();
}

class _DailyTimelineScreenState extends State<DailyTimelineScreen>
    with SingleTickerProviderStateMixin {
  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();

  late final TabController _tabController;

  WeightRecord? _weightRecord;
  List<DailyProtocolItem> _protocolItems = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _loadDay();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDay() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        widget.dataService.getWeightRecordForDate(widget.date),
        widget.dataService.getDoseRecordsForDate(widget.date),
      ]);

      final weightRecord = results[0] as WeightRecord?;

      final doseRecords = results[1] as List<DoseRecord>;

      final recordsByDose = <String, DoseRecord>{
        for (final record in doseRecords)
          _doseKey(record.protocolId, record.scheduledFor): record,
      };

      final scheduledProtocols = _scheduleService.protocolsForDate(
        widget.protocols,
        widget.date,
      );

      final items = <DailyProtocolItem>[];

      for (final protocol in scheduledProtocols) {
        final scheduledFor = _scheduleService.scheduledDateTime(
          protocol,
          widget.date,
        );

        items.add(
          DailyProtocolItem(
            protocol: protocol,
            scheduledFor: scheduledFor,
            record: recordsByDose[_doseKey(protocol.id, scheduledFor)],
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _weightRecord = weightRecord;
        _protocolItems = items;
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

  Future<void> _openDayEditor() async {
    final result = await showModalBottomSheet<EditDayResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return EditDaySheet(
          date: widget.date,
          protocolItems: _protocolItems,
          weightRecord: _weightRecord,
          onSave: (result) {
            Navigator.pop(sheetContext, result);
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await _saveDayChanges(result);
  }

  Future<void> _saveDayChanges(EditDayResult result) async {
    try {
      await _saveWeightChanges(result);
      await _saveProtocolChanges(result);

      if (!mounted) {
        return;
      }

      await _loadDay();

      if (!mounted) {
        return;
      }

      widget.onDataChanged();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Day updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update this day: $error')),
      );
    }
  }

  Future<void> _saveWeightChanges(EditDayResult result) async {
    if (result.deleteWeight) {
      final existingWeight = _weightRecord;

      if (existingWeight != null) {
        await widget.dataService.deleteWeightRecord(existingWeight.id);
      }

      return;
    }

    if (result.weight == null) {
      return;
    }

    final recordedAt = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      12,
    );

    final weightRecord = WeightRecord(
      id:
          _weightRecord?.id ??
          'weight-'
              '${widget.date.year}-'
              '${widget.date.month}-'
              '${widget.date.day}',
      weight: result.weight!,
      recordedAt: recordedAt,
    );

    await widget.dataService.saveWeightRecord(weightRecord);
  }

  Future<void> _saveProtocolChanges(EditDayResult result) async {
    for (final change in result.protocolChanges) {
      final item = change.item;
      final existingRecord = item.record;

      if (!change.isTaken) {
        if (existingRecord != null) {
          await widget.dataService.deleteDoseRecord(
            protocolId: item.protocol.id,
            scheduledFor: item.scheduledFor,
          );
        }

        continue;
      }

      final completedAt = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        change.completedTime.hour,
        change.completedTime.minute,
      );

      final record = DoseRecord(
        id:
            existingRecord?.id ??
            '${item.protocol.id}-'
                '${item.scheduledFor.microsecondsSinceEpoch}',
        protocolId: item.protocol.id,
        scheduledFor: item.scheduledFor,
        scheduledAmount: item.protocol.dose,
        actualAmount: change.actualAmount,
        completedAt: completedAt,
        status: DoseRecordStatus.taken,
      );

      await widget.dataService.saveDoseRecord(record);
    }
  }

  String _doseKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|'
        '${scheduledFor.toIso8601String()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day'),
        actions: [
          TextButton.icon(
            onPressed: _openDayEditor,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Could not load this day.',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _loadDay, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DateHeader(date: widget.date),

        const SizedBox(height: AppSpacing.lg),

        _ProtocolsSection(items: _protocolItems),

        const SizedBox(height: AppSpacing.lg),

        _WeightSection(record: _weightRecord),

        const SizedBox(height: AppSpacing.lg),

        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notes & Symptoms'),
            Tab(text: 'Photos'),
          ],
        ),

        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _tabController,
            children: const [
              _EmptyTabContent(
                icon: Icons.notes_outlined,
                title: 'No notes or symptoms',
                message: 'Notes and symptom tracking will appear here.',
              ),
              _EmptyTabContent(
                icon: Icons.photo_library_outlined,
                title: 'No progress photos',
                message: 'Progress photo sessions will appear here.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _weekdayName(date.weekday),
          style: TextStyle(
            fontSize: AppTypography.body,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_monthName(date.month)} '
          '${date.day}, ${date.year}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ProtocolsSection extends StatelessWidget {
  const _ProtocolsSection({required this.items});

  final List<DailyProtocolItem> items;

  @override
  Widget build(BuildContext context) {
    return _TimelineSection(
      title: 'Protocols',
      child: items.isEmpty
          ? Text(
              'Nothing scheduled.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _ProtocolRow(item: items[index]),
                  if (index < items.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({required this.item});

  final DailyProtocolItem item;

  @override
  Widget build(BuildContext context) {
    final color = Color(item.protocol.colorValue);

    final isTaken = item.isTaken;
    final displayedAmount = item.displayedAmount;

    final statusText = isTaken
        ? item.record?.completedAt == null
              ? 'Taken'
              : 'Taken at '
                    '${_formatDateTime(item.record!.completedAt!)}'
        : 'Scheduled for '
              '${_formatDateTime(item.scheduledFor)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 19,
                    color: isTaken
                        ? const Color(0xFF34C759)
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.protocol.name,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                displayedAmount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightSection extends StatelessWidget {
  const _WeightSection({required this.record});

  final WeightRecord? record;

  @override
  Widget build(BuildContext context) {
    return _TimelineSection(
      title: 'Weight',
      child: record == null
          ? Text(
              'No weight recorded.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              '${record!.weight.toStringAsFixed(1)} lb',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  const _EmptyTabContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdays[weekday - 1];
}

String _monthName(int month) {
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

  return months[month - 1];
}

String _formatDateTime(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');

  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}
