import '../core/repository/ghost_repository.dart';
import '../core/repository/injection_log_repository.dart';
import '../models/dose_record.dart';
import '../models/dose_details.dart';
import '../models/injection_log.dart';
import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/schedule_override.dart';
import '../models/weight_record.dart';
import 'entitlement_service.dart';
import 'inventory_service.dart';
import 'notification_service.dart';
import '../core/repository/inventory_event_repository.dart';
import '../models/inventory_event.dart';
import '../core/repository/inventory_photo_repository.dart';
import '../models/inventory_photo.dart';
import '../core/repository/inventory_batch_repository.dart';
import '../models/inventory_batch.dart';
import 'protocol_schedule_service.dart';
import 'profile_service.dart';
import 'milestone_service.dart';
import '../models/protocol_type.dart';

class AppDataService {
  AppDataService({
    GhostRepository? repository,
    InjectionLogRepository? injectionLogRepository,
    InventoryEventRepository? inventoryEventRepository,
    InventoryPhotoRepository? inventoryPhotoRepository,
    InventoryBatchRepository? inventoryBatchRepository,
    NotificationService? notificationService,
    EntitlementService? entitlementService,
    InventoryService? inventoryService,
    MilestoneService? milestoneService,
  }) : _repository = repository ?? GhostRepository(),
       _injectionLogRepository =
           injectionLogRepository ?? InjectionLogRepository(),
       _inventoryEventRepository =
           inventoryEventRepository ?? InventoryEventRepository(),
       _inventoryPhotoRepository =
           inventoryPhotoRepository ?? InventoryPhotoRepository(),
       _inventoryBatchRepository =
           inventoryBatchRepository ?? InventoryBatchRepository(),
       _notificationService =
           notificationService ?? NotificationService.instance,
       _entitlementService = entitlementService ?? EntitlementService.instance,
       _inventoryService = inventoryService ?? const InventoryService(),
       _milestoneService = milestoneService ?? MilestoneService();

  final GhostRepository _repository;
  final InjectionLogRepository _injectionLogRepository;
  final NotificationService _notificationService;
  final EntitlementService _entitlementService;
  final InventoryService _inventoryService;
  final MilestoneService _milestoneService;
  final InventoryEventRepository _inventoryEventRepository;
  final InventoryPhotoRepository _inventoryPhotoRepository;
  final InventoryBatchRepository _inventoryBatchRepository;
  final ProtocolScheduleService _protocolScheduleService =
      const ProtocolScheduleService();
  final ProfileService _profileService = ProfileService();

  String get displayName => 'Frank';

  bool get hasPremium => _entitlementService.hasPremium;

  Future<bool> hasDoseSafetyAcknowledgement({
    required String acknowledgementType,
    required int version,
  }) {
    return _repository.hasDoseSafetyAcknowledgement(
      acknowledgementType: acknowledgementType,
      version: version,
    );
  }

  Future<void> saveDoseSafetyAcknowledgement({
    required String acknowledgementType,
    required int version,
    required DateTime acceptedAt,
  }) {
    return _repository.saveDoseSafetyAcknowledgement(
      acknowledgementType: acknowledgementType,
      version: version,
      acceptedAt: acceptedAt,
    );
  }

  Future<DateTime?> getDoseSafetyAcknowledgementAcceptedAt({
    required String acknowledgementType,
    required int version,
  }) {
    return _repository.getDoseSafetyAcknowledgementAcceptedAt(
      acknowledgementType: acknowledgementType,
      version: version,
    );
  }

  Future<List<ScheduleOverride>> getScheduleOverrides() {
    return _repository.getScheduleOverrides();
  }

  Future<List<ScheduleOverride>> getScheduleOverridesForProtocol(
    String protocolId,
  ) {
    return _repository.getScheduleOverridesForProtocol(protocolId);
  }

