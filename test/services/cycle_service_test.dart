import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/models/protocol.dart';
import 'package:project_ghost/models/protocol_schedule.dart';
import 'package:project_ghost/services/cycle_service.dart';

void main() {
  const service = CycleService();

  group('CycleService', () {
    test('continuous protocol is always active', () {
      final protocol = _buildProtocol(useCycle: false);

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 1)), isTrue);

      expect(service.isProtocolActive(protocol, DateTime(2030, 1, 1)), isTrue);
    });

    test('cycled protocol is inactive before its start date', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 10),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.weeks,
        cycleOffDuration: 1,
        cycleOffUnit: CycleUnit.weeks,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 9)), isFalse);
    });

    test('repeating protocol is active during on period', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 1)), isTrue);

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 2)), isTrue);
    });

    test('repeating protocol is inactive during off period', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 3)), isFalse);

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 4)), isFalse);
    });

    test('repeating protocol restarts after off period', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 5)), isTrue);
    });

    test('non-repeating protocol ends after first on period', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 3,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 0,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: false,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 3)), isTrue);

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 4)), isFalse);
    });

    test('zero-day off period stays active when repeating', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 5,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 0,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 20)), isTrue);
    });

    test('weeks are converted to seven-day periods', () {
      final protocol = _buildProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 1,
        cycleOnUnit: CycleUnit.weeks,
        cycleOffDuration: 1,
        cycleOffUnit: CycleUnit.weeks,
        repeatCycle: true,
      );

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 7)), isTrue);

      expect(service.isProtocolActive(protocol, DateTime(2026, 8, 8)), isFalse);
    });
  });
}

Protocol _buildProtocol({
  bool useCycle = false,
  DateTime? cycleStartDate,
  int cycleOnDuration = 1,
  CycleUnit cycleOnUnit = CycleUnit.weeks,
  int cycleOffDuration = 0,
  CycleUnit cycleOffUnit = CycleUnit.weeks,
  bool repeatCycle = false,
}) {
  return Protocol(
    id: 'test-protocol',
    name: 'Test Protocol',
    dose: '1 mg',
    schedule: ProtocolSchedule.daily(
      startDate: DateTime(2026, 8, 1),
      hour: 8,
      minute: 0,
    ),
    useCycle: useCycle,
    cycleStartDate: cycleStartDate,
    cycleOnDuration: cycleOnDuration,
    cycleOnUnit: cycleOnUnit,
    cycleOffDuration: cycleOffDuration,
    cycleOffUnit: cycleOffUnit,
    repeatCycle: repeatCycle,
  );
}
