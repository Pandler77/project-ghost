import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/models/protocol_status.dart';
import 'package:project_ghost/services/dose_service.dart';

import '../helpers/protocol_factory.dart';

void main() {
  final service = DoseService();
  
  group('DoseService', () {
    test('getTodaysDoses returns scheduled active protocols', () {
      final morning = buildTestProtocol(
        id: 'morning',
        name: 'Morning',
        dose: '1 mg',
        hour: 8,
      );

      final evening = buildTestProtocol(
        id: 'evening',
        name: 'Evening',
        dose: '2 mg',
        hour: 20,
      );

      final doses = service.getTodaysDoses([
        evening,
        morning,
      ], now: DateTime(2026, 8, 1, 12));

      expect(doses.length, 2);
      expect(doses[0].protocolId, 'morning');
      expect(doses[1].protocolId, 'evening');
      expect(doses[0].scheduledFor, DateTime(2026, 8, 1, 8));
      expect(doses[1].scheduledFor, DateTime(2026, 8, 1, 20));
    });

    test('getTodaysDoses excludes paused protocols', () {
      final protocol = buildTestProtocol(status: ProtocolStatus.paused);

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 1, 12));

      expect(doses, isEmpty);
    });

    test('getTodaysDoses excludes archived protocols', () {
      final protocol = buildTestProtocol(status: ProtocolStatus.archived);

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 1, 12));

      expect(doses, isEmpty);
    });

    test('getTodaysDoses excludes off-cycle protocols', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 3, 12));

      expect(doses, isEmpty);
    });

    test('getTodaysDoses includes active-cycle protocols', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 2, 12));

      expect(doses.length, 1);
      expect(doses.first.protocolId, protocol.id);
    });

    test('continuous dose does not include cycle labels', () {
      final protocol = buildTestProtocol(useCycle: false);

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 1, 12));

      expect(doses.length, 1);
      expect(doses.first.cyclePrimaryLabel, isNull);
      expect(doses.first.cycleSecondaryLabel, isNull);
      expect(doses.first.hasCycleStatus, isFalse);
    });

    test('cycled dose includes cycle labels', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.weeks,
        cycleOffDuration: 1,
        cycleOffUnit: CycleUnit.weeks,
        repeatCycle: true,
      );

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 3, 12));

      expect(doses.length, 1);
      expect(doses.first.cyclePrimaryLabel, isNotNull);
      expect(doses.first.cycleSecondaryLabel, isNotNull);
      expect(doses.first.hasCycleStatus, isTrue);
    });

    test('dose carries protocol color value', () {
      const colorValue = 0xFF123456;

      final protocol = buildTestProtocol().copyWith(colorValue: colorValue);

      final doses = service.getTodaysDoses([
        protocol,
      ], now: DateTime(2026, 8, 1, 12));

      expect(doses.length, 1);
      expect(doses.first.protocolColorValue, colorValue);
    });

    test('getNextDose returns earliest upcoming dose', () {
      final morning = buildTestProtocol(
        id: 'morning',
        name: 'Morning',
        hour: 8,
      );

      final evening = buildTestProtocol(
        id: 'evening',
        name: 'Evening',
        hour: 20,
      );

      final next = service.getNextDose([
        evening,
        morning,
      ], after: DateTime(2026, 8, 1, 10));

      expect(next, isNotNull);
      expect(next!.protocolId, 'evening');
      expect(next.scheduledFor, DateTime(2026, 8, 1, 20));
    });

    test('getNextDose moves past completed time today', () {
      final protocol = buildTestProtocol(hour: 8);

      final next = service.getNextDose([
        protocol,
      ], after: DateTime(2026, 8, 1, 10));

      expect(next, isNotNull);
      expect(next!.scheduledFor, DateTime(2026, 8, 2, 8));
    });

    test('getNextDose skips off-cycle days', () {
      final protocol = buildTestProtocol(
        hour: 8,
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final next = service.getNextDose([
        protocol,
      ], after: DateTime(2026, 8, 2, 10));

      expect(next, isNotNull);
      expect(next!.scheduledFor, DateTime(2026, 8, 5, 8));
    });

    test('getNextDose returns null when nothing is active', () {
      final paused = buildTestProtocol(status: ProtocolStatus.paused);

      final archived = buildTestProtocol(
        id: 'archived',
        status: ProtocolStatus.archived,
      );

      final next = service.getNextDose([
        paused,
        archived,
      ], after: DateTime(2026, 8, 1));

      expect(next, isNull);
    });

    test('future cycle returns first valid scheduled date', () {
      final protocol = buildTestProtocol(
        hour: 8,
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 10),
        cycleOnDuration: 1,
        cycleOnUnit: CycleUnit.weeks,
      );

      final next = service.getNextDose([protocol], after: DateTime(2026, 8, 1));

      expect(next, isNotNull);
      expect(next!.scheduledFor, DateTime(2026, 8, 10, 8));
    });

    test('completed non-repeating cycle has no next dose', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 3,
        cycleOnUnit: CycleUnit.days,
        repeatCycle: false,
      );

      final next = service.getNextDose([
        protocol,
      ], after: DateTime(2026, 8, 10));

      expect(next, isNull);
    });
  });
}
