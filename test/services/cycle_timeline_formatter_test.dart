import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_status.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/services/cycle_timeline_formatter.dart';

import '../helpers/protocol_factory.dart';

void main() {
  const formatter = CycleTimelineFormatter();

  group('CycleTimelineFormatter', () {
    test('formats active cycle title and badge', () {
      final status = _status(isActive: true, phaseLabel: 'On cycle');

      expect(formatter.sectionTitle(status), 'Current Cycle');

      expect(formatter.badgeLabel(status), 'On Cycle');
    });

    test('formats off-cycle title and badge', () {
      final status = _status(isActive: false, phaseLabel: 'Off cycle');

      expect(formatter.sectionTitle(status), 'Off Cycle');

      expect(formatter.badgeLabel(status), 'Off Cycle');
    });

    test('formats future cycle state', () {
      final status = _status(
        isActive: false,
        isBeforeStart: true,
        phaseLabel: 'Starts soon',
        nextTransitionDate: DateTime(2026, 8, 10),
      );

      expect(formatter.sectionTitle(status), 'Upcoming Cycle');

      expect(formatter.badgeLabel(status), 'Not Started');
    });

    test('formats completed cycle state', () {
      final status = _status(isActive: false, phaseLabel: 'Cycle complete');

      expect(formatter.sectionTitle(status), 'Cycle Complete');

      expect(formatter.badgeLabel(status), 'Complete');
    });

    test('formats repeating cycle number', () {
      final protocol = buildTestProtocol(repeatCycle: true);

      final status = _status(currentCycleNumber: 3);

      expect(formatter.cycleNumberLabel(protocol, status), 'Cycle 3');
    });

    test('does not format cycle number for non-repeating protocol', () {
      final protocol = buildTestProtocol(repeatCycle: false);

      final status = _status(currentCycleNumber: 1);

      expect(formatter.cycleNumberLabel(protocol, status), isEmpty);
    });

    test('formats day progress', () {
      expect(
        formatter.phaseProgressLabel(
          currentDay: 3,
          totalDays: 7,
          unit: CycleUnit.days,
        ),
        'Day 3 of 7',
      );
    });

    test('formats week progress', () {
      expect(
        formatter.phaseProgressLabel(
          currentDay: 9,
          totalDays: 28,
          unit: CycleUnit.weeks,
        ),
        'Week 2 of 4',
      );
    });

    test('formats month progress', () {
      expect(
        formatter.phaseProgressLabel(
          currentDay: 35,
          totalDays: 90,
          unit: CycleUnit.months,
        ),
        'Month 2 of 3',
      );
    });

    test('calculates progress value', () {
      final status = _status(dayInCurrentPhase: 5, totalDaysInCurrentPhase: 10);

      expect(formatter.progress(status), 0.5);
    });

    test('clamps progress above one', () {
      final status = _status(
        dayInCurrentPhase: 15,
        totalDaysInCurrentPhase: 10,
      );

      expect(formatter.progress(status), 1.0);
    });

    test('formats remaining day text', () {
      expect(formatter.remainingText(1), '1 Day Remaining');

      expect(formatter.remainingText(8), '8 Days Remaining');

      expect(formatter.remainingText(0), 'Last Day');
    });

    test('formats dates', () {
      final date = DateTime(2026, 8, 14);

      expect(formatter.formatShortDate(date), 'August 14');

      expect(formatter.formatFullDate(date), 'August 14, 2026');
    });

    test('formats null dates as dash', () {
      expect(formatter.formatShortDate(null), '—');

      expect(formatter.formatFullDate(null), '—');
    });
  });
}

CycleStatus _status({
  bool isCycled = true,
  bool isActive = true,
  bool isBeforeStart = false,
  String phaseLabel = 'On cycle',
  int currentCycleNumber = 1,
  int dayInCurrentPhase = 1,
  int totalDaysInCurrentPhase = 7,
  int daysRemainingInCurrentPhase = 6,
  DateTime? nextTransitionDate,
}) {
  return CycleStatus(
    isCycled: isCycled,
    isActive: isActive,
    isBeforeStart: isBeforeStart,
    phaseLabel: phaseLabel,
    currentCycleNumber: currentCycleNumber,
    dayInCurrentPhase: dayInCurrentPhase,
    totalDaysInCurrentPhase: totalDaysInCurrentPhase,
    daysRemainingInCurrentPhase: daysRemainingInCurrentPhase,
    nextTransitionDate: nextTransitionDate,
  );
}
