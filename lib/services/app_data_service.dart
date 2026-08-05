import '../core/repository/ghost_repository.dart';
import '../models/dose_record.dart';
import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import 'entitlement_service.dart';
import 'inventory_service.dart';
import 'notification_service.dart';

class AppDataService {
  AppDataService({
    GhostRepository? repository,
    NotificationService? notificationService,
    EntitlementService? entitlementService,
    InventoryService? inventoryService,
  }) : _repository = repository ?? GhostRepository(),
       _notificationService =
           notificationService ?? NotificationService.instance,
       _entitlementService = entitlementService ?? EntitlementService.instance,
       _inventoryService = inventoryService ?? const InventoryService();

  final GhostRepository _repository;
  final NotificationService _notificationService;
  final EntitlementService _entitlementService;
  final InventoryService _inventoryService;

  String get displayName => 'Frank';

  bool get hasPremium => _entitlementService.hasPremium;

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
    final existingRecord = await _findDoseRecord(
      protocolId: record.protocolId,
      scheduledFor: record.scheduledFor,
    );

    await _repository.saveDoseRecord(record);

    if (record.completedAt != null) {
      await _notificationService.cancelFollowUpReminder(
        protocolId: record.protocolId,
        scheduledDoseTime: record.scheduledFor,
      );
    }

    if (!hasPremium) {
      return;
    }

    final previousAmount = _inventoryAmountForRecord(existingRecord);
    final newAmount = _inventoryAmountForRecord(record);
    final difference = newAmount - previousAmount;

    if (difference > 0) {
      await _deductInventory(protocolId: record.protocolId, amount: difference);
    } else if (difference < 0) {
      await _restoreInventory(
        protocolId: record.protocolId,
        amount: difference.abs(),
      );
    }
  }

  Future<void> deleteDoseRecord({
    required String protocolId,
    required DateTime scheduledFor,
  }) async {
    final existingRecord = await _findDoseRecord(
      protocolId: protocolId,
      scheduledFor: scheduledFor,
    );

    if (hasPremium) {
      final amountToRestore = _inventoryAmountForRecord(existingRecord);

      if (amountToRestore > 0) {
        await _restoreInventory(
          protocolId: protocolId,
          amount: amountToRestore,
        );
      }
    }

    await _repository.deleteDoseRecord(
      protocolId: protocolId,
      scheduledFor: scheduledFor,
    );
  }

  Future<DoseRecord?> _findDoseRecord({
    required String protocolId,
    required DateTime scheduledFor,
  }) async {
    final records = await _repository.getDoseRecordsForProtocol(protocolId);

    for (final record in records) {
      if (record.scheduledFor.toIso8601String() ==
          scheduledFor.toIso8601String()) {
        return record;
      }
    }

    return null;
  }

  double _inventoryAmountForRecord(DoseRecord? record) {
    if (record == null ||
        record.status != DoseRecordStatus.taken ||
        record.completedAt == null) {
      return 0;
    }

    return _parseDoseAmount(record.actualAmount ?? record.scheduledAmount) ?? 0;
  }

  double? _parseDoseAmount(String value) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value);

    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(1)!);
  }

  Future<void> _deductInventory({
    required String protocolId,
    required double amount,
  }) async {
    if (amount <= 0) {
      return;
    }

    final inventory = await _repository.getInventoryItemForProtocol(protocolId);

    if (inventory == null) {
      return;
    }

    final result = _inventoryService.deductDose(
      item: inventory,
      doseAmount: amount,
      completedAt: DateTime.now(),
    );

    if (!result.hadEnoughStock) {
      return;
    }

    await _repository.updateInventoryItem(result.item);
  }

  Future<void> _restoreInventory({
    required String protocolId,
    required double amount,
  }) async {
    if (amount <= 0) {
      return;
    }

    final inventory = await _repository.getInventoryItemForProtocol(protocolId);

    if (inventory == null || inventory.vialSize <= 0) {
      return;
    }

    var currentAmount = inventory.currentAmount + amount;
    var unopenedQuantity = inventory.unopenedQuantity;

    while (currentAmount > inventory.vialSize) {
      currentAmount -= inventory.vialSize;
      unopenedQuantity++;
    }

    await _repository.updateInventoryItem(
      inventory.copyWith(
        currentAmount: _normalizeAmount(currentAmount),
        unopenedQuantity: unopenedQuantity,
        updatedAt: DateTime.now(),
      ),
    );
  }

  double _normalizeAmount(double value) {
    if (value.abs() < 0.000001) {
      return 0;
    }

    return double.parse(value.toStringAsFixed(6));
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

  Future<List<InventoryItem>> getInventoryItems() {
    return _repository.getInventoryItems();
  }

  Future<InventoryItem?> getInventoryItemForProtocol(String protocolId) {
    return _repository.getInventoryItemForProtocol(protocolId);
  }

  Future<void> saveInventoryItem(InventoryItem item) {
    return _repository.insertInventoryItem(item);
  }

  Future<void> updateInventoryItem(InventoryItem item) {
    return _repository.updateInventoryItem(item);
  }

  Future<void> deleteInventoryItem(String id) {
    return _repository.deleteInventoryItem(id);
  }

  Future<void> deleteInventoryForProtocol(String protocolId) {
    return _repository.deleteInventoryForProtocol(protocolId);
  }
}
