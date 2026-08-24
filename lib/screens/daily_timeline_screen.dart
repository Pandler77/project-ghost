import 'package:flutter/material.dart';
import 'dart:io';

import '../models/daily_protocol_item.dart';
import '../models/dose_record.dart';
import '../models/injection_log.dart';
import '../models/injection_site.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/protocol_schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily/edit_day_sheet.dart';
import 'daily_notes_symptoms_screen.dart';
import '../models/symptom_entry.dart';
import '../services/symptom_service.dart';
import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import '../services/progress_photo_service.dart';
import 'progress_photo_session_screen.dart';
import '../models/measurement_system.dart';
import '../utils/weight_display.dart';
import '../theme/arctic_icons.dart';

class DailyTimelineScreen extends StatefulWidget {
  const DailyTimelineScreen({
    required this.date,
    required this.protocols,
    required this.dataService,
    required this.onDataChanged,
    required this.measurementSystem,
    super.key,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final AppDataService dataService;
  final VoidCallback onDataChanged;
  final MeasurementSystem measurementSystem;

  @override
  State<DailyTimelineScreen> createState() => _DailyTimelineScreenState();
}

class _DailyTimelineScreenState extends State<DailyTimelineScreen>
    with SingleTickerProviderStateMixin {
  final ProtocolScheduleService _scheduleService =
      const ProtocolScheduleService();
  final SymptomService _symptomService = SymptomService();
  final ProgressPhotoService _progressPhotoService = ProgressPhotoService();

  List<ProgressPhotoSession> _photoSessions = [];
  Map<String, List<ProgressPhoto>> _photosBySessionId = {};

  List<SymptomEntry> _symptomEntries = [];

  late final TabController _tabController;

  WeightRecord? _weightRecord;
  List<DailyProtocolItem> _protocolItems = [];
  Map<String, InjectionLog> _injectionLogsByDoseRecordId = {};

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _loadDay();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDay() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        widget.dataService.getWeightRecordForDate(widget.date),
        widget.dataService.getDoseRecordsForDate(widget.date),
        widget.dataService.getAllInjectionLogs(),
        _symptomService.getEntriesForDate(widget.date),
        _progressPhotoService.getSessionsForDate(widget.date),
      ]);

      final weightRecord = results[0] as WeightRecord?;
      final doseRecords = results[1] as List<DoseRecord>;
      final injectionLogs = results[2] as List<InjectionLog>;
      final symptomEntries = results[3] as List<SymptomEntry>;
      final photoSessions = results[4] as List<ProgressPhotoSession>;

      final injectionLogsByDoseRecordId = <String, InjectionLog>{
        for (final log in injectionLogs) log.doseRecordId: log,
      };

      final photosBySessionId = <String, List<ProgressPhoto>>{};

      for (final session in photoSessions) {
        photosBySessionId[session.id] = await _progressPhotoService
            .getPhotosForSession(session.id);
      }

      final recordsByDose = <String, DoseRecord>{
        for (final record in doseRecords)
          _doseKey(record.protocolId, record.scheduledFor): record,
      };

      final scheduledProtocols = _scheduleService.protocolsForDate(
        widget.protocols,
        widget.date,
      );

      final items = <DailyProtocolItem>[];
      final representedRecordIds = <String>{};

      for (final protocol in scheduledProtocols) {
        final scheduledFor = _scheduleService.scheduledDateTime(
          protocol,
          widget.date,
        );

        final record = recordsByDose[_doseKey(protocol.id, scheduledFor)];

        if (record != null) {
          representedRecordIds.add(record.id);
        }

        items.add(
          DailyProtocolItem(
            protocol: protocol,
            scheduledFor: scheduledFor,
            record: record,
          ),
        );
      }

      // Include manually entered historical doses that were not part of the
      // protocol's configured schedule on this date.
      for (final record in doseRecords) {
        if (representedRecordIds.contains(record.id)) {
          continue;
        }

        Protocol? protocol;

        for (final candidate in widget.protocols) {
          if (candidate.id == record.protocolId) {
            protocol = candidate;
            break;
          }
        }

        if (protocol == null) {
          continue;
        }

        items.add(
          DailyProtocolItem(
            protocol: protocol,
            scheduledFor: record.scheduledFor,
            record: record,
          ),
        );
      }

