import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../models/symptom_entry.dart';
import '../services/symptom_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import 'symptom_history_screen.dart';
import '../theme/arctic_icons.dart';

class DailyNotesSymptomsScreen extends StatefulWidget {
  const DailyNotesSymptomsScreen({
    required this.date,
    required this.protocols,
    super.key,
  });

  final DateTime date;
  final List<Protocol> protocols;

  @override
  State<DailyNotesSymptomsScreen> createState() =>
      _DailyNotesSymptomsScreenState();
}

class _DailyNotesSymptomsScreenState extends State<DailyNotesSymptomsScreen> {
  final SymptomService _symptomService = SymptomService();

  late DateTime _selectedDate;

  List<SymptomEntry> _entries = [];
  Map<String, List<String>> _protocolIdsByEntryId = {};

  bool _isLoading = true;
  String? _loadError;

  static const List<String> _defaultSymptoms = [
    'Fatigue',
    'Nausea',
    'Headache',
    'Dizziness',
    'Constipation',
    'Diarrhea',
    'Bloating',
    'Heartburn',
    'Injection Site Reaction',
    'Appetite Increase',
    'Appetite Suppression',
    'Sleep Issues',
    'Body Aches',
    'Chills',
    'Sweating',
  ];

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final entries = await _symptomService.getEntriesForDate(_selectedDate);

      entries.sort(
        (first, second) => first.symptomName.toLowerCase().compareTo(
          second.symptomName.toLowerCase(),
        ),
      );

      final links = await _symptomService.getProtocolIdsForEntries(
        entries.map((entry) => entry.id).toList(growable: false),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _protocolIdsByEntryId = links;
        _isLoading = false;
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

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) {
      return;
    }

    final normalizedDate = DateTime(
      selected.year,
      selected.month,
      selected.day,
    );

    if (normalizedDate == _selectedDate) {
      return;
    }

    setState(() {
      _selectedDate = normalizedDate;
    });

