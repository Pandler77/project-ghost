import '../core/repository/ghost_repository.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import 'notification_service.dart';

class AppDataService {
  AppDataService({
    GhostRepository? repository,
    NotificationService? notificationService,
  }) : _repository = repository ?? GhostRepository(),
       _notificationService =
           notificationService ?? NotificationService.instance;

  final GhostRepository _repository;
  final NotificationService _notificationService;

  String get displayName => 'Frank';

  Future<List<Protocol>> getProtocols() {
    return _repository.getProtocols();
  }

  Future<void> addProtocol(Protocol protocol) async {
    await _repository.insertProtocol(protocol);

    await _notificationService.scheduleProtocolReminders(protocol);
  }

  Future<void> updateProtocol(Protocol protocol) async {
    await _repository.updateProtocol(protocol);

    await _notificationService.scheduleProtocolReminders(protocol);
  }

  Future<void> deleteProtocol(String protocolId) async {
    await _notificationService.cancelProtocolReminders(protocolId);

    await _repository.deleteProtocol(protocolId);
  }

  Future<List<DoseRecord>> getAllDoseRecords() {
    return _repository.getAllDoseRecords();
  }

  Future<List<DoseRecord>> getDoseRecordsBetween(DateTime start, DateTime end) {
    return _repository.getDoseRecordsBetween(start, end);
  }

  Future<List<DoseRecord>> getDoseRecordsForProtocol(String protocolId) {
    return _repository.getDoseRecordsForProtocol(protocolId);
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(DateTime date) {
    return _repository.getDoseRecordsForDate(date);
  }

  Future<void> saveDoseRecord(DoseRecord record) async {
    await _repository.saveDoseRecord(record);

    if (record.completedAt != null) {
      await _notificationService.cancelFollowUpReminder(
        protocolId: record.protocolId,
        scheduledDoseTime: record.scheduledFor,
      );
    }
  }

  Future<void> deleteDoseRecord({
    required String protocolId,
    required DateTime scheduledFor,
  }) {
    return _repository.deleteDoseRecord(
      protocolId: protocolId,
      scheduledFor: scheduledFor,
    );
  }

  Future<void> saveWeightRecord(WeightRecord record) {
    return _repository.saveWeightRecord(record);
  }

  Future<List<WeightRecord>> getWeightRecords() {
    return _repository.getWeightRecords();
  }

  Future<WeightRecord?> getWeightRecordForDate(DateTime date) {
    return _repository.getWeightRecordForDate(date);
  }

  Future<WeightRecord?> getLatestWeight() {
    return _repository.getLatestWeight();
  }

  Future<void> deleteWeightRecord(String id) {
    return _repository.deleteWeightRecord(id);
  }
}
