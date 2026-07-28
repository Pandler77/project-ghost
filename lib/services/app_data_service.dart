import '../core/repository/ghost_repository.dart';
import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';

class AppDataService {
  AppDataService({GhostRepository? repository})
    : _repository = repository ?? GhostRepository();

  final GhostRepository _repository;

  String get displayName => 'Frank';

  Future<List<Protocol>> getProtocols() {
    return _repository.getProtocols();
  }

  Future<void> addProtocol(Protocol protocol) {
    return _repository.insertProtocol(protocol);
  }

  Future<void> updateProtocol(Protocol protocol) {
    return _repository.updateProtocol(protocol);
  }

  Future<void> deleteProtocol(String protocolId) {
    return _repository.deleteProtocol(protocolId);
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(DateTime date) {
    return _repository.getDoseRecordsForDate(date);
  }

  Future<void> saveDoseRecord(DoseRecord record) {
    return _repository.saveDoseRecord(record);
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

  Future<WeightRecord?> getLatestWeight() {
    return _repository.getLatestWeight();
  }

  Future<void> deleteWeightRecord(String id) {
    return _repository.deleteWeightRecord(id);
  }
}