      items.sort(
        (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _weightRecord = weightRecord;
        _protocolItems = items;
        _injectionLogsByDoseRecordId = injectionLogsByDoseRecordId;
        _symptomEntries = symptomEntries;
        _isLoading = false;
        _photoSessions = photoSessions;
        _photosBySessionId = photosBySessionId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _openDayEditor() async {
    final result = await showModalBottomSheet<EditDayResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return EditDaySheet(
          date: widget.date,
          protocolItems: _protocolItems,
          weightRecord: _weightRecord,
          measurementSystem: widget.measurementSystem,
          onSave: (result) {
            Navigator.pop(sheetContext, result);
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await _saveDayChanges(result);
  }

  Future<void> _saveDayChanges(EditDayResult result) async {
    try {
      await _saveWeightChanges(result);
      await _saveProtocolChanges(result);

      if (!mounted) {
        return;
      }

      await _loadDay();

      if (!mounted) {
        return;
      }

      widget.onDataChanged();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Day updated.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update this day: $error')),
      );
    }
  }

  Future<void> _saveWeightChanges(EditDayResult result) async {
    if (result.deleteWeight) {
      final existingWeight = _weightRecord;

      if (existingWeight != null) {
        await widget.dataService.deleteWeightRecord(existingWeight.id);
      }

      return;
    }

    if (result.weight == null) {
      return;
    }

    final recordedAt = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      12,
    );

    final weightRecord = WeightRecord(
      id:
          _weightRecord?.id ??
          'weight-'
              '${widget.date.year}-'
              '${widget.date.month}-'
              '${widget.date.day}',
      weight: result.weight!,
      recordedAt: recordedAt,
    );

    await widget.dataService.saveWeightRecord(weightRecord);
  }

  Future<void> _saveProtocolChanges(EditDayResult result) async {
    for (final change in result.protocolChanges) {
      final item = change.item;
      final existingRecord = item.record;

      if (!change.isTaken) {
        if (existingRecord != null) {
          await widget.dataService.deleteDoseRecord(
            protocolId: item.protocol.id,
            scheduledFor: item.scheduledFor,
          );
        }

        continue;
      }

      final completedAt = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        change.completedTime.hour,
        change.completedTime.minute,
      );

      final record = DoseRecord(
        id:
            existingRecord?.id ??
            '${item.protocol.id}-'
                '${item.scheduledFor.microsecondsSinceEpoch}',
        protocolId: item.protocol.id,
        scheduledFor: item.scheduledFor,
        scheduledAmount: item.protocol.dose,
        actualAmount: change.actualAmount,
        completedAt: completedAt,
        status: DoseRecordStatus.taken,
      );

      await widget.dataService.saveDoseRecord(record);
    }
  }

  Future<void> _addHistoricalDose() async {
    if (widget.protocols.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Create a protocol first.')));
      return;
    }

    final result = await showModalBottomSheet<_HistoricalDoseResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return _HistoricalDoseSheet(
          date: widget.date,
          protocols: widget.protocols,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final protocol = result.protocol;

    final occurredAt = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      result.time.hour,
      result.time.minute,
    );

    final existingForProtocol = await widget.dataService
        .getDoseRecordsForProtocol(protocol.id);

    final duplicate = existingForProtocol.any(
      (record) =>
          record.scheduledFor.toIso8601String() == occurredAt.toIso8601String(),
    );

    if (duplicate) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A dose already exists at that exact time.'),
        ),
      );
      return;
    }

    final record = DoseRecord(
      id: '${protocol.id}-historical-${occurredAt.microsecondsSinceEpoch}',
      protocolId: protocol.id,
      scheduledFor: occurredAt,
      scheduledAmount: result.actualAmount,
      actualAmount: result.actualAmount,
      completedAt: occurredAt,
      status: DoseRecordStatus.taken,
    );

    try {
      await widget.dataService.saveDoseRecord(
        record,
        adjustInventory: false,
      );

      if (!mounted) {
        return;
      }

      await _loadDay();
      widget.onDataChanged();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Historical dose added.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add historical dose: $error')),
      );
    }
  }

  String _doseKey(String protocolId, DateTime scheduledFor) {
    return '$protocolId|'
        '${scheduledFor.toIso8601String()}';
  }

  bool get _isPastDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    return selected.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day'),
        actions: [
          if (_isPastDate)
            IconButton(
              onPressed: _addHistoricalDose,
              tooltip: 'Add historical dose',
              icon: const Icon(Icons.add_circle_outline),
            ),
          TextButton.icon(
            onPressed: _openDayEditor,
            icon: const Icon(ArcticIcons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(ArcticIcons.error_outline, size: 40),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Could not load this day.',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _loadDay, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DateHeader(date: widget.date),

        const SizedBox(height: AppSpacing.lg),

        _ProtocolsSection(
          items: _protocolItems,
          injectionLogsByDoseRecordId: _injectionLogsByDoseRecordId,
        ),

        const SizedBox(height: AppSpacing.lg),

        _WeightSection(
          record: _weightRecord,
          measurementSystem: widget.measurementSystem,
        ),

        const SizedBox(height: AppSpacing.lg),

        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notes & Symptoms'),
            Tab(text: 'Photos'),
          ],
        ),

        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _tabController,
            children: [
              _NotesSymptomsTab(
                date: widget.date,
                protocols: widget.protocols,
                entries: _symptomEntries,
                onChanged: _loadDay,
              ),
              _PhotosTab(
                sessions: _photoSessions,
                photosBySessionId: _photosBySessionId,
                measurementSystem: widget.measurementSystem,
                onOpenSession: (session) async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgressPhotoSessionScreen(
                        session: session,
                        measurementSystem: widget.measurementSystem,
                      ),
                    ),
                  );

                  if (!mounted) {
                    return;
                  }

                  await _loadDay();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _weekdayName(date.weekday),
          style: TextStyle(
            fontSize: AppTypography.body,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_monthName(date.month)} '
          '${date.day}, ${date.year}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ProtocolsSection extends StatelessWidget {
  const _ProtocolsSection({
    required this.items,
    required this.injectionLogsByDoseRecordId,
  });

  final List<DailyProtocolItem> items;
  final Map<String, InjectionLog> injectionLogsByDoseRecordId;

  @override
  Widget build(BuildContext context) {
    return _TimelineSection(
      title: 'Protocols',
      child: items.isEmpty
          ? Text(
              'Nothing scheduled.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _ProtocolRow(
                    item: items[index],
                    injectionLog: items[index].record == null
                        ? null
                        : injectionLogsByDoseRecordId[items[index].record!.id],
                  ),
                  if (index < items.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow({required this.item, required this.injectionLog});

  final DailyProtocolItem item;
  final InjectionLog? injectionLog;

  @override
  Widget build(BuildContext context) {
    final color = Color(item.protocol.colorValue);

    final isTaken = item.isTaken;
    final displayedAmount = item.displayedAmount;
    final isSkipped = item.record?.status == DoseRecordStatus.skipped;
    final isMissed = item.record?.status == DoseRecordStatus.missed;

    final statusText = isTaken
        ? item.record?.completedAt == null
              ? 'Taken'
              : 'Taken at ${_formatDateTime(item.record!.completedAt!)}'
        : isSkipped
        ? item.record?.completedAt == null
              ? 'Skipped'
              : 'Skipped at ${_formatDateTime(item.record!.completedAt!)}'
        : isMissed
        ? 'Missed'
        : 'Scheduled for ${_formatDateTime(item.scheduledFor)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isTaken
                        ? Icons.check_circle
                        : isSkipped
                        ? Icons.remove_circle_outline
                        : isMissed
                        ? ArcticIcons.error_outline
                        : Icons.radio_button_unchecked,
                    size: 19,
                    color: isTaken
                        ? const Color(0xFF34C759)
                        : isSkipped
                        ? const Color(0xFFFFA726)
                        : isMissed
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item.protocol.name,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                displayedAmount,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isTaken && injectionLog != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(ArcticIcons.location_on_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        injectionLog!.site.label,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightSection extends StatelessWidget {
  const _WeightSection({required this.record, required this.measurementSystem});

  final WeightRecord? record;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    return _TimelineSection(
      title: 'Weight',
      child: record == null
          ? Text(
              'No weight recorded.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              WeightDisplay.format(record!.weight, measurementSystem),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _NotesSymptomsTab extends StatelessWidget {
  const _NotesSymptomsTab({
    required this.date,
    required this.protocols,
    required this.entries,
    required this.onChanged,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final List<SymptomEntry> entries;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ArcticIcons.notes_outlined, size: 38, color: colors.outline),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'No notes or symptoms',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Log symptoms, severity, and notes for this day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyNotesSymptomsScreen(
                              date: date,
                              protocols: protocols,
                            ),
                          ),
                        );

                        await onChanged();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Symptom'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${entries.length} ${entries.length == 1 ? 'symptom' : 'symptoms'} logged',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyNotesSymptomsScreen(
                          date: date,
                          protocols: protocols,
                        ),
                      ),
                    );

                    await onChanged();
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = entries[index];

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
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
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.sessions,
    required this.photosBySessionId,
    required this.measurementSystem,
    required this.onOpenSession,
  });

  final List<ProgressPhotoSession> sessions;
  final Map<String, List<ProgressPhoto>> photosBySessionId;
  final MeasurementSystem measurementSystem;
  final Future<void> Function(ProgressPhotoSession session) onOpenSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ArcticIcons.photo_library_outlined,
                size: 38,
                color: colors.outline,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'No progress photos',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Progress photo sessions from this day will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final photos = photosBySessionId[session.id] ?? const [];

        return InkWell(
          onTap: () {
            onOpenSession(session);
          },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: _PhotoPreviewStack(photos: photos),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress Photo Session',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (session.weight != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          WeightDisplay.format(
                            session.weight!,
                            measurementSystem,
                          ),
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPreviewStack extends StatelessWidget {
  const _PhotoPreviewStack({required this.photos});

  final List<ProgressPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (photos.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        alignment: Alignment.center,
        child: Icon(ArcticIcons.photo_outlined, color: colors.onSurfaceVariant),
      );
    }

    final photo = photos.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Image.file(
        File(photo.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            color: colors.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              ArcticIcons.broken_image_outlined,
              color: colors.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}

class _HistoricalDoseResult {
  const _HistoricalDoseResult({
    required this.protocol,
    required this.actualAmount,
    required this.time,
  });

  final Protocol protocol;
  final String actualAmount;
  final TimeOfDay time;
}

class _HistoricalDoseSheet extends StatefulWidget {
  const _HistoricalDoseSheet({required this.date, required this.protocols});

  final DateTime date;
  final List<Protocol> protocols;

  @override
  State<_HistoricalDoseSheet> createState() => _HistoricalDoseSheetState();
}

class _HistoricalDoseSheetState extends State<_HistoricalDoseSheet> {
  late Protocol _selectedProtocol;
  late final TextEditingController _doseController;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();

    _selectedProtocol = widget.protocols.first;
    _doseController = TextEditingController(text: _selectedProtocol.dose);
    _time = TimeOfDay(
      hour: _selectedProtocol.schedule.hour,
      minute: _selectedProtocol.schedule.minute,
    );
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _time = selected;
    });
  }

  void _save() {
    final amount = _doseController.text.trim();

    if (amount.isEmpty || RegExp(r'[0-9]').hasMatch(amount) == false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the dose taken.')));
      return;
    }

    Navigator.pop(
      context,
      _HistoricalDoseResult(
        protocol: _selectedProtocol,
        actualAmount: amount,
        time: _time,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Historical Dose',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Record what was actually taken on this date. This does not '
              'change the protocol\'s current schedule.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<Protocol>(
              initialValue: _selectedProtocol,
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final protocol in widget.protocols)
                  DropdownMenuItem(value: protocol, child: Text(protocol.name)),
              ],
              onChanged: (protocol) {
                if (protocol == null) {
                  return;
                }

                setState(() {
                  _selectedProtocol = protocol;
                  _doseController.text = protocol.dose;
                  _time = TimeOfDay(
                    hour: protocol.schedule.hour,
                    minute: protocol.schedule.minute,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _doseController,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Dose taken',
                hintText: '1 mg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _chooseTime,
              icon: const Icon(ArcticIcons.schedule_outlined),
              label: Text(_formatHistoricalTime(_time)),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add),
                label: const Text('Add Dose'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatHistoricalTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

String _weekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  return weekdays[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}

String _formatDateTime(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');

  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}
