import '../models/cycle_status.dart';
import '../models/cycle_unit.dart';
import '../models/protocol.dart';

class CycleTimelineFormatter {
  const CycleTimelineFormatter();

  String sectionTitle(CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Upcoming Cycle';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Cycle Complete';
    }

    return status.isActive ? 'Current Cycle' : 'Off Cycle';
  }

  String badgeLabel(CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Not Started';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Complete';
    }

    return status.isActive ? 'On Cycle' : 'Off Cycle';
  }

  String cycleNumberLabel(Protocol protocol, CycleStatus status) {
    if (!protocol.repeatCycle || status.currentCycleNumber <= 0) {
      return '';
    }

    return 'Cycle ${status.currentCycleNumber}';
  }

  String primaryProgressLabel(Protocol protocol, CycleStatus status) {
    if (status.isBeforeStart) {
      return 'Starts ${formatShortDate(status.nextTransitionDate)}';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Protocol cycle finished';
    }

    final unit = status.isActive ? protocol.cycleOnUnit : protocol.cycleOffUnit;

    return phaseProgressLabel(
      currentDay: status.dayInCurrentPhase,
      totalDays: status.totalDaysInCurrentPhase,
      unit: unit,
    );
  }

  String phaseProgressLabel({
    required int currentDay,
    required int totalDays,
    required CycleUnit unit,
  }) {
    switch (unit) {
      case CycleUnit.days:
        return 'Day $currentDay of $totalDays';

      case CycleUnit.weeks:
        final currentWeek = ((currentDay - 1) ~/ 7) + 1;

        final totalWeeks = (totalDays / 7).ceil();

        return 'Week $currentWeek of $totalWeeks';

      case CycleUnit.months:
        final currentMonth = ((currentDay - 1) ~/ 30) + 1;

        final totalMonths = (totalDays / 30).ceil();

        return 'Month $currentMonth of $totalMonths';
    }
  }

  double progress(CycleStatus status) {
    final total = status.totalDaysInCurrentPhase;

    if (total <= 0) {
      return status.isBeforeStart ? 0 : 1;
    }

    final current = status.dayInCurrentPhase.clamp(0, total);

    return (current / total).clamp(0.0, 1.0);
  }

  String remainingText(int days) {
    if (days <= 0) {
      return 'Last Day';
    }

    return '$days ${days == 1 ? 'Day' : 'Days'} Remaining';
  }

  String formatShortDate(DateTime? date) {
    if (date == null) {
      return '—';
    }

    return '${_monthName(date.month)} ${date.day}';
  }

  String formatFullDate(DateTime? date) {
    if (date == null) {
      return '—';
    }

    return '${_monthName(date.month)} '
        '${date.day}, ${date.year}';
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
}
