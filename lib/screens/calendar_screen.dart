import 'package:flutter/material.dart';

import '../models/calendar_day_summary.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../services/app_data_service.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';
import 'calendar/calendar_helpers.dart';
import 'calendar/widgets/day_schedule_sheet.dart';
import 'calendar/widgets/month_calendar.dart';
import 'calendar/widgets/month_year_picker_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.dataService,
    required this.protocols,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();

  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  List<DoseRecord> _monthRecords = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(now.year, now.month, now.day);

    _displayedMonth = DateTime(now.year, now.month);

    _loadDisplayedMonth();
  }

  Future<void> _loadDisplayedMonth() async {
    final monthStart = DateTime(_displayedMonth.year, _displayedMonth.month, 1);

    final nextMonthStart = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      1,
    );

    try {
      final records = await widget.dataService.getDoseRecordsBetween(
        monthStart,
        nextMonthStart,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _monthRecords = records;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _monthRecords = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load calendar history: $error')),
      );
    }
  }

  Future<void> _showPreviousMonth() async {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });

    await _loadDisplayedMonth();
  }

  Future<void> _showNextMonth() async {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });

    await _loadDisplayedMonth();
  }

  Future<void> _returnToToday() async {
    final now = DateTime.now();

    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);

      _displayedMonth = DateTime(now.year, now.month);
    });

    await _loadDisplayedMonth();
  }

  Future<void> _showMonthYearPicker() async {
    final selectedMonth = await showDialog<DateTime>(
      context: context,
      builder: (_) => MonthYearPickerDialog(initialMonth: _displayedMonth),
    );

    if (selectedMonth == null || !mounted) {
      return;
    }

    setState(() {
      _displayedMonth = DateTime(selectedMonth.year, selectedMonth.month);
    });

    await _loadDisplayedMonth();
  }

  Future<void> _openDate(DateTime date) async {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });

    try {
      final records = await widget.dataService.getDoseRecordsForDate(date);

      if (!mounted) {
        return;
      }

      final scheduledItems = _scheduledDosesForDate(date, records);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DayScheduleSheet(date: date, items: scheduledItems),
      );

      await _loadDisplayedMonth();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load this date: $error')),
      );
    }
  }

  List<Protocol> _protocolsForDate(DateTime date) {
    return _scheduleService.protocolsForDate(widget.protocols, date);
  }

  CalendarDaySummary _summaryForDate(DateTime date) {
    final protocols = _protocolsForDate(date);

    final protocolIds = protocols.map((protocol) => protocol.id).toSet();

    final records = _monthRecords.where((record) {
      return protocolIds.contains(record.protocolId) &&
          isSameDay(record.scheduledFor, date);
    }).toList();

    return CalendarDaySummary(
      date: date,
      protocols: protocols,
      records: records,
    );
  }

  List<ScheduledDoseItem> _scheduledDosesForDate(
    DateTime date,
    List<DoseRecord> records,
  ) {
    final recordsByDose = <String, DoseRecord>{
      for (final record in records)
        _doseKey(record.protocolId, record.scheduledFor): record,
    };

    final items = <ScheduledDoseItem>[];

    for (final protocol in _protocolsForDate(date)) {
      final scheduledFor = _scheduleService.scheduledDateTime(protocol, date);

      items.add(
        ScheduledDoseItem(
          protocol: protocol,
          scheduledFor: scheduledFor,
          record: recordsByDose[_doseKey(protocol.id, scheduledFor)],
        ),
      );
    }

    return items;
  }

  String _doseKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|${scheduledFor.toIso8601String()}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Calendar',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _returnToToday,
                  child: const Text('Today'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: MonthCalendar(
                displayedMonth: _displayedMonth,
                selectedDate: _selectedDate,
                summaryForDate: _summaryForDate,
                onPreviousMonth: _showPreviousMonth,
                onNextMonth: _showNextMonth,
                onMonthPressed: _showMonthYearPicker,
                onDateSelected: _openDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
