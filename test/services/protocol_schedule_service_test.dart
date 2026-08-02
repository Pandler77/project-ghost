import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/models/protocol_schedule.dart';
import 'package:project_ghost/models/protocol_status.dart';
import 'package:project_ghost/services/protocol_schedule_service.dart';

import '../helpers/protocol_factory.dart';

void main() {
  const service = ProtocolScheduleService();

  group('ProtocolScheduleService', () {
    test('daily protocol schedules every day after start date', () {
      final protocol = buildTestProtocol(
        scheduleStartDate: DateTime(2026, 8, 1),
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 1)), isTrue);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 10)),
        isTrue,
      );
    });

    test('protocol does not schedule before start date', () {
      final protocol = buildTestProtocol(
        scheduleStartDate: DateTime(2026, 8, 10),
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 9)),
        isFalse,
      );
    });

    test('weekly protocol schedules only on configured weekday', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.weekly(
          startDate: DateTime(2026, 8, 1),
          hour: 8,
          minute: 0,
          weekday: DateTime.monday,
        ),
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 3)), isTrue);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 4)),
        isFalse,
      );
    });

    test('every X days schedules on correct interval', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.everyXDays(
          startDate: DateTime(2026, 8, 1),
          hour: 8,
          minute: 0,
          intervalDays: 3,
        ),
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 1)), isTrue);

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 4)), isTrue);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 5)),
        isFalse,
      );
    });

    test('specific weekdays schedule only selected days', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.specificDays(
          startDate: DateTime(2026, 8, 1),
          hour: 8,
          minute: 0,
          weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
        ),
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 3)), isTrue);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 4)),
        isFalse,
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 5)), isTrue);
    });

    test('monthly protocol schedules on configured day', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.monthly(
          startDate: DateTime(2026, 8, 1),
          hour: 8,
          minute: 0,
          day: 15,
        ),
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 15)),
        isTrue,
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 16)),
        isFalse,
      );
    });

    test('monthly day 31 uses final day of shorter month', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.monthly(
          startDate: DateTime(2026, 1, 1),
          hour: 8,
          minute: 0,
          day: 31,
        ),
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 4, 30)),
        isTrue,
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 4, 29)),
        isFalse,
      );
    });

    test('monthly day 31 uses February final day', () {
      final protocol = buildTestProtocol().copyWith(
        schedule: ProtocolSchedule.monthly(
          startDate: DateTime(2026, 1, 1),
          hour: 8,
          minute: 0,
          day: 31,
        ),
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 2, 28)),
        isTrue,
      );
    });

    test('paused protocol never schedules', () {
      final protocol = buildTestProtocol(status: ProtocolStatus.paused);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 1)),
        isFalse,
      );
    });

    test('archived protocol never schedules', () {
      final protocol = buildTestProtocol(status: ProtocolStatus.archived);

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 1)),
        isFalse,
      );
    });

    test('active cycle schedules during on period', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(service.isScheduledOnDate(protocol, DateTime(2026, 8, 2)), isTrue);
    });

    test('off-cycle date does not schedule', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 3)),
        isFalse,
      );
    });

    test('future cycle does not schedule before cycle start', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 10),
        cycleOnDuration: 1,
        cycleOnUnit: CycleUnit.weeks,
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 5)),
        isFalse,
      );
    });

    test('completed non-repeating cycle does not schedule', () {
      final protocol = buildTestProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 3,
        cycleOnUnit: CycleUnit.days,
        repeatCycle: false,
      );

      expect(
        service.isScheduledOnDate(protocol, DateTime(2026, 8, 4)),
        isFalse,
      );
    });

    test('protocolsForDate returns only scheduled protocols in time order', () {
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

      final paused = buildTestProtocol(
        id: 'paused',
        name: 'Paused',
        status: ProtocolStatus.paused,
        hour: 6,
      );

      final protocols = service.protocolsForDate([
        evening,
        paused,
        morning,
      ], DateTime(2026, 8, 1));

      expect(protocols.length, 2);
      expect(protocols[0].id, 'morning');
      expect(protocols[1].id, 'evening');
    });

    test('scheduledDateTime applies protocol time to selected date', () {
      final protocol = buildTestProtocol(hour: 20, minute: 30);

      final scheduled = service.scheduledDateTime(
        protocol,
        DateTime(2026, 8, 15),
      );

      expect(scheduled, DateTime(2026, 8, 15, 20, 30));
    });

    test('nextScheduledDate returns next future dose today', () {
      final protocol = buildTestProtocol(hour: 20);

      final next = service.nextScheduledDate(
        protocol,
        after: DateTime(2026, 8, 1, 10),
      );

      expect(next, DateTime(2026, 8, 1, 20));
    });

    test('nextScheduledDate moves to tomorrow after dose time passes', () {
      final protocol = buildTestProtocol(hour: 8);

      final next = service.nextScheduledDate(
        protocol,
        after: DateTime(2026, 8, 1, 10),
      );

      expect(next, DateTime(2026, 8, 2, 8));
    });

    test('nextScheduledDate skips off-cycle days', () {
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

      final next = service.nextScheduledDate(
        protocol,
        after: DateTime(2026, 8, 2, 10),
      );

      expect(next, DateTime(2026, 8, 5, 8));
    });

    test('nextScheduledDate returns null for paused protocol', () {
      final protocol = buildTestProtocol(status: ProtocolStatus.paused);

      final next = service.nextScheduledDate(
        protocol,
        after: DateTime(2026, 8, 1),
      );

      expect(next, isNull);
    });
  });
}
