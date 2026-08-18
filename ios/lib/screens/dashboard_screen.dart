import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/display_preferences.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';
import '../models/injection_log.dart';
import '../models/injection_site.dart';
import '../models/inventory_item.dart';
import '../models/inventory_batch.dart';
import '../models/protocol.dart';
import '../models/tracking_preferences.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/dose_completion_service.dart';
import '../services/dose_service.dart';
import '../services/injection_rotation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/completed_dose_sheet.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_today_card.dart';
import '../widgets/ghost_supply_card.dart';
import '../widgets/take_dose_sheet.dart';
import '../widgets/today_doses_card.dart';
import '../widgets/upcoming_carousel.dart';
import '../widgets/weight_card.dart';
import 'add_protocol_screen.dart';
import 'daily_timeline_screen.dart';
import 'inventory_screen.dart';
import 'weight_history_screen.dart';
import '../models/profile.dart';
import '../models/profile_module.dart';
import '../models/injection_site_suggestion.dart';
import '../models/progress_photo_session.dart';
import '../services/progress_photo_service.dart';
import '../widgets/progress_photos_card.dart';
import 'progress_photo_screen.dart';
import '../models/symptom_entry.dart';
import '../services/symptom_service.dart';
import 'daily_notes_symptoms_screen.dart';
import '../models/measurement_system.dart';
import '../utils/weight_display.dart';
import '../theme/arctic_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.protocols,
    required this.onProtocolAdded,
    required this.dataService,
    required this.dataRevision,
    required this.homeLayout,
    required this.onDataChanged,
    required this.trackingPreferences,
    required this.displayPreferences,
    required this.measurementSystem,
    required this.profile,
    super.key,
  });

  final List<Protocol> protocols;
  final Future<void> Function(Protocol protocol) onProtocolAdded;
  final AppDataService dataService;
  final int dataRevision;
  final HomeLayout homeLayout;
  final VoidCallback onDataChanged;
  final TrackingPreferences trackingPreferences;
  final DisplayPreferences displayPreferences;
  final MeasurementSystem measurementSystem;
  final Profile profile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DoseService _doseService = DoseService();
  final InjectionRotationService _rotationService = InjectionRotationService();
  late final DoseCompletionService _doseCompletionService;
  final ProgressPhotoService _progressPhotoService = ProgressPhotoService();
  final SymptomService _symptomService = SymptomService();

  List<ProgressPhotoSession> _progressPhotoSessions = [];
  List<SymptomEntry> _symptomEntries = [];

  List<Dose> _doses = [];
  List<WeightRecord> _weightRecords = [];
  List<DoseRecord> _recentDoseRecords = [];
  List<InventoryItem> _inventoryItems = [];
  Map<String, List<InventoryBatch>> _inventoryBatchesByItemId = {};

  Timer? _refreshTimer;

  bool _isLoadingWeight = true;

  @override
  void initState() {
    super.initState();

    _doseCompletionService = DoseCompletionService(widget.dataService);

    _loadDashboardData();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadDoseData();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.protocols != widget.protocols) {
      _loadDoseData();
    }

    if (oldWidget.dataRevision != widget.dataRevision) {
      _loadDashboardData();
    }

    if (oldWidget.trackingPreferences != widget.trackingPreferences) {
      _loadProgressPhotoData();
      _loadSymptomData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadDoseData(),
      _loadRecentDoseData(),
      _loadWeightData(),
      _loadInventoryData(),
      _loadProgressPhotoData(),
      _loadSymptomData(),
    ]);
  }

  Future<void> _loadSymptomData() async {
    if (!widget.trackingPreferences.trackNotes) {
      if (!mounted) {
        return;
      }

      setState(() {
        _symptomEntries = [];
      });

      return;
    }

    final entries = await _symptomService.getAllEntries();

    entries.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _symptomEntries = entries;
    });
  }

  Future<void> _loadDoseData() async {
    final refreshedDoses = _doseService.getTodaysDoses(widget.protocols);

    final savedRecords = await widget.dataService.getDoseRecordsForDate(
      DateTime.now(),
    );

    final recordsByDose = <String, DoseRecord>{
      for (final record in savedRecords)
        _doseKey(record.protocolId, record.scheduledFor): record,
    };

    for (final dose in refreshedDoses) {
      final record =
          recordsByDose[_doseKey(dose.protocolId, dose.scheduledFor)];

      if (record == null) {
        continue;
      }

      dose.status = record.status;
      dose.completedAt = record.completedAt;

      if (record.status == DoseRecordStatus.taken) {
        final injectionLog = await widget.dataService
            .getInjectionLogForDoseRecord(record.id);

        dose.injectionSiteLabel = injectionLog?.site.label;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _doses = refreshedDoses;
    });
  }

  Future<void> _loadWeightData() async {
    final records = await widget.dataService.getWeightRecords();

    records.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _weightRecords = records;
      _isLoadingWeight = false;
    });
  }

  Future<void> _loadInventoryData() async {
    final items = await widget.dataService.getInventoryItems();

    final batchEntries = await Future.wait(
      items.map((item) async {
        final batches = await widget.dataService.getInventoryBatchesForItem(
          item.id,
        );

        return MapEntry<String, List<InventoryBatch>>(item.id, batches);
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _inventoryItems = items;
      _inventoryBatchesByItemId = {
        for (final entry in batchEntries) entry.key: entry.value,
      };
    });
  }

  Future<void> _loadRecentDoseData() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));

    final end = DateTime(now.year, now.month, now.day + 1);

    final records = await widget.dataService.getDoseRecordsBetween(start, end);

    records.sort((first, second) {
      final firstTime = first.completedAt ?? first.scheduledFor;
      final secondTime = second.completedAt ?? second.scheduledFor;

      return secondTime.compareTo(firstTime);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _recentDoseRecords = records;
    });
  }

  Future<void> _loadProgressPhotoData() async {
    if (!widget.trackingPreferences.trackPhotos) {
      if (!mounted) {
        return;
      }

      setState(() {
        _progressPhotoSessions = [];
      });

      return;
    }

    final sessions = await _progressPhotoService.getAllSessions();

    sessions.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _progressPhotoSessions = sessions;
    });
  }

  Future<void> _toggleDose(Dose dose) async {
    if (dose.isResolved) {
      await _openCompletedDoseDetails(dose);
      return;
    }

    final protocol = _findProtocol(dose.protocolId);

    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This protocol could not be found.')),
      );
      return;
    }

    final result = await TakeDoseSheet.show(
      context: context,
      protocol: protocol,
      injectionSiteSuggestionFuture: _getInjectionSiteSuggestion(protocol),
      onSkip: () async {
        await _skipDose(dose, protocol);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    String? preferredInventoryBatchId;

    try {
      final rolloverCheck = await _doseCompletionService.checkInventoryRollover(
        protocol: protocol,
        result: result,
      );

      if (!mounted) {
        return;
      }

      if (rolloverCheck?.requiresNewContainer == true) {
        final choice = await _showInventoryRolloverSheet(rolloverCheck!);

        if (choice == null || !mounted) {
          return;
        }

        if (choice.batch != null) {
          preferredInventoryBatchId = choice.batch!.id;
        } else if (choice.useNewBatch) {
          final newBatchResult =
              await showModalBottomSheet<_NewRolloverBatchResult>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) {
                  return _NewRolloverBatchSheet(item: rolloverCheck.item);
                },
              );

          if (newBatchResult == null || !mounted) {
            return;
          }

          final beforeBatches = await widget.dataService
              .getInventoryBatchesForItem(rolloverCheck.item.id);
          final beforeIds = beforeBatches.map((batch) => batch.id).toSet();

          await widget.dataService.addInventoryStock(
            item: rolloverCheck.item,
            batchName: newBatchResult.batchName,
            containerSize: newBatchResult.containerSize,
            quantity: newBatchResult.quantity,
            vendor: newBatchResult.vendor,
            batchNumber: newBatchResult.batchNumber,
            purchaseDate: newBatchResult.purchaseDate,
            expirationDate: newBatchResult.expirationDate,
            cost: newBatchResult.cost,
            notes: newBatchResult.notes,
          );

          final afterBatches = await widget.dataService
              .getInventoryBatchesForItem(rolloverCheck.item.id);

          InventoryBatch? createdBatch;
          for (final batch in afterBatches) {
            if (!beforeIds.contains(batch.id)) {
              createdBatch = batch;
              break;
            }
          }

          if (createdBatch == null) {
            throw StateError('ArcticDose could not identify the new batch.');
          }

          preferredInventoryBatchId = createdBatch.id;
        }
      }

      await _doseCompletionService.completeDose(
        dose: dose,
        protocol: protocol,
        result: result,
        preferredInventoryBatchId: preferredInventoryBatchId,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete dose: $error')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadDoseData(),
      _loadRecentDoseData(),
      _loadInventoryData(),
    ]);

    if (!mounted) {
      return;
    }

    widget.onDataChanged();
  }

  Future<void> _skipDose(Dose dose, Protocol protocol) async {
    final record = DoseRecord(
      id:
          '${dose.protocolId}-'
          '${dose.scheduledFor.microsecondsSinceEpoch}',
      protocolId: dose.protocolId,
      scheduledFor: dose.scheduledFor,
      scheduledAmount: dose.amount,
      actualAmount: null,
      completedAt: DateTime.now(),
      status: DoseRecordStatus.skipped,
    );

    try {
      await widget.dataService.saveDoseRecord(record);

      if (!mounted) {
        return;
      }

      await Future.wait([
        _loadDoseData(),
        _loadRecentDoseData(),
        _loadInventoryData(),
      ]);

      if (!mounted) {
        return;
      }

      widget.onDataChanged();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not skip dose: $error')));
    }
  }

  Future<_InventoryRolloverChoice?> _showInventoryRolloverSheet(
    InventoryRolloverCheck check,
  ) {
    return showModalBottomSheet<_InventoryRolloverChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return _InventoryRolloverSheet(
          item: check.item,
          batches: check.availableBatches,
          doseAmount: check.doseAmount,
        );
      },
    );
  }

  Future<void> _openCompletedDoseDetails(Dose dose) async {
    final record = await _findDoseRecordForDose(dose);

    if (!mounted) {
      return;
    }

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The completed dose record could not be found.'),
        ),
      );
      return;
    }

    final injectionLog = await _findInjectionLogForRecord(record);

    if (!mounted) {
      return;
    }

    final shouldUndo = await CompletedDoseSheet.show(
      context: context,
      dose: dose,
      record: record,
      injectionLog: injectionLog,
    );

    if (!shouldUndo || !mounted) {
      return;
    }

    await widget.dataService.deleteInjectionLogForDoseRecord(record.id);

    await widget.dataService.deleteDoseRecord(
      protocolId: dose.protocolId,
      scheduledFor: dose.scheduledFor,
    );

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadDoseData(),
      _loadRecentDoseData(),
      _loadInventoryData(),
    ]);

    if (!mounted) {
      return;
    }

    widget.onDataChanged();
  }

  Future<DoseRecord?> _findDoseRecordForDose(Dose dose) async {
    final records = await widget.dataService.getDoseRecordsForProtocol(
      dose.protocolId,
    );

    final scheduledFor = dose.scheduledFor.toIso8601String();

    for (final record in records) {
      if (record.scheduledFor.toIso8601String() == scheduledFor) {
        return record;
      }
    }

    return null;
  }

  Future<InjectionLog?> _findInjectionLogForRecord(DoseRecord record) {
    return widget.dataService.getInjectionLogForDoseRecord(record.id);
  }

  Protocol? _findProtocol(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol;
      }
    }

    return null;
  }

  Future<InjectionSiteSuggestion> _getInjectionSiteSuggestion(
    Protocol protocol,
  ) async {
    if (!protocol.isInjection || !protocol.rotationEnabled) {
      return const InjectionSiteSuggestion(
        recommendedSite: null,
        previousSite: null,
      );
    }

    final logs = await widget.dataService.getInjectionLogsForProtocol(
      protocol.id,
    );

    final chronologicalHistory = logs.reversed
        .map((log) => log.site)
        .toList(growable: false);

    final result = _rotationService.getNextSite(
      mode: protocol.rotationMode,
      enabledSites: protocol.enabledInjectionSites,
      history: chronologicalHistory,
    );

    return InjectionSiteSuggestion(
      recommendedSite: result.nextSite,
      previousSite: result.previousSite,
    );
  }

  Future<void> _openAddProtocol() async {
    final protocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => const AddProtocolScreen()),
    );

    if (protocol == null || !mounted) {
      return;
    }

    await widget.onProtocolAdded(protocol);

    if (!mounted) {
      return;
    }

    await _loadDoseData();
  }

  Future<void> _openUpcomingDay(DateTime date) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyTimelineScreen(
          date: date,
          protocols: widget.protocols,
          dataService: widget.dataService,
          onDataChanged: widget.onDataChanged,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadDashboardData();
  }

  Future<void> _openGhostSupply() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryScreen(
          dataService: widget.dataService,
          protocols: widget.protocols,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadInventoryData();
  }

  Future<void> _openWeightDialog() async {
    final currentStoredWeight = _weightRecords.isEmpty
        ? null
        : _weightRecords.first.weight;

    final initialDisplayWeight = currentStoredWeight == null
        ? null
        : WeightDisplay.displayValue(
            currentStoredWeight,
            widget.measurementSystem,
          );

    final enteredWeight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightEntryDialog(
        initialWeight: initialDisplayWeight,
        isFirstEntry: _weightRecords.isEmpty,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (enteredWeight == null || !mounted) {
      return;
    }

    final storedWeight = WeightDisplay.storageValue(
      enteredWeight,
      widget.measurementSystem,
    );

    final now = DateTime.now();

    final existingRecord = await widget.dataService.getWeightRecordForDate(now);

    final record = WeightRecord(
      id: existingRecord?.id ?? now.microsecondsSinceEpoch.toString(),
      weight: storedWeight,
      recordedAt: now,
    );

    await widget.dataService.saveWeightRecord(record);

    if (!mounted) {
      return;
    }

    await _loadWeightData();

    if (!mounted) {
      return;
    }

    widget.onDataChanged();
  }

  Future<void> _openWeightHistory() async {
    final didChange = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WeightHistoryScreen(
          dataService: widget.dataService,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );

    if (!mounted || didChange != true) {
      return;
    }

    await _loadWeightData();

    if (!mounted) {
      return;
    }

    widget.onDataChanged();
  }

  Future<void> _openProgressPhotos() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressPhotosScreen(
          dataService: widget.dataService,
          measurementSystem: widget.measurementSystem,
          startSessionOnOpen: true,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProgressPhotoData();
  }

  Future<void> _startProgressPhotoSession() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressPhotosScreen(
          dataService: widget.dataService,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProgressPhotoData();
  }

  String _doseKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|'
        '${scheduledFor.toIso8601String()}';
  }

  List<Widget> _buildConfiguredSections({
    required bool hasProtocols,
    required bool hasWeight,
    required double? currentWeight,
    required double? startingWeight,
  }) {
    if (!hasProtocols) {
      if (widget.profile.hasModule(ProfileModule.protocols)) {
        return [EmptyTodayCard(onAddProtocol: _openAddProtocol)];
      }

      if (widget.profile.hasModule(ProfileModule.weight)) {
        return [_EmptyWeightCard(onLogWeight: _openWeightDialog)];
      }

      return const [];
    }

    final sections = <Widget>[];

    for (final section in widget.homeLayout.visibleSections) {
      if (section == HomeSection.upcoming &&
          !widget.displayPreferences.showUpcoming) {
        continue;
      }

      if (section == HomeSection.weight &&
          !widget.displayPreferences.showWeight) {
        continue;
      }

      if (section == HomeSection.recentActivity &&
          !widget.displayPreferences.showRecentActivity) {
        continue;
      }

      final Widget sectionWidget = switch (section) {
        HomeSection.today => _buildTodaySection(),
        HomeSection.ghostSupply => _buildGhostSupplySection(),
        HomeSection.upcoming => _buildUpcomingSection(),
        HomeSection.weight => _buildWeightSection(
          hasWeight: hasWeight,
          currentWeight: currentWeight,
          startingWeight: startingWeight,
        ),
        HomeSection.progressPhotos => _buildProgressPhotosSection(),
        HomeSection.recentActivity => _buildRecentActivitySection(),
        HomeSection.notesSymptoms => _buildNotesSymptomsSection(),
      };

      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpacing.md));
      }

      sections.add(sectionWidget);
    }

    return sections;
  }

  Widget _buildTodaySection() {
    final visibleDoses = widget.displayPreferences.showCompletedDoses
        ? _doses
        : _doses.where((dose) => !dose.isResolved).toList();

    return _DashboardSectionContainer(
      title: 'Today\'s Doses',
      mergeWithHeader: true,
      child: TodayDosesCard(
        doses: visibleDoses,
        onDosePressed: _toggleDose,
        displayPreferences: widget.displayPreferences,
      ),
    );
  }

  Widget _buildGhostSupplySection() {
    return GhostSupplyCard(
      items: _inventoryItems,
      protocols: widget.protocols,
      batchesByItemId: _inventoryBatchesByItemId,
      onTap: _openGhostSupply,
    );
  }

  Widget _buildUpcomingSection() {
    return _DashboardSectionContainer(
      title: 'Upcoming',
      child: UpcomingCarousel(
        protocols: widget.protocols,
        onDayTapped: _openUpcomingDay,
      ),
    );
  }

  Widget _buildWeightSection({
    required bool hasWeight,
    required double? currentWeight,
    required double? startingWeight,
  }) {
    Widget content;

    if (_isLoadingWeight) {
      content = const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!hasWeight) {
      content = _EmptyWeightCard(onLogWeight: _openWeightDialog);
    } else {
      content = WeightCard(
        currentWeight: currentWeight!,
        startingWeight: startingWeight!,
        weightRecords: _weightRecords,
        measurementSystem: widget.measurementSystem,
        onLogWeight: _openWeightDialog,
        onOpenHistory: _openWeightHistory,
      );
    }

    return _DashboardSectionContainer(
      title: 'Weight',
      trailing: TextButton(
        onPressed: _openWeightDialog,
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Log'),
      ),
      child: content,
    );
  }

  Widget _buildProgressPhotosSection() {
    return ProgressPhotosCard(
      preferences: widget.trackingPreferences,
      sessions: _progressPhotoSessions,
      onOpen: _openProgressPhotos,
      onStartSession: _startProgressPhotoSession,
    );
  }

  Widget _buildNotesSymptomsSection() {
    final now = DateTime.now();

    final todayEntries = _symptomEntries.where((entry) {
      return entry.recordedAt.year == now.year &&
          entry.recordedAt.month == now.month &&
          entry.recordedAt.day == now.day;
    }).toList();

    todayEntries.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    return _NotesSymptomsHomeCard(
      todayEntries: todayEntries,
      recentEntries: _symptomEntries.take(5).toList(),
      onOpen: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => DailyNotesSymptomsScreen(
              date: DateTime(now.year, now.month, now.day),
              protocols: widget.protocols,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        await _loadSymptomData();
      },
    );
  }

  Widget _buildRecentActivitySection() {
    final items = <_RecentActivityItem>[];

    for (final record in _recentDoseRecords) {
      final protocol = _findProtocol(record.protocolId);

      if (protocol == null) {
        continue;
      }

      final recordedAt = record.completedAt ?? record.scheduledFor;

      final statusText = switch (record.status) {
        DoseRecordStatus.taken => 'Dose taken',
        DoseRecordStatus.missed => 'Dose missed',
        DoseRecordStatus.skipped => 'Dose skipped',
      };

      items.add(
        _RecentActivityItem(
          type: _RecentActivityType.dose,
          title: protocol.name,
          subtitle: statusText,
          recordedAt: recordedAt,
          icon: record.status == DoseRecordStatus.taken
              ? Icons.check_circle_outline
              : record.status == DoseRecordStatus.missed
              ? ArcticIcons.error_outline
              : Icons.remove_circle_outline,
          colorValue: protocol.colorValue,
        ),
      );
    }

    for (final record in _weightRecords) {
      items.add(
        _RecentActivityItem(
          type: _RecentActivityType.weight,
          title: 'Weight logged',
          subtitle: WeightDisplay.format(
            record.weight,
            widget.measurementSystem,
          ),
          recordedAt: record.recordedAt,
          icon: ArcticIcons.monitor_weight_outlined,
        ),
      );
    }

    for (final entry in _symptomEntries) {
      items.add(
        _RecentActivityItem(
          type: _RecentActivityType.symptom,
          title: entry.symptomName,
          subtitle: 'Severity ${entry.severity}/5',
          recordedAt: entry.recordedAt,
          icon: ArcticIcons.notes_outlined,
        ),
      );
    }

    for (final session in _progressPhotoSessions) {
      items.add(
        _RecentActivityItem(
          type: _RecentActivityType.photo,
          title: 'Progress photos',
          subtitle: 'Photo session logged',
          recordedAt: session.recordedAt,
          icon: ArcticIcons.photo_camera_outlined,
        ),
      );
    }

    items.sort(
      (first, second) => second.recordedAt.compareTo(first.recordedAt),
    );

    return _RecentActivityCard(items: items.take(5).toList());
  }

  @override
  Widget build(BuildContext context) {
    final hasProtocols = widget.protocols.isNotEmpty;
    final hasWeight = _weightRecords.isNotEmpty;

    final currentWeight = hasWeight ? _weightRecords.first.weight : null;

    final startingWeight = hasWeight ? _weightRecords.last.weight : null;

    final remainingDoses = _doses.where((dose) => !dose.isResolved).length;

    final configuredSections = _buildConfiguredSections(
      hasProtocols: hasProtocols,
      hasWeight: hasWeight,
      currentWeight: currentWeight,
      startingWeight: startingWeight,
    );

    return Scaffold(
      floatingActionButton: null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            110,
          ),
          children: [
            DashboardHeader(
              profileName: widget.profile.name,
              remainingDoses: remainingDoses,
              totalDoses: _doses.length,
              onAddProtocol: hasProtocols ? _openAddProtocol : null,
              showGreeting: widget.displayPreferences.showGreeting,
              showProgressBar: widget.displayPreferences.showProgressBar,
            ),
            ...configuredSections,
          ],
        ),
      ),
    );
  }
}

