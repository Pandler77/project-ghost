import '../models/cycle_status.dart';
import '../models/cycle_unit.dart';
import '../models/protocol.dart';

class CycleStatusService {
  const CycleStatusService();

  CycleStatus statusForDate(Protocol protocol, DateTime date) {
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (!protocol.useCycle) {
      return const CycleStatus(
        isCycled: false,
        isActive: true,
        isBeforeStart: false,
        currentCycleNumber: 0,
        dayInCurrentPhase: 0,
        totalDaysInCurrentPhase: 0,
        daysRemainingInCurrentPhase: 0,
        nextTransitionDate: null,
        phaseLabel: 'Continuous',
      );
    }

    final configuredStart =
        protocol.cycleStartDate ?? protocol.schedule.startDate;

    final startDate = DateTime(
      configuredStart.year,
      configuredStart.month,
      configuredStart.day,
    );

    final onDays = _durationInDays(
      protocol.cycleOnDuration,
      protocol.cycleOnUnit,
    );

    final offDays = _durationInDays(
      protocol.cycleOffDuration,
      protocol.cycleOffUnit,
    );

    if (selectedDate.isBefore(startDate)) {
      return CycleStatus(
        isCycled: true,
        isActive: false,
        isBeforeStart: true,
        currentCycleNumber: 0,
        dayInCurrentPhase: 0,
        totalDaysInCurrentPhase: onDays,
        daysRemainingInCurrentPhase: startDate.difference(selectedDate).inDays,
        nextTransitionDate: startDate,
        phaseLabel: 'Starts soon',
      );
    }

    final daysSinceStart = selectedDate.difference(startDate).inDays;

    if (!protocol.repeatCycle) {
      final isActive = daysSinceStart < onDays;

      if (isActive) {
        final dayInPhase = daysSinceStart + 1;

        return CycleStatus(
          isCycled: true,
          isActive: true,
          isBeforeStart: false,
          currentCycleNumber: 1,
          dayInCurrentPhase: dayInPhase,
          totalDaysInCurrentPhase: onDays,
          daysRemainingInCurrentPhase: onDays - dayInPhase,
          nextTransitionDate: startDate.add(Duration(days: onDays)),
          phaseLabel: 'On cycle',
        );
      }

      return const CycleStatus(
        isCycled: true,
        isActive: false,
        isBeforeStart: false,
        currentCycleNumber: 1,
        dayInCurrentPhase: 0,
        totalDaysInCurrentPhase: 0,
        daysRemainingInCurrentPhase: 0,
        nextTransitionDate: null,
        phaseLabel: 'Cycle complete',
      );
    }

    if (offDays <= 0) {
      final dayInPhase = daysSinceStart + 1;

      return CycleStatus(
        isCycled: true,
        isActive: true,
        isBeforeStart: false,
        currentCycleNumber: 1,
        dayInCurrentPhase: dayInPhase,
        totalDaysInCurrentPhase: onDays,
        daysRemainingInCurrentPhase: 0,
        nextTransitionDate: null,
        phaseLabel: 'On cycle',
      );
    }

    final cycleLength = onDays + offDays;
    final cycleIndex = daysSinceStart ~/ cycleLength;
    final position = daysSinceStart % cycleLength;
    final cycleStart = startDate.add(Duration(days: cycleIndex * cycleLength));

    final isActive = position < onDays;

    if (isActive) {
      final dayInPhase = position + 1;

      return CycleStatus(
        isCycled: true,
        isActive: true,
        isBeforeStart: false,
        currentCycleNumber: cycleIndex + 1,
        dayInCurrentPhase: dayInPhase,
        totalDaysInCurrentPhase: onDays,
        daysRemainingInCurrentPhase: onDays - dayInPhase,
        nextTransitionDate: cycleStart.add(Duration(days: onDays)),
        phaseLabel: 'On cycle',
      );
    }

    final offPosition = position - onDays;
    final dayInPhase = offPosition + 1;

    return CycleStatus(
      isCycled: true,
      isActive: false,
      isBeforeStart: false,
      currentCycleNumber: cycleIndex + 1,
      dayInCurrentPhase: dayInPhase,
      totalDaysInCurrentPhase: offDays,
      daysRemainingInCurrentPhase: offDays - dayInPhase,
      nextTransitionDate: cycleStart.add(Duration(days: cycleLength)),
      phaseLabel: 'Off cycle',
    );
  }

  int _durationInDays(int duration, CycleUnit unit) {
    if (duration <= 0) {
      return 0;
    }

    return switch (unit) {
      CycleUnit.days => duration,
      CycleUnit.weeks => duration * 7,
      CycleUnit.months => duration * 30,
    };
  }
}