  Future<void> saveScheduleOverride(ScheduleOverride override) async {
    final original = override.originalScheduledFor;

    if (original != null) {
      await _repository.deleteScheduleOverrideForOccurrence(
        protocolId: override.protocolId,
        originalScheduledFor: original,
      );
    }

    await _repository.saveScheduleOverride(override);
    await _rescheduleProtocolAfterOverride(override.protocolId);
  }

  Future<void> deleteScheduleOverride(String id, String protocolId) async {
    await _repository.deleteScheduleOverride(id);
    await _rescheduleProtocolAfterOverride(protocolId);
  }

  Future<void> _rescheduleProtocolAfterOverride(String protocolId) async {
    final protocols = await _repository.getProtocols();

    Protocol? protocol;

    for (final candidate in protocols) {
      if (candidate.id == protocolId) {
        protocol = candidate;
        break;
      }
    }

    if (protocol == null) {
      return;
    }

    final profile = await _profileService.getActiveProfile();
    final overrides = await _repository.getScheduleOverridesForProtocol(
      protocolId,
    );

    await _notificationService.scheduleProtocolReminders(
      protocol,
      profileId: profile.id,
      profileName: profile.name,
      overrides: overrides,
    );
  }

  Future<List<Protocol>> getProtocols() {
    return _repository.getProtocols();
  }

  Future<List<Protocol>> getProtocolsForProfile(String profileId) {
    return _repository.getProtocolsForProfile(profileId);
  }

  Future<void> addProtocol(Protocol protocol) async {
    await _repository.insertProtocol(protocol);

    final profile = await _profileService.getActiveProfile();

    await _notificationService.scheduleProtocolReminders(
      protocol,
      profileId: profile.id,
      profileName: profile.name,
    );
  }

  Future<void> updateProtocol(Protocol protocol) async {
    await _repository.updateProtocol(protocol);

    await _removeStaleMissedDoseRecords(protocol);

    final profile = await _profileService.getActiveProfile();
    final overrides = await _repository.getScheduleOverridesForProtocol(
      protocol.id,
    );

    await _notificationService.scheduleProtocolReminders(
      protocol,
      profileId: profile.id,
      profileName: profile.name,
      overrides: overrides,
    );
  }

  Future<void> _removeStaleMissedDoseRecords(Protocol protocol) async {
    final records = await _repository.getDoseRecordsForProtocol(protocol.id);
    final overrides = await _repository.getScheduleOverridesForProtocol(
      protocol.id,
    );

    for (final record in records) {
      if (record.status != DoseRecordStatus.missed) {
        continue;
      }

      final scheduledDate = DateTime(
        record.scheduledFor.year,
        record.scheduledFor.month,
        record.scheduledFor.day,
      );

      final scheduledOccurrences = _protocolScheduleService.occurrencesForDate(
        [protocol],
        scheduledDate,
        overrides: overrides,
      );

      final matchingOccurrence = scheduledOccurrences.any(
        (occurrence) => _sameScheduledTime(
          occurrence.scheduledFor,
          record.scheduledFor,
        ),
      );

      if (!matchingOccurrence) {
        await _repository.deleteDoseRecord(
          protocolId: record.protocolId,
          scheduledFor: record.scheduledFor,
        );

        continue;
      }

    }
  }

  bool _sameScheduledTime(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }

