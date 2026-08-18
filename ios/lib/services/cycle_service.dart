import '../models/cycle_unit.dart';
import '../models/protocol.dart';

class CycleService {
  const CycleService();

  bool isProtocolActive(Protocol protocol, DateTime date) {
    if (!protocol.useCycle) {
      return true;
    }

    final cycleStartDate = protocol.cycleStartDate;

    if (cycleStartDate == null) {
      return true;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);

    final normalizedStartDate = DateTime(
      cycleStartDate.year,
      cycleStartDate.month,
      cycleStartDate.day,
    );

    if (normalizedDate.isBefore(normalizedStartDate)) {
      return false;
    }

    final onDays = _durationInDays(
      protocol.cycleOnDuration,
      protocol.cycleOnUnit,
    );

    final offDays = _durationInDays(
      protocol.cycleOffDuration,
      protocol.cycleOffUnit,
    );

    if (onDays <= 0) {
      return false;
    }

    final daysSinceStart = normalizedDate
        .difference(normalizedStartDate)
        .inDays;

    if (!protocol.repeatCycle) {
      return daysSinceStart < onDays;
    }

    if (offDays <= 0) {
      return true;
    }

    final fullCycleDays = onDays + offDays;
    final positionInCycle = daysSinceStart % fullCycleDays;

    return positionInCycle < onDays;
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
