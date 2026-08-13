import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/dose_record.dart';
import '../models/injection_log.dart';
import '../models/injection_site.dart';
import '../models/protocol.dart';
import '../models/protocol_type.dart';
import '../services/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/completed_dose_sheet.dart';

class DoseHistoryScreen extends StatefulWidget {
  const DoseHistoryScreen({
    required this.dataService,
    required this.protocols,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;

  @override
  State<DoseHistoryScreen> createState() => _DoseHistoryScreenState();
}

class _DoseHistoryScreenState extends State<DoseHistoryScreen> {
  List<DoseRecord> _records = [];
  Map<String, InjectionLog> _injectionLogsByDoseRecordId = {};

  bool _isLoading = true;
  String? _loadError;
  String? _selectedProtocolId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _selectedProtocolId == null
            ? widget.dataService.getAllDoseRecords()
            : widget.dataService.getDoseRecordsForProtocol(
                _selectedProtocolId!,
              ),
        widget.dataService.getAllInjectionLogs(),
      ]);

      final records = results[0] as List<DoseRecord>;
      final injectionLogs = results[1] as List<InjectionLog>;

      final injectionLogsByDoseRecordId = <String, InjectionLog>{
        for (final log in injectionLogs) log.doseRecordId: log,
      };

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        _injectionLogsByDoseRecordId = injectionLogsByDoseRecordId;
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