  Future<void> deleteProtocol(String protocolId) async {
    final profile = await _profileService.getActiveProfile();

    await _notificationService.cancelProtocolReminders(
      protocolId,
      profileId: profile.id,
    );

    // Supply belongs to the active protocol configuration, not its historical
    // dose records. Remove linked supply before hiding the protocol.
    await _repository.deleteInventoryForProtocol(protocolId);

    // Repository uses a soft delete so logged dose/injection history remains.
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

  Future<void> saveDoseRecord(
    DoseRecord record, {
    String? preferredInventoryBatchId,
    bool adjustInventory = true,
  }) async {
    final beforeDoseRecords = await _repository.getAllDoseRecords();

    final persistedRecord = await _withProtocolSnapshot(record);

    final existingRecord = await _findDoseRecord(
      protocolId: persistedRecord.protocolId,
      scheduledFor: persistedRecord.scheduledFor,
    );

    final previousAmount = await _inventoryAmountForRecord(existingRecord);
    final newAmount = await _inventoryAmountForRecord(persistedRecord);
    final difference = newAmount - previousAmount;

    if (adjustInventory && hasPremium && difference > 0) {
      final inventoryUpdated = await _deductInventory(
        protocolId: persistedRecord.protocolId,
        amount: difference,
        preferredBatchId: preferredInventoryBatchId,
      );

      if (!inventoryUpdated) {
        throw StateError(
          'MODOSE Supply could not complete the inventory deduction.',
        );
      }
    } else if (adjustInventory && hasPremium && difference < 0) {
      await _restoreInventory(
        protocolId: persistedRecord.protocolId,
        amount: difference.abs(),
      );
    }

    await _repository.saveDoseRecord(persistedRecord);

    if (persistedRecord.completedAt != null) {
      final profile = await _profileService.getActiveProfile();

      await _notificationService.cancelFollowUpReminder(
        profileId: profile.id,
        protocolId: persistedRecord.protocolId,
        scheduledDoseTime: persistedRecord.scheduledFor,
      );
    }

    final profile = await _profileService.getActiveProfile();
    final afterDoseRecords = await _repository.getAllDoseRecords();

    await _milestoneService.evaluateDoseSave(
      profile: profile,
      beforeRecords: beforeDoseRecords,
      afterRecords: afterDoseRecords,
    );
  }

  Future<DoseRecord> _withProtocolSnapshot(DoseRecord record) async {
    final alreadyComplete =
        record.protocolNameSnapshot != null &&
        record.protocolTypeSnapshot != null &&
        record.protocolColorValueSnapshot != null;

    if (alreadyComplete) {
      return record;
    }

    final protocols = await _repository.getProtocols();

    Protocol? protocol;

    for (final candidate in protocols) {
      if (candidate.id == record.protocolId) {
        protocol = candidate;
        break;
      }
    }

    if (protocol == null) {
      return record;
    }

    return record.copyWithSnapshot(
      protocolNameSnapshot: protocol.name,
      protocolTypeSnapshot: protocol.type.storageValue,
      protocolColorValueSnapshot: protocol.colorValue,
      advancedDoseJsonSnapshot: protocol.doseDetails?.toJson(),
    );
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
      final amountToRestore = await _inventoryAmountForRecord(existingRecord);

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

  Future<double> _inventoryAmountForRecord(DoseRecord? record) async {
    if (record == null ||
        record.status != DoseRecordStatus.taken ||
        record.completedAt == null) {
      return 0;
    }

    final actualActiveAmount =
        _parseDoseAmount(record.actualAmount ?? record.scheduledAmount);

    if (actualActiveAmount == null || actualActiveAmount <= 0) {
      return 0;
    }

    final inventory = await _repository.getInventoryItemForProtocol(
      record.protocolId,
    );

    if (inventory == null) {
      return actualActiveAmount;
    }

    if (!_isPhysicalInventoryUnit(inventory.unit)) {
      return actualActiveAmount;
    }

    // If the recorded dose itself is already count-based, use it directly.
    if (_doseTextUsesPhysicalUnit(
      record.actualAmount ?? record.scheduledAmount,
    )) {
      return actualActiveAmount;
    }

    DoseDetails? details = DoseDetails.fromJson(
      record.advancedDoseJsonSnapshot,
    );

    if (details == null) {
      final protocols = await _repository.getProtocols();

      for (final protocol in protocols) {
        if (protocol.id == record.protocolId) {
          details = protocol.doseDetails;
          break;
        }
      }
    }

    final scheduledQuantity = details?.scheduledQuantity;

    if (scheduledQuantity == null || scheduledQuantity <= 0) {
      // Avoid interpreting an active-ingredient dose such as 1000 mg
      // as 1000 tablets/capsules when count metadata is unavailable.
      return 0;
    }

    final scheduledActiveAmount = _parseDoseAmount(record.scheduledAmount);

    if (scheduledActiveAmount == null || scheduledActiveAmount <= 0) {
      return scheduledQuantity;
    }

    final ratio = actualActiveAmount / scheduledActiveAmount;

    return _normalizeAmount(scheduledQuantity * ratio);
  }

  bool _isPhysicalInventoryUnit(String unit) {
    final normalized = unit.trim().toLowerCase();

    return const {
      'tablet',
      'tablets',
      'capsule',
      'capsules',
      'pill',
      'pills',
      'softgel',
      'softgels',
      'patch',
      'patches',
      'drop',
      'drops',
      'serving',
      'servings',
    }.contains(normalized);
  }

  bool _doseTextUsesPhysicalUnit(String value) {
    final normalized = value.trim().toLowerCase();

    return RegExp(
      r'\b(tablets?|capsules?|pills?|softgels?|patches?|drops?|servings?)\b',
    ).hasMatch(normalized);
  }

  double? _parseDoseAmount(String value) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value);

    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(1)!);
  }

  Future<bool> _deductInventory({
    required String protocolId,
    required double amount,
    String? preferredBatchId,
  }) async {
    if (amount <= 0) {
      return true;
    }

    final inventory = await _repository.getInventoryItemForProtocol(protocolId);

    if (inventory == null) {
      return true;
    }

    final batches = await _inventoryBatchRepository.getByInventoryItem(
      inventory.id,
    );

    final result = _inventoryService.deductDose(
      item: inventory,
      batches: batches,
      doseAmount: amount,
      preferredBatchId: preferredBatchId,
      completedAt: DateTime.now(),
    );

    if (!result.hadEnoughStock) {
      return false;
    }

    await _repository.updateInventoryItem(result.item);

    for (final batch in result.batches) {
      await _inventoryBatchRepository.update(batch);
    }

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: result.item.id,
        protocolId: protocolId,
        type: InventoryEventType.doseDeducted,
        amountChanged: -amount,
        amountAfter: result.item.currentAmount,
        unopenedQuantityAfter: await getUnopenedContainerCount(result.item.id),
        occurredAt: DateTime.now(),
      ),
    );

    return true;
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

    final restoredItem = inventory.copyWith(
      currentAmount: _normalizeAmount(currentAmount),
      unopenedQuantity: unopenedQuantity,
      updatedAt: DateTime.now(),
    );

    await _repository.updateInventoryItem(restoredItem);

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: restoredItem.id,
        protocolId: protocolId,
        type: InventoryEventType.doseRestored,
        amountChanged: amount,
        amountAfter: restoredItem.currentAmount,
        unopenedQuantityAfter: restoredItem.unopenedQuantity,
        occurredAt: DateTime.now(),
      ),
    );
  }

  double _normalizeAmount(double value) {
    if (value.abs() < 0.000001) {
      return 0;
    }

    return double.parse(value.toStringAsFixed(6));
  }

  Future<void> saveInjectionLog(InjectionLog log) {
    return _injectionLogRepository.insert(log);
  }

  Future<void> updateInjectionLog(InjectionLog log) {
    return _injectionLogRepository.update(log);
  }

  Future<void> deleteInjectionLog(String logId) {
    return _injectionLogRepository.delete(logId);
  }

  Future<InjectionLog?> getInjectionLogById(String logId) {
    return _injectionLogRepository.getById(logId);
  }

  Future<List<InjectionLog>> getInjectionLogsForProtocol(
    String protocolId, {
    int? limit,
  }) {
    return _injectionLogRepository.getByProtocol(protocolId, limit: limit);
  }

  Future<InjectionLog?> getMostRecentInjectionLog(String protocolId) {
    return _injectionLogRepository.getMostRecentForProtocol(protocolId);
  }

  Future<List<InjectionLog>> getAllInjectionLogs() {
    return _injectionLogRepository.getAll();
  }

  Future<InjectionLog?> getInjectionLogForDoseRecord(String doseRecordId) {
    return _injectionLogRepository.getByDoseRecordId(doseRecordId);
  }

  Future<void> deleteInjectionLogForDoseRecord(String doseRecordId) {
    return _injectionLogRepository.deleteByDoseRecordId(doseRecordId);
  }

  Future<void> deleteInjectionLogsForProtocol(String protocolId) {
    return _injectionLogRepository.deleteByProtocol(protocolId);
  }

  Future<void> saveWeightRecord(WeightRecord record) async {
    final profile = await _profileService.getActiveProfile();
    final beforeRecords = await _repository.getWeightRecords();

    await _repository.saveWeightRecord(record);

    final afterRecords = await _repository.getWeightRecords();

    await _milestoneService.evaluateWeightSave(
      profile: profile,
      beforeRecords: beforeRecords,
      afterRecords: afterRecords,
    );
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

  Future<void> saveInventoryItem(
    InventoryItem item, {
    String? initialBatchName,
    double? initialBatchContainerSize,
    String? initialBatchUnit,
  }) async {
    final existing = await _repository.getInventoryItemForProtocol(
      item.protocolId,
    );

    final initialUnopenedQuantity = item.unopenedQuantity;
    final unopenedContainerSize = initialBatchContainerSize ?? item.vialSize;

    final unopenedUnit = initialBatchUnit ?? item.unit;
    final unopenedAmount = unopenedContainerSize * initialUnopenedQuantity;
    final totalInitialAmount = item.currentAmount + unopenedAmount;

    // One protocol owns one InventoryItem. Batches hold unopened stock.
    final storedItem = item.copyWith(
      id: existing?.id ?? item.id,
      unopenedQuantity: 0,
      supplyCapacity: existing == null
          ? totalInitialAmount
          : existing.supplyCapacity + totalInitialAmount,
      createdAt: existing?.createdAt ?? item.createdAt,
      updatedAt: DateTime.now(),
    );

    if (existing == null) {
      await _repository.insertInventoryItem(storedItem);
    } else {
      await _repository.updateInventoryItem(storedItem);
    }

    if (initialUnopenedQuantity > 0) {
      final initialBatch = InventoryBatch(
        inventoryItemId: storedItem.id,
        name: initialBatchName?.trim().isNotEmpty == true
            ? initialBatchName!.trim()
            : '${_normalizeAmount(unopenedContainerSize)} $unopenedUnit Batch',
        containerSize: unopenedContainerSize,
        unit: unopenedUnit,
        quantity: initialUnopenedQuantity,
        vendor: item.vendor,
        batch: item.batch,
        purchaseDate: item.purchaseDate,
        expirationDate: item.expirationDate,
        cost: item.cost,
        notes: item.notes,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );

      await _inventoryBatchRepository.insert(initialBatch);
    }

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: storedItem.id,
        protocolId: storedItem.protocolId,
        type: existing == null
            ? InventoryEventType.created
            : InventoryEventType.stockAdded,
        amountChanged: totalInitialAmount,
        amountAfter: storedItem.currentAmount,
        unopenedQuantityAfter: await getUnopenedContainerCount(storedItem.id),
        notes: existing == null
            ? 'Initial inventory added.'
            : 'Inventory added to existing supply.',
        occurredAt: DateTime.now(),
      ),
    );
  }

  Future<void> addInventoryStock({
    required InventoryItem item,
    required String batchName,
    required double containerSize,
    required int quantity,
    String? vendor,
    String? batchNumber,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    double? cost,
    String? notes,
  }) async {
    if (containerSize <= 0 || quantity <= 0) {
      return;
    }

    final batch = InventoryBatch(
      inventoryItemId: item.id,
      name: batchName.trim(),
      containerSize: containerSize,
      unit: item.unit,
      quantity: quantity,
      vendor: vendor,
      batch: batchNumber,
      purchaseDate: purchaseDate,
      expirationDate: expirationDate,
      cost: cost,
      notes: notes,
    );

    await _inventoryBatchRepository.insert(batch);

    final addedAmount = containerSize * quantity;

    final updatedItem = item.copyWith(
      supplyCapacity: item.supplyCapacity + addedAmount,
      updatedAt: DateTime.now(),
    );

    await _repository.updateInventoryItem(updatedItem);

    final unopenedCount = await getUnopenedContainerCount(item.id);

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: item.id,
        protocolId: item.protocolId,
        type: InventoryEventType.stockAdded,
        amountChanged: addedAmount,
        amountAfter: item.currentAmount,
        unopenedQuantityAfter: unopenedCount,
        notes:
            'Added $batchName • '
            '$quantity × ${_normalizeAmount(containerSize)} ${item.unit}',
        occurredAt: DateTime.now(),
      ),
    );
  }

  Future<InventoryBatch> addInventoryBatchAndOpen({
    required InventoryItem item,
    required String batchName,
    required double containerSize,
    required int quantity,
    String? vendor,
    String? batchNumber,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    double? cost,
    String? notes,
  }) async {
    final trimmedName = batchName.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Batch name is required.');
    }

    if (containerSize <= 0) {
      throw ArgumentError('Container size must be greater than zero.');
    }

    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (item.currentAmount > 0) {
      throw StateError(
        'The current ${item.containerType.toLowerCase()} '
        'must be empty before opening a new one.',
      );
    }

    final now = DateTime.now();

    // One container is opened immediately.
    final unopenedQuantity = quantity - 1;

    final batch = InventoryBatch(
      inventoryItemId: item.id,
      name: trimmedName,
      containerSize: containerSize,
      unit: item.unit,
      quantity: unopenedQuantity,
      vendor: vendor,
      batch: batchNumber,
      purchaseDate: purchaseDate,
      expirationDate: expirationDate,
      cost: cost,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await _inventoryBatchRepository.insert(batch);

    final addedAmount = containerSize * quantity;

    final updatedItem = item.copyWith(
      vialSize: containerSize,
      currentAmount: containerSize,
      unit: item.unit,
      currentContainerOpenedAt: now,
      currentContainerBatchId: batch.id,
      supplyCapacity: item.supplyCapacity + addedAmount,
      updatedAt: now,
    );

    await _repository.updateInventoryItem(updatedItem);

    final unopenedCount = await getUnopenedContainerCount(item.id);

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: item.id,
        protocolId: item.protocolId,
        type: InventoryEventType.stockAdded,
        amountChanged: addedAmount,
        amountAfter: updatedItem.currentAmount,
        unopenedQuantityAfter: unopenedCount,
        notes:
            'Added $trimmedName • '
            '$quantity × ${_normalizeAmount(containerSize)} ${item.unit}',
        occurredAt: now,
      ),
    );

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: item.id,
        protocolId: item.protocolId,
        type: InventoryEventType.vialOpened,
        amountChanged: 0,
        amountAfter: updatedItem.currentAmount,
        unopenedQuantityAfter: unopenedCount,
        notes:
            'Opened 1 ${item.containerType.toLowerCase()} '
            'from $trimmedName.',
        occurredAt: now,
      ),
    );

    return batch;
  }

  Future<InventoryItem?> openNewInventoryVial({
    required InventoryItem item,
    String? batchId,
    String? notes,
  }) async {
    if (item.currentAmount > 0) {
      return null;
    }

    final batches = await _inventoryBatchRepository.getByInventoryItem(item.id);

    final availableBatches = batches
        .where((batch) => batch.quantity > 0)
        .toList(growable: false);

    if (availableBatches.isEmpty) {
      return null;
    }

    InventoryBatch? selectedBatch;

    if (batchId != null) {
      for (final batch in availableBatches) {
        if (batch.id == batchId) {
          selectedBatch = batch;
          break;
        }
      }

      if (selectedBatch == null) {
        throw ArgumentError(
          'The selected inventory batch is no longer available.',
        );
      }
    } else {
      // Safe fallback for callers that do not yet provide a batch.
      // When multiple batches exist, the oldest available batch is used.
      final sorted = [...availableBatches]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      selectedBatch = sorted.first;
    }

    final now = DateTime.now();

    final updatedBatch = selectedBatch.copyWith(
      quantity: selectedBatch.quantity - 1,
      updatedAt: now,
    );

    await _inventoryBatchRepository.update(updatedBatch);

    final updatedItem = item.copyWith(
      vialSize: selectedBatch.containerSize,
      currentAmount: selectedBatch.containerSize,
      unit: selectedBatch.unit,
      currentContainerOpenedAt: now,
      currentContainerBatchId: selectedBatch.id,
      updatedAt: now,
    );

    await _repository.updateInventoryItem(updatedItem);

    final unopenedCount = await getUnopenedContainerCount(item.id);

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: updatedItem.id,
        protocolId: updatedItem.protocolId,
        type: InventoryEventType.vialOpened,
        amountChanged: 0,
        amountAfter: updatedItem.currentAmount,
        unopenedQuantityAfter: unopenedCount,
        notes:
            notes ??
            'Opened ${_normalizeAmount(selectedBatch.containerSize)} '
                '${selectedBatch.unit} '
                '${item.containerType.toLowerCase()}'
                '${selectedBatch.vendor == null ? '' : ' from ${selectedBatch.vendor}'}.',
        occurredAt: now,
      ),
    );

    return updatedItem;
  }

  Future<InventoryItem> manuallyAdjustInventory({
    required InventoryItem item,
    required double currentAmount,
    required int unopenedQuantity,
    String? notes,
  }) async {
    if (currentAmount < 0 || currentAmount > item.vialSize) {
      throw ArgumentError(
        'Current amount must be between 0 and the container size.',
      );
    }

    final unopenedAmount = await getUnopenedInventoryAmount(item.id);
    final unopenedCount = await getUnopenedContainerCount(item.id);
    final existing = await _repository.getInventoryItemForProtocol(
      item.protocolId,
    );

    final previousCurrentAmount = existing?.currentAmount ?? item.currentAmount;
    final previousTotal = previousCurrentAmount + unopenedAmount;

    final updatedItem = item.copyWith(
      currentAmount: _normalizeAmount(currentAmount),

      // InventoryBatch rows are the source of truth for unopened supply.
      unopenedQuantity: 0,
      updatedAt: DateTime.now(),
    );

    final updatedTotal = updatedItem.currentAmount + unopenedAmount;
    final totalDifference = updatedTotal - previousTotal;

    await _repository.updateInventoryItem(updatedItem);

    await _inventoryEventRepository.insert(
      InventoryEvent(
        inventoryItemId: updatedItem.id,
        protocolId: updatedItem.protocolId,
        type: InventoryEventType.manualAdjustment,
        amountChanged: _normalizeAmount(totalDifference),
        amountAfter: updatedItem.currentAmount,
        unopenedQuantityAfter: unopenedCount,
        notes: notes,
        occurredAt: DateTime.now(),
      ),
    );

    return updatedItem;
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

  Future<void> saveInventoryEvent(InventoryEvent event) {
    return _inventoryEventRepository.insert(event);
  }

  Future<void> updateInventoryEvent(InventoryEvent event) {
    return _inventoryEventRepository.update(event);
  }

  Future<void> deleteInventoryEvent(String eventId) {
    return _inventoryEventRepository.delete(eventId);
  }

  Future<InventoryEvent?> getInventoryEventById(String eventId) {
    return _inventoryEventRepository.getById(eventId);
  }

  Future<List<InventoryEvent>> getInventoryEventsForItem(
    String inventoryItemId, {
    int? limit,
  }) {
    return _inventoryEventRepository.getByInventoryItem(
      inventoryItemId,
      limit: limit,
    );
  }

  Future<List<InventoryEvent>> getInventoryEventsForProtocol(
    String protocolId, {
    int? limit,
  }) {
    return _inventoryEventRepository.getByProtocol(protocolId, limit: limit);
  }

  Future<List<InventoryEvent>> getAllInventoryEvents({int? limit}) {
    return _inventoryEventRepository.getAll(limit: limit);
  }

  Future<void> deleteInventoryEventsForItem(String inventoryItemId) {
    return _inventoryEventRepository.deleteByInventoryItem(inventoryItemId);
  }

  Future<void> deleteInventoryEventsForProtocol(String protocolId) {
    return _inventoryEventRepository.deleteByProtocol(protocolId);
  }

  Future<void> saveInventoryPhoto(InventoryPhoto photo) {
    return _inventoryPhotoRepository.insert(photo);
  }

  Future<void> updateInventoryPhoto(InventoryPhoto photo) {
    return _inventoryPhotoRepository.update(photo);
  }

  Future<void> deleteInventoryPhoto(String photoId) {
    return _inventoryPhotoRepository.delete(photoId);
  }

  Future<InventoryPhoto?> getInventoryPhotoById(String photoId) {
    return _inventoryPhotoRepository.getById(photoId);
  }

  Future<List<InventoryPhoto>> getInventoryPhotosForItem(
    String inventoryItemId,
  ) {
    return _inventoryPhotoRepository.getByInventoryItem(inventoryItemId);
  }

  Future<void> deleteInventoryPhotosForItem(String inventoryItemId) {
    return _inventoryPhotoRepository.deleteByInventoryItem(inventoryItemId);
  }

  Future<void> saveInventoryBatch(InventoryBatch batch) {
    return _inventoryBatchRepository.insert(batch);
  }

  Future<void> updateInventoryBatch(InventoryBatch batch) {
    return _inventoryBatchRepository.update(batch);
  }

  Future<void> deleteInventoryBatch(String batchId) {
    return _inventoryBatchRepository.delete(batchId);
  }

  Future<InventoryBatch?> getInventoryBatchById(String batchId) {
    return _inventoryBatchRepository.getById(batchId);
  }

  Future<List<InventoryBatch>> getInventoryBatchesForItem(
    String inventoryItemId,
  ) {
    return _inventoryBatchRepository.getByInventoryItem(inventoryItemId);
  }

  Future<List<InventoryBatch>> getAllInventoryBatches() {
    return _inventoryBatchRepository.getAll();
  }

  Future<void> deleteInventoryBatchesForItem(String inventoryItemId) {
    return _inventoryBatchRepository.deleteByInventoryItem(inventoryItemId);
  }

  Future<int> getUnopenedContainerCount(String inventoryItemId) async {
    final batches = await _inventoryBatchRepository.getByInventoryItem(
      inventoryItemId,
    );

    return batches.fold<int>(0, (total, batch) => total + batch.quantity);
  }

  Future<double> getUnopenedInventoryAmount(String inventoryItemId) async {
    final batches = await _inventoryBatchRepository.getByInventoryItem(
      inventoryItemId,
    );

    return batches.fold<double>(0, (total, batch) => total + batch.totalAmount);
  }

  Future<double> getTotalInventoryAmount(InventoryItem item) async {
    final unopenedAmount = await getUnopenedInventoryAmount(item.id);

    return item.currentAmount + unopenedAmount;
  }

  Future<bool> hasUnopenedInventory(String inventoryItemId) async {
    return (await getUnopenedContainerCount(inventoryItemId)) > 0;
  }
}

