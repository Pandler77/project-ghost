import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/services/cycle_status_service.dart';

import '../helpers/protocol_factory.dart';

void main() {
  const service = CycleStatusService();

  group('CycleStatusService', () {
    test('continuous protocol returns continuous status', () {
      final protocol = buildTestProtocol(useCycle: false);

      final status = service.statusForDate(protocol, DateTime(2026, 8, 10));

      expect(status.isCycled, isFalse);
      expect(status.isActive, isTrue);
      expect(status.phaseLabel, 'Continuous');
      expect(status.nextTransitionDate, isNull);
    });

    test('future cycle reports before-start state', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 10),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.weeks,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 5));

      expect(status.isCycled, isTrue);
      expect(status.isBeforeStart, isTrue);
      expect(status.isActive, isFalse);
      expect(status.phaseLabel, 'Starts soon');
      expect(status.nextTransitionDate, DateTime(2026, 8, 10));
      expect(status.daysRemainingInCurrentPhase, 5);
    });

    test('active repeating cycle reports correct day and transition', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 5,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 3));

      expect(status.isActive, isTrue);
      expect(status.currentCycleNumber, 1);
      expect(status.dayInCurrentPhase, 3);
      expect(status.totalDaysInCurrentPhase, 5);
      expect(status.daysRemainingInCurrentPhase, 2);
      expect(status.nextTransitionDate, DateTime(2026, 8, 6));
      expect(status.phaseLabel, 'On cycle');
    });

    test('off cycle reports correct day and resume date', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 5,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 6));

      expect(status.isActive, isFalse);
      expect(status.currentCycleNumber, 1);
      expect(status.dayInCurrentPhase, 1);
      expect(status.totalDaysInCurrentPhase, 2);
      expect(status.daysRemainingInCurrentPhase, 1);
      expect(status.nextTransitionDate, DateTime(2026, 8, 8));
      expect(status.phaseLabel, 'Off cycle');
    });

    test('repeating cycle increments cycle number', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 5));

      expect(status.isActive, isTrue);
      expect(status.currentCycleNumber, 2);
      expect(status.dayInCurrentPhase, 1);
    });

    test('non-repeating cycle reports complete after on period', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 3,
        cycleOnUnit: CycleUnit.days,
        repeatCycle: false,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 4));

      expect(status.isActive, isFalse);
      expect(status.isBeforeStart, isFalse);
      expect(status.phaseLabel, 'Cycle complete');
      expect(status.nextTransitionDate, isNull);
    });

    test('zero-day off period remains active', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 5,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 0,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final status = service.statusForDate(protocol, DateTime(2026, 8, 20));

      expect(status.isActive, isTrue);
      expect(status.phaseLabel, 'On cycle');
      expect(status.nextTransitionDate, isNull);
    });
  });
}