  String _protocolName(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol.name;
      }
    }

    return 'Unknown Protocol';
  }

  Color _protocolColor(String protocolId) {
    final protocol = _protocolForId(protocolId);

    if (protocol == null) {
      return Theme.of(context).colorScheme.primary;
    }

    return Color(protocol.colorValue);
  }

  Protocol? _protocolForId(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol;
      }
    }

    return null;
  }

  Future<void> _openRecordDetails(DoseRecord record) async {
    final protocol = _protocolForId(record.protocolId);

    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This protocol could not be found.')),
      );
      return;
    }

    final injectionLog = _injectionLogsByDoseRecordId[record.id];

    final dose = Dose(
      protocolId: protocol.id,
      protocolName: protocol.name,
      amount: record.actualAmount ?? record.scheduledAmount,
      scheduledFor: record.scheduledFor,
      protocolColorValue: protocol.colorValue,
      completedAt: record.completedAt,
      injectionSiteLabel: injectionLog?.site.label,
    );

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
      protocolId: record.protocolId,
      scheduledFor: record.scheduledFor,
    );

    if (!mounted) {
      return;
    }

    await _loadRecords();
  }

  Map<DateTime, List<DoseRecord>> _groupRecordsByDate() {
    final grouped = <DateTime, List<DoseRecord>>{};

    for (final record in _records) {
      final date = DateTime(
        record.scheduledFor.year,
        record.scheduledFor.month,
        record.scheduledFor.day,
      );

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(record);
    }

    for (final records in grouped.values) {
      records.sort(
        (first, second) => second.scheduledFor.compareTo(first.scheduledFor),
      );
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedRecords = _groupRecordsByDate();

    final dates = groupedRecords.keys.toList()
      ..sort((first, second) => second.compareTo(first));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dose History',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecords,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              100,
            ),
            children: [
              _HistorySummaryCard(
                recordCount: _records.length,
                selectedProtocolId: _selectedProtocolId,
                protocols: widget.protocols,
                onProtocolChanged: (value) {
                  setState(() {
                    _selectedProtocolId = value;
                  });

                  _loadRecords();
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _HistoryErrorState(error: _loadError!, onRetry: _loadRecords)
              else if (_records.isEmpty)
                const _EmptyHistoryState()
              else
                for (final date in dates) ...[
                  _DateHeader(date: date, count: groupedRecords[date]!.length),

                  const SizedBox(height: AppSpacing.sm),

                  for (
                    var index = 0;
                    index < groupedRecords[date]!.length;
                    index++
                  ) ...[
                    _DoseHistoryRow(
                      record: groupedRecords[date]![index],
                      protocol: _protocolForId(
                        groupedRecords[date]![index].protocolId,
                      ),
                      protocolName: _protocolName(
                        groupedRecords[date]![index].protocolId,
                      ),
                      protocolColor: _protocolColor(
                        groupedRecords[date]![index].protocolId,
                      ),
                      injectionLog:
                          _injectionLogsByDoseRecordId[groupedRecords[date]![index]
                              .id],
                      onDetails: () {
                        return _openRecordDetails(groupedRecords[date]![index]);
                      },
                    ),
                    if (index < groupedRecords[date]!.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.recordCount,
    required this.selectedProtocolId,
    required this.protocols,
    required this.onProtocolChanged,
  });

  final int recordCount;
  final String? selectedProtocolId;
  final List<Protocol> protocols;
  final ValueChanged<String?> onProtocolChanged;

  String _selectedName() {
    if (selectedProtocolId == null) {
      return 'All Protocols';
    }

    for (final protocol in protocols) {
      if (protocol.id == selectedProtocolId) {
        return protocol.name;
      }
    }

    return 'Selected Protocol';
  }

  Future<void> _showProtocolFilter(BuildContext context) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            const Text(
              'Filter Dose History',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: const Text('All Protocols'),
              trailing: selectedProtocolId == null
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                Navigator.pop(context, '__all__');
              },
            ),

            for (final protocol in protocols)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(protocol.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(protocol.name),
                trailing: selectedProtocolId == protocol.id
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context, protocol.id);
                },
              ),
          ],
        );
      },
    );

    if (selected == null) {
      return;
    }

    onProtocolChanged(selected == '__all__' ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final gradientColors = brightness == Brightness.dark
        ? [
            colors.primary.withValues(alpha: 0.28),
            colors.primaryContainer.withValues(alpha: 0.12),
          ]
        : [
            colors.primary.withValues(alpha: 0.15),
            colors.primaryContainer.withValues(alpha: 0.52),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dose History',
            style: TextStyle(
              fontSize: AppTypography.pageTitle,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Review taken, skipped, and missed doses.',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: _HistoryMetric(label: 'RECORDED', value: '$recordCount'),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: _HistoryFilterButton(
                  value: _selectedName(),
                  onTap: () {
                    _showProtocolFilter(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({required this.value, required this.onTap});

  final String value;
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FILTER',
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.tune_rounded, size: 18, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            _formatDateHeading(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoseHistoryRow extends StatelessWidget {
  const _DoseHistoryRow({
    required this.record,
    required this.protocol,
    required this.protocolName,
    required this.protocolColor,
    required this.injectionLog,
    required this.onDetails,
  });

  final DoseRecord record;
  final Protocol? protocol;
  final String protocolName;
  final Color protocolColor;
  final InjectionLog? injectionLog;
  final Future<void> Function() onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final actualAmount = record.actualAmount ?? record.scheduledAmount;
    final amountChanged = actualAmount != record.scheduledAmount;

    final statusColor = _statusColor(context, record.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: record.status == DoseRecordStatus.taken
            ? () async {
                await onDetails();
              }
            : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: protocolColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: protocolColor.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      _statusIcon(record.status),
                      color: statusColor,
                      size: AppIcon.sm,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          protocolName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _recordTimeText(record),
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  _StatusPill(
                    label: _statusLabel(record.status),
                    color: statusColor,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _DoseInfoRow(
                doseLabel: amountChanged ? 'ACTUAL' : 'DOSE',
                doseValue: actualAmount,
                scheduledValue: amountChanged
                    ? record.scheduledAmount
                    : _formatTime(record.scheduledFor),
                scheduledLabel: amountChanged ? 'SCHEDULED' : 'SCHEDULED',
                routeLabel: _routeLabel(),
                routeValue: _routeValue(),
              ),

              if (record.status == DoseRecordStatus.taken) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _routeLabel() {
    if (protocol?.isInjection == true &&
        record.status == DoseRecordStatus.taken &&
        injectionLog != null) {
      return 'SITE';
    }

    return 'ROUTE';
  }

  String _routeValue() {
    if (protocol?.isInjection == true &&
        record.status == DoseRecordStatus.taken &&
        injectionLog != null) {
      return injectionLog!.site.label;
    }

    return protocol?.type.label ?? 'Unknown';
  }

  String _recordTimeText(DoseRecord record) {
    switch (record.status) {
      case DoseRecordStatus.taken:
        final completedAt = record.completedAt;

        if (completedAt == null) {
          return 'Completion time unavailable';
        }

        return 'Taken at ${_formatTime(completedAt)}';

      case DoseRecordStatus.skipped:
        final skippedAt = record.completedAt;

        if (skippedAt == null) {
          return 'Scheduled for ${_formatTime(record.scheduledFor)}';
        }

        return 'Skipped at ${_formatTime(skippedAt)}';

      case DoseRecordStatus.missed:
        return 'Scheduled for ${_formatTime(record.scheduledFor)}';
    }
  }

  String _statusLabel(DoseRecordStatus status) {
    switch (status) {
      case DoseRecordStatus.taken:
        return 'Taken';
      case DoseRecordStatus.skipped:
        return 'Skipped';
      case DoseRecordStatus.missed:
        return 'Missed';
    }
  }

  IconData _statusIcon(DoseRecordStatus status) {
    switch (status) {
      case DoseRecordStatus.taken:
        return Icons.check_rounded;
      case DoseRecordStatus.skipped:
        return Icons.remove_rounded;
      case DoseRecordStatus.missed:
        return Icons.priority_high_rounded;
    }
  }

  Color _statusColor(BuildContext context, DoseRecordStatus status) {
    switch (status) {
      case DoseRecordStatus.taken:
        return Colors.green.shade600;

      case DoseRecordStatus.skipped:
        return Colors.amber.shade700;

      case DoseRecordStatus.missed:
        return Colors.red.shade600;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DoseInfoRow extends StatelessWidget {
  const _DoseInfoRow({
    required this.doseLabel,
    required this.doseValue,
    required this.scheduledLabel,
    required this.scheduledValue,
    required this.routeLabel,
    required this.routeValue,
  });

  final String doseLabel;
  final String doseValue;
  final String scheduledLabel;
  final String scheduledValue;
  final String routeLabel;
  final String routeValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _DoseInfoCell(label: doseLabel, value: doseValue),
          ),
          _DoseInfoDivider(color: colors.outlineVariant),
          Expanded(
            child: _DoseInfoCell(label: scheduledLabel, value: scheduledValue),
          ),
          _DoseInfoDivider(color: colors.outlineVariant),
          Expanded(
            child: _DoseInfoCell(label: routeLabel, value: routeValue),
          ),
        ],
      ),
    );
  }
}

class _DoseInfoCell extends StatelessWidget {
  const _DoseInfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppTypography.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.55,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseInfoDivider extends StatelessWidget {
  const _DoseInfoDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: color.withValues(alpha: 0.55),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(Icons.history_rounded, size: 28, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No dose history yet',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Taken, skipped, and missed doses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.error.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 42, color: colors.error),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not load dose history',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

String _formatDateHeading(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final yesterday = today.subtract(const Duration(days: 1));

  final fullDate = _formatFullDate(date);

  if (_isSameDay(date, today)) {
    return 'Today • $fullDate';
  }

  if (_isSameDay(date, yesterday)) {
    return 'Yesterday • $fullDate';
  }

  return fullDate;
}

String _formatFullDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];

  return '$weekday, $month ${_ordinal(date.day)}, ${date.year}';
}

String _ordinal(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }

  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
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

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
