import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/calendar_day_summary.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../services/app_data_service.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';
import 'calendar/calendar_helpers.dart';
import 'calendar/widgets/month_calendar.dart';
import 'daily_timeline_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.dataService,
    required this.protocols,
    required this.onDataChanged,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;
  final VoidCallback onDataChanged;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _pastMonthCount = 120;
  static const int _futureMonthCount = 120;

  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();

  final ItemScrollController _itemScrollController = ItemScrollController();

  late final List<DateTime> _months;
  late final int _currentMonthIndex;

  late DateTime _selectedDate;

  final Map<String, List<DoseRecord>> _recordsByMonth = {};
  final Set<String> _loadingMonths = {};

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(now.year, now.month, now.day);

    final currentMonth = DateTime(now.year, now.month);

    _months = List<DateTime>.generate(_pastMonthCount + _futureMonthCount + 1, (
      index,
    ) {
      final monthOffset = index - _pastMonthCount;

      return DateTime(currentMonth.year, currentMonth.month + monthOffset);
    });

    _currentMonthIndex = _pastMonthCount;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMonthLoaded(currentMonth);
    });
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.protocols != widget.protocols) {
      _reloadCalendar();
    }
  }

  String _monthKey(DateTime month) {
    return '${month.year}-'
        '${month.month.toString().padLeft(2, '0')}';
  }

  Future<void> _ensureMonthLoaded(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);

    final key = _monthKey(normalizedMonth);

    if (_recordsByMonth.containsKey(key) || _loadingMonths.contains(key)) {
      return;
    }

    _loadingMonths.add(key);

    final visibleRange = _visibleRangeForMonth(normalizedMonth);

    try {
      final records = await widget.dataService.getDoseRecordsBetween(
        visibleRange.start,
        visibleRange.end,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recordsByMonth[key] = records;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recordsByMonth[key] = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load calendar history: $error')),
      );
    } finally {
      _loadingMonths.remove(key);
    }
  }

  DateTimeRange _visibleRangeForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);

    final lastDay = DateTime(month.year, month.month + 1, 0);

    final leadingDays = firstDay.weekday % 7;

    final trailingDays = 6 - (lastDay.weekday % 7);

    final visibleStart = firstDay.subtract(Duration(days: leadingDays));

    final visibleEndExclusive = lastDay.add(Duration(days: trailingDays + 1));

    return DateTimeRange(start: visibleStart, end: visibleEndExclusive);
  }

  Future<void> _reloadCalendar() async {
    setState(() {
      _recordsByMonth.clear();
      _loadingMonths.clear();
    });

    final selectedMonth = DateTime(_selectedDate.year, _selectedDate.month);

    await _ensureMonthLoaded(selectedMonth);
  }

  Future<void> _returnToToday() async {
    final now = DateTime.now();

    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });

    await _ensureMonthLoaded(DateTime(now.year, now.month));

    if (!_itemScrollController.isAttached) {
      return;
    }

    await _itemScrollController.scrollTo(
      index: _currentMonthIndex,
      alignment: 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openDate(DateTime date) async {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyTimelineScreen(
          date: date,
          protocols: widget.protocols,
          dataService: widget.dataService,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _reloadCalendar();
  }

  List<Protocol> _protocolsForDate(DateTime date) {
    return _scheduleService.protocolsForDate(widget.protocols, date);
  }

  CalendarDaySummary _summaryForDate({
    required DateTime month,
    required DateTime date,
  }) {
    final protocols = _protocolsForDate(date);

    final protocolIds = protocols.map((protocol) => protocol.id).toSet();

    final records = _recordsByMonth[_monthKey(month)] ?? const <DoseRecord>[];

    final dateRecords = records.where((record) {
      return protocolIds.contains(record.protocolId) &&
          isSameDay(record.scheduledFor, date);
    }).toList();

    return CalendarDaySummary(
      date: date,
      protocols: protocols,
      records: dateRecords,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scroll through your schedule',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _returnToToday,
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text('Today'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              initialScrollIndex: _currentMonthIndex,
              initialAlignment: 0,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                100,
              ),
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];

                _ensureMonthLoaded(month);

                return MonthCalendar(
                  key: ValueKey(_monthKey(month)),
                  displayedMonth: month,
                  selectedDate: _selectedDate,
                  summaryForDate: (date) {
                    return _summaryForDate(month: month, date: date);
                  },
                  onDateSelected: _openDate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