    await _loadEntries();
  }

  Future<void> _addEntries() async {
    final results = await showModalBottomSheet<List<_SymptomEditorResult>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _MultiSymptomEditorSheet(
        date: _selectedDate,
        protocols: widget.protocols,
        existingEntries: _entries,
        defaultSymptoms: _defaultSymptoms,
      ),
    );

    if (results == null || results.isEmpty || !mounted) {
      return;
    }

    try {
      for (final result in results) {
        await _symptomService.createEntry(
          symptomName: result.symptomName,
          severity: result.severity,
          recordedAt: result.recordedAt,
          notes: result.notes,
          protocolIds: result.protocolIds,
        );
      }

      UsageAnalyticsService.instance.track(
        UsageAnalyticsEvent.symptomLogged,
        properties: {
          'entry_count': results.length,
        },
      );

      if (!mounted) {
        return;
      }

      await _loadEntries();
    } catch (error) {
      _showError('Could not save symptoms', error);
    }
  }

  Future<void> _editEntry(SymptomEntry entry) async {
    final existingProtocolIds = await _symptomService.getProtocolIdsForEntry(
      entry.id,
    );

    if (!mounted) {
      return;
    }

    final result = await showModalBottomSheet<_SymptomEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SingleSymptomEditorSheet(
        date: _selectedDate,
        protocols: widget.protocols,
        entry: entry,
        initialProtocolIds: existingProtocolIds,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await _symptomService.updateEntry(
        entry.copyWith(
          symptomName: result.symptomName,
          severity: result.severity,
          recordedAt: result.recordedAt,
          notes: result.notes,
        ),
        protocolIds: result.protocolIds,
      );

      if (!mounted) {
        return;
      }

      await _loadEntries();
    } catch (error) {
      _showError('Could not update symptom', error);
    }
  }

  Future<void> _deleteEntry(SymptomEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete symptom?'),
          content: Text('Delete ${entry.symptomName} from this day?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _symptomService.deleteEntry(entry.id);

      if (!mounted) {
        return;
      }

      await _loadEntries();
    } catch (error) {
      _showError('Could not delete symptom', error);
    }
  }

  List<Protocol> _protocolsForEntry(SymptomEntry entry) {
    final ids = _protocolIdsByEntryId[entry.id] ?? const <String>[];
    final idSet = ids.toSet();

    return widget.protocols
        .where((protocol) => idSet.contains(protocol.id))
        .toList(growable: false);
  }

  void _showError(String message, Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Symptoms'),
        actions: [
          IconButton(
            tooltip: 'Symptom history',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const SymptomHistoryScreen()),
              );

              if (!mounted) {
                return;
              }

              await _loadEntries();
            },
            icon: const Icon(ArcticIcons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Log symptoms',
            onPressed: _addEntries,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEntries,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              40,
            ),
            children: [
              _DateHeader(date: _selectedDate, onTap: _chooseDate),
              const SizedBox(height: AppSpacing.lg),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _ErrorState(onRetry: _loadEntries)
              else if (_entries.isEmpty)
                _EmptyState(onAdd: _addEntries)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_entries.length} '
                        '${_entries.length == 1 ? 'symptom' : 'symptoms'} logged',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addEntries,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var index = 0; index < _entries.length; index++) ...[
                  _SymptomCard(
                    entry: _entries[index],
                    protocols: _protocolsForEntry(_entries[index]),
                    onTap: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymptomHistoryScreen(
                            initialSymptom: _entries[index].symptomName,
                          ),
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await _loadEntries();
                    },
                    onEdit: () {
                      _editEntry(_entries[index]);
                    },
                    onDelete: () {
                      _deleteEntry(_entries[index]);
                    },
                  ),
                  if (index < _entries.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(ArcticIcons.event_note_outlined, color: colors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily log',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change date',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 18, color: colors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.entry,
    required this.protocols,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SymptomEntry entry;
  final List<Protocol> protocols;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.symptomName,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SeverityBadge(severity: entry.severity),
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<String>(
                  tooltip: 'Symptom options',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(ArcticIcons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(ArcticIcons.delete_outline),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (protocols.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final protocol in protocols)
                    _ProtocolChip(protocol: protocol),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No protocol association',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (entry.notes != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.notes!,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatTime(entry.recordedAt),
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
}

class _ProtocolChip extends StatelessWidget {
  const _ProtocolChip({required this.protocol});

  final Protocol protocol;

  @override
  Widget build(BuildContext context) {
    final color = Color(protocol.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        protocol.name,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$severity/5',
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w800,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(ArcticIcons.notes_outlined, size: 52, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Nothing logged yet',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Log one or more symptoms, severity, notes, and protocol associations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Log Symptoms'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(ArcticIcons.error_outline, size: 48),
          const SizedBox(height: AppSpacing.md),
          const Text('Could not load symptoms.'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _MultiSymptomEditorSheet extends StatefulWidget {
  const _MultiSymptomEditorSheet({
    required this.date,
    required this.protocols,
    required this.existingEntries,
    required this.defaultSymptoms,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final List<SymptomEntry> existingEntries;
  final List<String> defaultSymptoms;

  @override
  State<_MultiSymptomEditorSheet> createState() =>
      _MultiSymptomEditorSheetState();
}

class _MultiSymptomEditorSheetState extends State<_MultiSymptomEditorSheet> {
  final TextEditingController _customSymptomController =
      TextEditingController();

  late DateTime _recordedAt;

  final Map<String, _DraftSymptom> _drafts = {};
  final List<String> _customSymptoms = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _recordedAt = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void dispose() {
    _customSymptomController.dispose();
    super.dispose();
  }

  List<String> get _availableDefaultSymptoms {
    final existingNames = widget.existingEntries
        .map((entry) => entry.symptomName.toLowerCase())
        .toSet();

    return widget.defaultSymptoms
        .where((symptom) => !existingNames.contains(symptom.toLowerCase()))
        .toList(growable: false);
  }

  bool _isSelected(String symptom) => _drafts.containsKey(symptom);

  void _toggleSymptom(String symptom, bool selected) {
    setState(() {
      if (selected) {
        _drafts.putIfAbsent(symptom, () => _DraftSymptom(symptomName: symptom));
      } else {
        _drafts.remove(symptom);
      }
    });
  }

  void _addCustomSymptom() {
    final name = _customSymptomController.text.trim();

    if (name.isEmpty) {
      return;
    }

    final alreadyLogged = widget.existingEntries.any(
      (entry) => entry.symptomName.toLowerCase() == name.toLowerCase(),
    );

    final alreadyAvailable = _availableDefaultSymptoms.any(
      (symptom) => symptom.toLowerCase() == name.toLowerCase(),
    );

    final alreadyCustom = _customSymptoms.any(
      (symptom) => symptom.toLowerCase() == name.toLowerCase(),
    );

    if (alreadyLogged || alreadyAvailable || alreadyCustom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That symptom is already available or already logged.'),
        ),
      );
      return;
    }

    setState(() {
      _customSymptoms.add(name);
      _drafts[name] = _DraftSymptom(symptomName: name);
      _customSymptomController.clear();
    });
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _save() {
    if (_drafts.isEmpty) {
      return;
    }

    final results = _drafts.values
        .map(
          (draft) => _SymptomEditorResult(
            symptomName: draft.symptomName,
            severity: draft.severity,
            recordedAt: _recordedAt,
            notes: _optionalText(draft.notes),
            protocolIds: draft.protocolIds.toList(growable: false),
          ),
        )
        .toList(growable: false);

    Navigator.pop(context, results);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final symptoms = [..._availableDefaultSymptoms, ..._customSymptoms];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log Symptoms',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select every symptom that applies. Each symptom can have its own severity and protocol association.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _chooseTime,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(ArcticIcons.schedule_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Time • ${_formatTime(_recordedAt)}')),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSymptomController,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addCustomSymptom(),
                    decoration: const InputDecoration(
                      labelText: 'Custom symptom',
                      hintText: 'Example: Dry mouth',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Add custom symptom',
                  onPressed: _addCustomSymptom,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: symptoms.isEmpty
                  ? Center(
                      child: Text(
                        'All common symptoms are already logged for this day. Add a custom symptom if needed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: symptoms.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final symptom = symptoms[index];
                        final selected = _isSelected(symptom);
                        final draft = _drafts[symptom];

                        return _SelectableSymptomCard(
                          symptomName: symptom,
                          selected: selected,
                          draft: draft,
                          protocols: widget.protocols,
                          onSelectedChanged: (value) {
                            _toggleSymptom(symptom, value);
                          },
                          onDraftChanged: () {
                            setState(() {});
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _drafts.isEmpty ? null : _save,
                child: Text(
                  _drafts.isEmpty
                      ? 'Select Symptoms'
                      : 'Save ${_drafts.length} '
                            '${_drafts.length == 1 ? 'Symptom' : 'Symptoms'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableSymptomCard extends StatelessWidget {
  const _SelectableSymptomCard({
    required this.symptomName,
    required this.selected,
    required this.draft,
    required this.protocols,
    required this.onSelectedChanged,
    required this.onDraftChanged,
  });

  final String symptomName;
  final bool selected;
  final _DraftSymptom? draft;
  final List<Protocol> protocols;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.30)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            onChanged: (value) {
              onSelectedChanged(value ?? false);
            },
            title: Text(
              symptomName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
          ),
          if (selected && draft != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Severity',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 4, label: Text('4')),
                      ButtonSegment(value: 5, label: Text('5')),
                    ],
                    selected: {draft!.severity},
                    onSelectionChanged: (selection) {
                      draft!.severity = selection.first;
                      onDraftChanged();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _severityDescription(draft!.severity),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Associated protocols',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Optional. Select the protocol(s) you think may be associated with this symptom.',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (protocols.isEmpty)
                    Text(
                      'No protocols available.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final protocol in protocols)
                          _ProtocolFilterChip(
                            protocol: protocol,
                            selected: draft!.protocolIds.contains(protocol.id),
                            onSelected: (value) {
                              if (value) {
                                draft!.protocolIds.add(protocol.id);
                              } else {
                                draft!.protocolIds.remove(protocol.id);
                              }

                              onDraftChanged();
                            },
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: draft!.notes,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      draft!.notes = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SingleSymptomEditorSheet extends StatefulWidget {
  const _SingleSymptomEditorSheet({
    required this.date,
    required this.protocols,
    required this.entry,
    required this.initialProtocolIds,
  });

  final DateTime date;
  final List<Protocol> protocols;
  final SymptomEntry entry;
  final List<String> initialProtocolIds;

  @override
  State<_SingleSymptomEditorSheet> createState() =>
      _SingleSymptomEditorSheetState();
}

class _SingleSymptomEditorSheetState extends State<_SingleSymptomEditorSheet> {
  late final TextEditingController _symptomController;
  late final TextEditingController _notesController;

  late DateTime _recordedAt;
  late int _severity;
  late Set<String> _protocolIds;

  @override
  void initState() {
    super.initState();

    _symptomController = TextEditingController(text: widget.entry.symptomName);
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _recordedAt = widget.entry.recordedAt;
    _severity = widget.entry.severity;
    _protocolIds = widget.initialProtocolIds.toSet();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave => _symptomController.text.trim().isNotEmpty;

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    Navigator.pop(
      context,
      _SymptomEditorResult(
        symptomName: _symptomController.text.trim(),
        severity: _severity,
        recordedAt: _recordedAt,
        notes: _optionalText(_notesController.text),
        protocolIds: _protocolIds.toList(growable: false),
      ),
    );
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
              'Edit Symptom',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _symptomController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Symptom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Severity',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5')),
              ],
              selected: {_severity},
              onSelectionChanged: (selection) {
                setState(() {
                  _severity = selection.first;
                });
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _severityDescription(_severity),
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Associated protocols',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Optional. This records your association, not a proven cause.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.protocols.isEmpty)
              Text(
                'No protocols available.',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final protocol in widget.protocols)
                    _ProtocolFilterChip(
                      protocol: protocol,
                      selected: _protocolIds.contains(protocol.id),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _protocolIds.add(protocol.id);
                          } else {
                            _protocolIds.remove(protocol.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: _chooseTime,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(ArcticIcons.schedule_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_formatTime(_recordedAt))),
                    const Icon(Icons.chevron_right),
                  ],
                ),
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
                onPressed: _canSave ? _save : null,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolFilterChip extends StatelessWidget {
  const _ProtocolFilterChip({
    required this.protocol,
    required this.selected,
    required this.onSelected,
  });

  final Protocol protocol;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Color(protocol.colorValue);

    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: CircleAvatar(radius: 6, backgroundColor: color),
      label: Text(protocol.name),
    );
  }
}

class _DraftSymptom {
  _DraftSymptom({required this.symptomName, Set<String>? protocolIds})
    : severity = 1,
      protocolIds = protocolIds ?? <String>{},
      notes = '';

  final String symptomName;
  int severity;
  final Set<String> protocolIds;
  String notes;
}

class _SymptomEditorResult {
  const _SymptomEditorResult({
    required this.symptomName,
    required this.severity,
    required this.recordedAt,
    required this.protocolIds,
    this.notes,
  });

  final String symptomName;
  final int severity;
  final DateTime recordedAt;
  final String? notes;
  final List<String> protocolIds;
}

String _severityDescription(int severity) {
  return switch (severity) {
    1 => 'Very mild',
    2 => 'Mild',
    3 => 'Moderate',
    4 => 'Strong',
    5 => 'Severe',
    _ => '',
  };
}

String? _optionalText(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String _formatDate(DateTime date) {
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

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}