class _InventoryRolloverChoice {
  const _InventoryRolloverChoice._({this.batch, this.useNewBatch = false});

  const _InventoryRolloverChoice.batch(InventoryBatch batch)
    : this._(batch: batch);

  const _InventoryRolloverChoice.newBatch() : this._(useNewBatch: true);

  final InventoryBatch? batch;
  final bool useNewBatch;
}

class _InventoryRolloverSheet extends StatelessWidget {
  const _InventoryRolloverSheet({
    required this.item,
    required this.batches,
    required this.doseAmount,
  });

  final InventoryItem item;
  final List<InventoryBatch> batches;
  final double doseAmount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final containerName = item.containerType.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your next supply',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.currentAmount > 0
                  ? 'Your current $containerName has only '
                        '${_formatDashboardAmount(item.currentAmount)} '
                        '${item.unit} remaining. This dose needs '
                        '${_formatDashboardAmount(doseAmount)} ${item.unit}. '
                        'Choose which batch ArcticDose should open next.'
                  : 'Your current $containerName is empty. '
                        'Choose which batch ArcticDose should open next.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final batch in batches) ...[
              _RolloverBatchTile(
                batch: batch,
                onTap: () {
                  Navigator.pop(context, _InventoryRolloverChoice.batch(batch));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _RolloverNewBatchTile(
              onTap: () {
                Navigator.pop(
                  context,
                  const _InventoryRolloverChoice.newBatch(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolloverBatchTile extends StatelessWidget {
  const _RolloverBatchTile({required this.batch, required this.onTap});

  final InventoryBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final details = <String>[
      '${_formatDashboardAmount(batch.containerSize)} ${batch.unit}',
      '${batch.quantity} unopened',
      if (batch.vendor != null && batch.vendor!.trim().isNotEmpty)
        batch.vendor!.trim(),
      if (batch.batch != null && batch.batch!.trim().isNotEmpty)
        'Lot ${batch.batch!.trim()}',
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
          ),
          child: Row(
            children: [
              Icon(ArcticIcons.inventory_2_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.join(' • '),
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolloverNewBatchTile extends StatelessWidget {
  const _RolloverNewBatchTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: ArcticPalette.ice.withValues(alpha: 0.72),
              width: 1.35,
            ),
          ),
          child: Row(
            children: [
              Icon(ArcticIcons.add_box_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Batch',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add new inventory and use it for this rollover.',
                      style: TextStyle(fontSize: AppTypography.caption),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewRolloverBatchResult {
  const _NewRolloverBatchResult({
    required this.batchName,
    required this.containerSize,
    required this.quantity,
    this.vendor,
    this.batchNumber,
    this.purchaseDate,
    this.expirationDate,
    this.cost,
    this.notes,
  });

  final String batchName;
  final double containerSize;
  final int quantity;
  final String? vendor;
  final String? batchNumber;
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final double? cost;
  final String? notes;
}

class _NewRolloverBatchSheet extends StatefulWidget {
  const _NewRolloverBatchSheet({required this.item});

  final InventoryItem item;

  @override
  State<_NewRolloverBatchSheet> createState() => _NewRolloverBatchSheetState();
}

class _NewRolloverBatchSheetState extends State<_NewRolloverBatchSheet> {
  final TextEditingController _batchNameController = TextEditingController();
  late final TextEditingController _containerSizeController;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _purchaseDate;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    _containerSizeController = TextEditingController(
      text: _formatDashboardAmount(widget.item.vialSize),
    );
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _containerSizeController.dispose();
    _quantityController.dispose();
    _vendorController.dispose();
    _batchNumberController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _containerSize =>
      double.tryParse(_containerSizeController.text.trim());

  int? get _quantity => int.tryParse(_quantityController.text.trim());

  double? get _cost {
    final value = _costController.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  bool get _canSave {
    if (_batchNameController.text.trim().isEmpty) return false;
    final containerSize = _containerSize;
    final quantity = _quantity;
    if (containerSize == null || containerSize <= 0) return false;
    if (quantity == null || quantity <= 0) return false;
    if (_costController.text.trim().isNotEmpty && _cost == null) return false;
    return true;
  }

  Future<void> _choosePurchaseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (selected == null) return;
    setState(() {
      _purchaseDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  Future<void> _chooseExpirationDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (selected == null) return;
    setState(() {
      _expirationDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Batch',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add this batch to Arctic Supply and use it for the rollover.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _batchNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Batch name *',
                hintText: 'Example: QSC 100mg Kit',
                prefixIcon: Icon(ArcticIcons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _containerSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Container size',
                suffixText: widget.item.unit,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Quantity',
                suffixText: _pluralizeDashboard(widget.item.containerType),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _vendorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vendor',
                hintText: 'Optional',
                prefixIcon: Icon(ArcticIcons.store_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _batchNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Batch / lot',
                hintText: 'Optional',
                prefixIcon: Icon(ArcticIcons.qr_code_2_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RolloverDateTile(
              label: 'Purchase date',
              value: _purchaseDate,
              icon: ArcticIcons.shopping_bag_outlined,
              onTap: _choosePurchaseDate,
              onClear: _purchaseDate == null
                  ? null
                  : () => setState(() => _purchaseDate = null),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RolloverDateTile(
              label: 'Expiration date',
              value: _expirationDate,
              icon: ArcticIcons.event_busy_outlined,
              onTap: _chooseExpirationDate,
              onClear: _expirationDate == null
                  ? null
                  : () => setState(() => _expirationDate = null),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Cost',
                hintText: 'Optional',
                prefixText: '\$ ',
                prefixIcon: Icon(ArcticIcons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave
                    ? () {
                        Navigator.pop(
                          context,
                          _NewRolloverBatchResult(
                            batchName: _batchNameController.text.trim(),
                            containerSize: _containerSize!,
                            quantity: _quantity!,
                            vendor: _optionalDashboardText(
                              _vendorController.text,
                            ),
                            batchNumber: _optionalDashboardText(
                              _batchNumberController.text,
                            ),
                            purchaseDate: _purchaseDate,
                            expirationDate: _expirationDate,
                            cost: _cost,
                            notes: _optionalDashboardText(
                              _notesController.text,
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Add & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolloverDateTile extends StatelessWidget {
  const _RolloverDateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.45),
              width: 1.35,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value == null ? 'Not set' : _formatDashboardDate(value!),
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear $label',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDashboardAmount(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String? _optionalDashboardText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _pluralizeDashboard(String value) {
  final normalized = value.toLowerCase();
  if (normalized == 'box') return 'boxes';
  if (normalized.endsWith('s')) return normalized;
  return '${normalized}s';
}

String _formatDashboardDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

class _RecentActivityItem {
  const _RecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.recordedAt,
    required this.icon,
    this.colorValue,
  });

  final _RecentActivityType type;
  final String title;
  final String subtitle;
  final DateTime recordedAt;
  final IconData icon;
  final int? colorValue;
}

enum _RecentActivityType { dose, weight, symptom, photo }

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<_RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.45),
          width: 1.35,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (items.isEmpty)
              Text(
                'No recent activity yet.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                _RecentActivityRow(item: items[index]),
                if (index < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Divider(height: 1),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.item});

  final _RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final accentColor = item.colorValue == null
        ? colors.primary
        : Color(item.colorValue!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatRecentActivityTime(item.recordedAt),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _formatRecentActivityTime(DateTime value) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final activityDay = DateTime(value.year, value.month, value.day);

  final difference = today.difference(activityDay).inDays;

  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;

  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  final time = '$hour:$minute $period';

  if (difference == 0) {
    return 'Today\n$time';
  }

  if (difference == 1) {
    return 'Yesterday\n$time';
  }

  if (value.year == now.year) {
    return '${value.month}/${value.day}\n$time';
  }

  return '${value.month}/${value.day}/${value.year}\n$time';
}

class _NotesSymptomsHomeCard extends StatelessWidget {
  const _NotesSymptomsHomeCard({
    required this.todayEntries,
    required this.recentEntries,
    required this.onOpen,
  });

  final List<SymptomEntry> todayEntries;
  final List<SymptomEntry> recentEntries;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayEntries = todayEntries.isNotEmpty
        ? todayEntries
        : recentEntries;

    final visibleEntries = displayEntries.take(2).toList();
    final remainingCount = displayEntries.length - visibleEntries.length;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(ArcticIcons.notes_outlined, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Notes & Symptoms',
                      style: TextStyle(
                        fontSize: AppTypography.title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              if (displayEntries.isEmpty) ...[
                Text(
                  'No symptoms logged today.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.add),
                    label: const Text('Log Symptoms'),
                  ),
                ),
              ] else ...[
                Text(
                  todayEntries.isNotEmpty
                      ? '${todayEntries.length} logged today'
                      : 'Recent activity',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                for (final entry in visibleEntries) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.symptomName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${entry.severity}/5',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (entry.notes != null &&
                      entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.notes!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),
                ],

                if (remainingCount > 0) ...[
                  Text(
                    '+$remainingCount more ${remainingCount == 1 ? 'symptom' : 'symptoms'}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSectionContainer extends StatelessWidget {
  const _DashboardSectionContainer({
    required this.title,
    required this.child,
    this.trailing,
    this.mergeWithHeader = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool mergeWithHeader;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: mergeWithHeader
            ? ArcticPalette.ice.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.075
                    : 0.10,
              )
            : Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: mergeWithHeader
            ? const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.card),
              )
            : BorderRadius.circular(AppRadius.card),
        border: Border(
          left: BorderSide(
            color: mergeWithHeader
                ? colors.primary.withValues(alpha: 0.22)
                : colors.outline.withValues(alpha: 0.45),
            width: mergeWithHeader ? 1.2 : 1.35,
          ),
          right: BorderSide(
            color: mergeWithHeader
                ? colors.primary.withValues(alpha: 0.22)
                : colors.outline.withValues(alpha: 0.45),
            width: mergeWithHeader ? 1.2 : 1.35,
          ),
          bottom: BorderSide(
            color: mergeWithHeader
                ? colors.primary.withValues(alpha: 0.22)
                : colors.outline.withValues(alpha: 0.45),
            width: mergeWithHeader ? 1.2 : 1.35,
          ),
          top: mergeWithHeader
              ? BorderSide.none
              : BorderSide(
                  color: colors.outline.withValues(alpha: 0.45),
                  width: 1.35,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mergeWithHeader)
            _MergedSectionTitle(title: title)
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),

          const SizedBox(height: AppSpacing.md),

          child,
        ],
      ),
    );
  }
}

class _MergedSectionTitle extends StatelessWidget {
  const _MergedSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: ArcticPalette.ice.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.15,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: ArcticPalette.ice.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyWeightCard extends StatelessWidget {
  const _EmptyWeightCard({required this.onLogWeight});

  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start tracking your weight to see your progress.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogWeight,
                icon: const Icon(Icons.add),
                label: const Text('Log First Weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({
    required this.initialWeight,
    required this.isFirstEntry,
    required this.measurementSystem,
  });

  final double? initialWeight;
  final bool isFirstEntry;
  final MeasurementSystem measurementSystem;

  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_controller.text.trim());

    if (weight == null || weight <= 0) {
      return;
    }

    Navigator.pop(context, weight);
  }

  @override
  Widget build(BuildContext context) {
    final unit = WeightDisplay.unit(widget.measurementSystem);

    final hint = widget.measurementSystem == MeasurementSystem.metric
        ? '150.0'
        : '350.0';

    return AlertDialog(
      title: Text(widget.isFirstEntry ? 'Set Starting Weight' : 'Log Weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Weight',
          suffixText: unit,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
