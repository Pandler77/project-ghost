import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';
import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/tracking_preferences.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/dose_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_today_card.dart';
import '../widgets/ghost_supply_card.dart';
import '../widgets/today_doses_card.dart';
import '../widgets/upcoming_carousel.dart';
import '../widgets/weight_card.dart';
import 'add_protocol_screen.dart';
import 'daily_timeline_screen.dart';
import 'inventory_screen.dart';
import 'weight_history_screen.dart';
import '../models/profile.dart';
import '../models/profile_module.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.protocols,
    required this.onProtocolAdded,
    required this.dataService,
    required this.dataRevision,
    required this.homeLayout,
    required this.onDataChanged,
    required this.trackingPreferences,
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
  final Profile profile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DoseService _doseService = DoseService();

  List<Dose> _doses = [];
  List<WeightRecord> _weightRecords = [];
  List<InventoryItem> _inventoryItems = [];

  Timer? _refreshTimer;

  bool _isLoadingWeight = true;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadDoseData(),
      _loadWeightData(),
      _loadInventoryData(),
    ]);
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

      if (record?.status == DoseRecordStatus.taken) {
        dose.completedAt = record!.completedAt;
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

    if (!mounted) {
      return;
    }

    setState(() {
      _inventoryItems = items;
    });
  }

  Future<void> _toggleDose(Dose dose) async {
    if (dose.isCompleted) {
      await widget.dataService.deleteDoseRecord(
        protocolId: dose.protocolId,
        scheduledFor: dose.scheduledFor,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        dose.completedAt = null;
      });

      await _loadInventoryData();

      if (!mounted) {
        return;
      }

      widget.onDataChanged();
      return;
    }

    final completedAt = DateTime.now();

    final record = DoseRecord(
      id:
          '${dose.protocolId}-'
          '${dose.scheduledFor.microsecondsSinceEpoch}',
      protocolId: dose.protocolId,
      scheduledFor: dose.scheduledFor,
      scheduledAmount: dose.amount,
      actualAmount: dose.amount,
      completedAt: completedAt,
      status: DoseRecordStatus.taken,
    );

    await widget.dataService.saveDoseRecord(record);

    if (!mounted) {
      return;
    }

    setState(() {
      dose.completedAt = completedAt;
    });

    await _loadInventoryData();

    if (!mounted) {
      return;
    }

    widget.onDataChanged();
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
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => _WeightEntryDialog(
        initialWeight: _weightRecords.isEmpty
            ? null
            : _weightRecords.first.weight,
        isFirstEntry: _weightRecords.isEmpty,
      ),
    );

    if (weight == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    final existingRecord = await widget.dataService.getWeightRecordForDate(now);

    final record = WeightRecord(
      id: existingRecord?.id ?? now.microsecondsSinceEpoch.toString(),
      weight: weight,
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
        builder: (_) => WeightHistoryScreen(dataService: widget.dataService),
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
      if (section == HomeSection.weight &&
          !widget.trackingPreferences.trackWeight) {
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
        HomeSection.recentActivity => _buildRecentActivitySection(),
      };

      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: AppSpacing.lg));
      }

      sections.add(sectionWidget);
    }

    return sections;
  }

  Widget _buildTodaySection() {
    return TodayDosesCard(doses: _doses, onDosePressed: _toggleDose);
  }

  Widget _buildGhostSupplySection() {
    return GhostSupplyCard(
      items: _inventoryItems,
      protocols: widget.protocols,
      onTap: _openGhostSupply,
    );
  }

  Widget _buildUpcomingSection() {
    return UpcomingCarousel(
      protocols: widget.protocols,
      onDayTapped: _openUpcomingDay,
    );
  }

  Widget _buildWeightSection({
    required bool hasWeight,
    required double? currentWeight,
    required double? startingWeight,
  }) {
    if (_isLoadingWeight) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!hasWeight) {
      return _EmptyWeightCard(onLogWeight: _openWeightDialog);
    }

    return WeightCard(
      currentWeight: currentWeight!,
      startingWeight: startingWeight!,
      weightRecords: _weightRecords,
      onLogWeight: _openWeightDialog,
      onOpenHistory: _openWeightHistory,
    );
  }

  Widget _buildRecentActivitySection() {
    return const _RecentActivityPlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    final hasProtocols = widget.protocols.isNotEmpty;
    final hasWeight = _weightRecords.isNotEmpty;

    final currentWeight = hasWeight ? _weightRecords.first.weight : null;

    final startingWeight = hasWeight ? _weightRecords.last.weight : null;

    final remainingDoses = _doses.where((dose) => !dose.isCompleted).length;

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
              remainingDoses: remainingDoses,
              totalDoses: _doses.length,
            ),
            if (configuredSections.isNotEmpty)
              const SizedBox(height: AppSpacing.lg),
            ...configuredSections,
          ],
        ),
      ),
    );
  }
}

class _RecentActivityPlaceholder extends StatelessWidget {
  const _RecentActivityPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your latest dose and weight activity will appear here.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
  });

  final double? initialWeight;
  final bool isFirstEntry;

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
    return AlertDialog(
      title: Text(widget.isFirstEntry ? 'Set Starting Weight' : 'Log Weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Weight',
          suffixText: 'lb',
          hintText: '350.0',
          border: OutlineInputBorder(),
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
