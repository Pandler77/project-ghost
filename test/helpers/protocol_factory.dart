import 'package:project_ghost/models/cycle_unit.dart';
import 'package:project_ghost/models/protocol.dart';
import 'package:project_ghost/models/protocol_schedule.dart';
import 'package:project_ghost/models/protocol_status.dart';

Protocol buildTestProtocol({
  String id = 'test-protocol',
  String name = 'Test Protocol',
  String dose = '1 mg',
  ProtocolStatus status = ProtocolStatus.active,
  DateTime? scheduleStartDate,
  int hour = 8,
  int minute = 0,
  bool useCycle = false,
  DateTime? cycleStartDate,
  int cycleOnDuration = 1,
  CycleUnit cycleOnUnit = CycleUnit.weeks,
  int cycleOffDuration = 0,
  CycleUnit cycleOffUnit = CycleUnit.weeks,
  bool repeatCycle = false,
}) {
  final startDate = scheduleStartDate ?? DateTime(2026, 8, 1);

  return Protocol(
    id: id,
    name: name,
    dose: dose,
    status: status,
    schedule: ProtocolSchedule.daily(
      startDate: startDate,
      hour: hour,
      minute: minute,
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
