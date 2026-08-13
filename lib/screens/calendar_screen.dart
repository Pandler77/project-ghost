import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../models/calendar_day_summary.dart';
import '../models/dose_record.dart';
import '../models/measurement_system.dart';
import '../models/progress_photo_session.dart';
import '../models/protocol.dart';
import '../models/symptom_entry.dart';
import '../services/app_data_service.dart';
import '../services/progress_photo_service.dart';
import '../services/protocol_schedule_service.dart';
import '../services/symptom_service.dart';
import '../theme/app_theme.dart';
import 'calendar/calendar_helpers.dart';
import 'calendar/widgets/month_calendar.dart';
import 'daily_timeline_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.dataService,
    required this.protocols,
    required this.onDataChanged,
    required this.measurementSystem,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;
  final VoidCallback onDataChanged;
  final MeasurementSystem measurementSystem;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _pastMonthCount = 120;
  static const int _futureMonthCount = 120;

  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();

  final SymptomService _symptomService = SymptomService();

  final ProgressPhotoService _progressPhotoService = ProgressPhotoService();

  final ItemScrollController _itemScrollController = ItemScrollController();

  late final List<DateTime> _months;
  late final int _currentMonthIndex;
  late DateTime _selectedDate;

  final Map<String, List<DoseRecord>> _recordsByMonth = {};
  final Map<String, List<SymptomEntry>> _symptomsByMonth = {};
  final Map<String, List<ProgressPhotoSession>> _photoSessionsByMonth = {};

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
      final results = await Future.wait([
        widget.dataService.getDoseRecordsBetween(
          visibleRange.start,
          visibleRange.end,
        ),
        _symptomService.getEntriesBetween(visibleRange.start, visibleRange.end),
        _progressPhotoService.getSessionsBetween(
          visibleRange.start,
          visibleRange.end,
        ),
      ]);

      final records = results[0] as List<DoseRecord>;

      final symptoms = results[1] as List<SymptomEntry>;

      final photoSessions = results[2] as List<ProgressPhotoSession>;

      if (!mounted) {
        return;
      }

      setState(() {
        _recordsByMonth[key] = records;
        _symptomsByMonth[key] = symptoms;
        _photoSessionsByMonth[key] = photoSessions;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recordsByMonth[key] = [];
        _symptomsByMonth[key] = [];
        _photoSessionsByMonth[key] = [];
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
      _symptomsByMonth.clear();
      _photoSessionsByMonth.clear();
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
          measurementSystem: widget.measurementSystem,
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

    final key = _monthKey(month);

    final records = _recordsByMonth[key] ?? const <DoseRecord>[];

    final symptoms = _symptomsByMonth[key] ?? const <SymptomEntry>[];

    final photoSessions =
        _photoSessionsByMonth[key] ?? const <ProgressPhotoSession>[];

    final dateRecords = records.where((record) {
      return protocolIds.contains(record.protocolId) &&
          isSameDay(record.scheduledFor, date);
    }).toList();

    final hasSymptoms = symptoms.any(
      (entry) => isSameDay(entry.recordedAt, date),
    );

    final hasPhotos = photoSessions.any(
      (session) => isSameDay(session.recordedAt, date),
    );

    return CalendarDaySummary(
      date: date,
      protocols: protocols,
      records: dateRecords,
      hasSymptoms: hasSymptoms,
      hasPhotos: hasPhotos,
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
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: _CalendarHeader(
              selectedDate: _selectedDate,
              onTodayPressed: _returnToToday,
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.selectedDate,
    required this.onTodayPressed,
  });

  final DateTime selectedDate;
  final VoidCallback onTodayPressed;

  static const List<String> _months = [
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

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get _selectedDateText {
    final weekday = _weekdays[selectedDate.weekday - 1];
    final month = _months[selectedDate.month - 1];

    return '$weekday, $month ${selectedDate.day}, ${selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.28),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            colors.primary.withValues(alpha: 0.15),
            colors.primaryContainer.withValues(alpha: 0.55),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: AppTypography.pageTitle,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppIcon.xs,
                      color: colors.onSurfaceVariant,
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    Expanded(
                      child: Text(
                        _selectedDateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: brightness == Brightness.dark ? 0.06 : 0.18,
                  ),
                  blurRadius: brightness == Brightness.dark ? 12 : 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTodayPressed,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: brightness == Brightness.dark
                        ? colors.primary.withValues(alpha: 0.08)
                        : colors.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: brightness == Brightness.dark
                          ? colors.primary.withValues(alpha: 0.42)
                          : colors.primary.withValues(alpha: 0.16),
                      width: brightness == Brightness.dark ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.today_outlined,
                        size: AppIcon.sm,
                        color: colors.primary,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
