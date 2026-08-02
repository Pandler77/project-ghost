import '../models/cycle_status.dart';

class CycleStatusFormatter {
  const CycleStatusFormatter();

  String primaryLabel(CycleStatus status) {
    if (!status.isCycled) {
      return 'Continuous';
    }

    if (status.isBeforeStart) {
      return 'Starts soon';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'Cycle complete';
    }

    if (status.isActive) {
      return _activePhaseLabel(status);
    }

    return 'Off cycle';
  }

  String secondaryLabel(CycleStatus status) {
    if (!status.isCycled) {
      return '';
    }

    if (status.isBeforeStart) {
      final date = status.nextTransitionDate;

      return date == null ? '' : 'Starts ${_formatDate(date)}';
    }

    if (status.phaseLabel == 'Cycle complete') {
      return 'This cycle has ended';
    }

    if (status.isActive) {
      final remaining = status.daysRemainingInCurrentPhase;

      if (remaining <= 0) {
        return 'Last active day';
      }

      return '$remaining ${_dayLabel(remaining)} remaining';
    }

    final resumeDate = status.nextTransitionDate;

    if (resumeDate == null) {
      return '';
    }

    return 'Resumes ${_formatDate(resumeDate)}';
  }

  String compactLabel(CycleStatus status) {
    final primary = primaryLabel(status);
    final secondary = secondaryLabel(status);

    if (secondary.isEmpty) {
      return primary;
    }

    return '$primary • $secondary';
  }

  String _activePhaseLabel(CycleStatus status) {
    final totalDays = status.totalDaysInCurrentPhase;
    final currentDay = status.dayInCurrentPhase;

    if (totalDays <= 0 || currentDay <= 0) {
      return 'On cycle';
    }

    if (totalDays >= 7) {
      final currentWeek = ((currentDay - 1) ~/ 7) + 1;
      final totalWeeks = (totalDays / 7).ceil();

      return 'Week $currentWeek of $totalWeeks';
    }

    return 'Day $currentDay of $totalDays';
  }

  String _dayLabel(int days) {
    return days == 1 ? 'day' : 'days';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }
}
