import 'package:flutter_test/flutter_test.dart';
import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/models/protocol.dart';
import 'package:project_ghost/models/protocol_schedule.dart';
import 'package:project_ghost/models/protocol_status.dart';
import 'package:project_ghost/services/reminder_schedule_service.dart';

void main() {
  const service = ReminderScheduleService();

  Protocol createProtocol({
    ProtocolSchedule? schedule,
    ProtocolStatus status = ProtocolStatus.active,
    bool reminderEnabled = true,
    int reminderMinutesBefore = 0,
    bool followUpEnabled = false,
    int followUpMinutesAfter = 60,
    bool useCycle = false,
    DateTime? cycleStartDate,
    int cycleOnDuration = 1,
    CycleUnit cycleOnUnit = CycleUnit.weeks,
    int cycleOffDuration = 0,
    CycleUnit cycleOffUnit = CycleUnit.weeks,
    bool repeatCycle = false,
  }) {
    return Protocol(
      id: 'protocol-1',
      name: 'Test Protocol',
      dose: '3 mg',
      schedule:
          schedule ??
          ProtocolSchedule.daily(
            startDate: DateTime(2026, 8, 1),
            hour: 20,
            minute: 0,
          ),
      status: status,
      reminderEnabled: reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore,
      missedDoseReminderEnabled: followUpEnabled,
      missedDoseReminderMinutesAfter: followUpMinutesAfter,
      useCycle: useCycle,
      cycleStartDate: cycleStartDate,
      cycleOnDuration: cycleOnDuration,
      cycleOnUnit: cycleOnUnit,
      cycleOffDuration: cycleOffDuration,
      cycleOffUnit: cycleOffUnit,
      repeatCycle: repeatCycle,
    );
  }

  group('ReminderScheduleService', () {
    test('returns no reminders when reminders are disabled', () {
      final protocol = createProtocol(reminderEnabled: false);

      final reminders = service.upcomingReminders(
        protocol,
        from: DateTime(2026, 8, 2, 12),
      );

      expect(reminders, isEmpty);
    });

    test('returns no reminders for paused protocol', () {
      final protocol = createProtocol(status: ProtocolStatus.paused);

      final reminders = service.upcomingReminders(
        protocol,
        from: DateTime(2026, 8, 2, 12),
      );

      expect(reminders, isEmpty);
    });

    test('returns no reminders for archived protocol', () {
      final protocol = createProtocol(status: ProtocolStatus.archived);

      final reminders = service.upcomingReminders(
        protocol,
        from: DateTime(2026, 8, 2, 12),
      );

      expect(reminders, isEmpty);
    });

    test('creates reminder at scheduled time', () {
      final protocol = createProtocol();

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2, 12),
      );

      expect(reminder, isNotNull);
      expect(reminder!.notificationTime, DateTime(2026, 8, 2, 20));
      expect(reminder.kind, ReminderKind.primary);
    });

    test('creates reminder before scheduled time', () {
      final protocol = createProtocol(reminderMinutesBefore: 15);

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2, 12),
      );

      expect(reminder!.notificationTime, DateTime(2026, 8, 2, 19, 45));
    });

    test('creates primary and follow-up reminders', () {
      final protocol = createProtocol(
        reminderMinutesBefore: 15,
        followUpEnabled: true,
        followUpMinutesAfter: 60,
      );

      final reminders = service.remindersForOccurrence(
        protocol,
        scheduledDoseTime: DateTime(2026, 8, 2, 20),
      );

      expect(reminders, hasLength(2));

      expect(reminders[0].notificationTime, DateTime(2026, 8, 2, 19, 45));

      expect(reminders[1].notificationTime, DateTime(2026, 8, 2, 21));

      expect(reminders[0].kind, ReminderKind.primary);
      expect(reminders[1].kind, ReminderKind.followUp);
    });

    test('returns upcoming follow-up after dose time passed', () {
      final protocol = createProtocol(
        followUpEnabled: true,
        followUpMinutesAfter: 60,
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2, 20, 30),
      );

      expect(reminder, isNotNull);
      expect(reminder!.kind, ReminderKind.followUp);
      expect(reminder.notificationTime, DateTime(2026, 8, 2, 21));
    });

    test('weekly reminder uses configured weekday', () {
      final protocol = createProtocol(
        schedule: ProtocolSchedule.weekly(
          startDate: DateTime(2026, 8, 1),
          hour: 20,
          minute: 0,
          weekday: DateTime.monday,
        ),
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2, 12),
      );

      expect(reminder!.scheduledDoseTime, DateTime(2026, 8, 3, 20));
    });

    test('every X days follows interval', () {
      final protocol = createProtocol(
        schedule: ProtocolSchedule.everyXDays(
          startDate: DateTime(2026, 8, 1),
          hour: 20,
          minute: 0,
          intervalDays: 6,
        ),
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2),
      );

      expect(reminder!.scheduledDoseTime, DateTime(2026, 8, 7, 20));
    });

    test('specific weekdays chooses next matching day', () {
      final protocol = createProtocol(
        schedule: ProtocolSchedule.specificDays(
          startDate: DateTime(2026, 8, 1),
          hour: 8,
          minute: 0,
          weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
        ),
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 4, 12),
      );

      expect(reminder!.scheduledDoseTime, DateTime(2026, 8, 5, 8));
    });

    test('monthly schedule uses last day for short month', () {
      final protocol = createProtocol(
        schedule: ProtocolSchedule.monthly(
          startDate: DateTime(2026, 1, 1),
          hour: 8,
          minute: 0,
          day: 31,
        ),
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 2, 1),
      );

      expect(reminder!.scheduledDoseTime, DateTime(2026, 2, 28, 8));
    });

    test('skips off-cycle dates', () {
      final protocol = createProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        cycleOffDuration: 2,
        cycleOffUnit: CycleUnit.days,
        repeatCycle: true,
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 2, 21),
      );

      expect(reminder!.scheduledDoseTime, DateTime(2026, 8, 5, 20));
    });

    test('completed non-repeating cycle has no reminders', () {
      final protocol = createProtocol(
        useCycle: true,
        cycleStartDate: DateTime(2026, 8, 1),
        cycleOnDuration: 2,
        cycleOnUnit: CycleUnit.days,
        repeatCycle: false,
      );

      final reminder = service.nextReminder(
        protocol,
        after: DateTime(2026, 8, 3),
      );

      expect(reminder, isNull);
    });

    test('combines and sorts reminders across protocols', () {
      final first = createProtocol(
        schedule: ProtocolSchedule.daily(
          startDate: DateTime(2026, 8, 1),
          hour: 20,
          minute: 0,
        ),
      );

      final second = Protocol(
        id: 'protocol-2',
        name: 'Second Protocol',
        dose: '2 mg',
        schedule: ProtocolSchedule.daily(
          startDate: DateTime(2026, 8, 1),
          hour: 18,
          minute: 0,
        ),
        reminderEnabled: true,
      );

      final reminders = service.upcomingRemindersForProtocols(
        [first, second],
        from: DateTime(2026, 8, 2, 12),
        occurrenceLimitPerProtocol: 1,
      );

      expect(reminders, hasLength(2));
      expect(reminders.first.protocolId, 'protocol-2');
      expect(reminders.last.protocolId, 'protocol-1');
    });
  });
}
