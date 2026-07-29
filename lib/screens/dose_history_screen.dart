import 'package:flutter/material.dart';

import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../services/app_data_service.dart';
import '../theme/app_theme.dart';

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
      final records = _selectedProtocolId == null
          ? await widget.dataService.getAllDoseRecords()
          : await widget.dataService.getDoseRecordsForProtocol(
              _selectedProtocolId!,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
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
      appBar: AppBar(title: const Text('Dose History')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecords,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Review completed doses and saved history.',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String?>(
                initialValue: _selectedProtocolId,
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Protocols'),
                  ),
                  for (final protocol in widget.protocols)
                    DropdownMenuItem<String?>(
                      value: protocol.id,
                      child: Text(protocol.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProtocolId = value;
                  });

                  _loadRecords();
                },
              ),

              const SizedBox(height: AppSpacing.sm),

              if (!_isLoading && _loadError == null)
                Text(
                  _recordCountText(_records.length),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  _DateHeader(date: date),
                  const SizedBox(height: AppSpacing.sm),

                  for (
                    var index = 0;
                    index < groupedRecords[date]!.length;
                    index++
                  ) ...[
                    _DoseHistoryRow(
                      record: groupedRecords[date]![index],
                      protocolName: _protocolName(
                        groupedRecords[date]![index].protocolId,
                      ),
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

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDateHeading(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(height: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}

class _DoseHistoryRow extends StatelessWidget {
  const _DoseHistoryRow({required this.record, required this.protocolName});

  final DoseRecord record;
  final String protocolName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actualAmount = record.actualAmount ?? record.scheduledAmount;

    final amountChanged = actualAmount != record.scheduledAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor(
                context,
                record.status,
              ).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(record.status),
              color: _statusColor(context, record.status),
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
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                if (amountChanged) ...[
                  Text(
                    'Actual: $actualAmount',
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scheduled: ${record.scheduledAmount}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else
                  Text(
                    actualAmount,
                    style: const TextStyle(
                      fontSize: AppTypography.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  _statusLabel(record.status),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(context, record.status),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _recordTimeText(record),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _recordTimeText(DoseRecord record) {
    switch (record.status) {
      case DoseRecordStatus.taken:
        final completedAt = record.completedAt;

        if (completedAt == null) {
          return 'Completion time unavailable';
        }

        return _formatTime(completedAt);

      case DoseRecordStatus.skipped:
        return 'Scheduled for ${_formatTime(record.scheduledFor)}';

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
        return Icons.check;

      case DoseRecordStatus.skipped:
        return Icons.remove;

      case DoseRecordStatus.missed:
        return Icons.priority_high;
    }
  }

  Color _statusColor(BuildContext context, DoseRecordStatus status) {
    switch (status) {
      case DoseRecordStatus.taken:
        return Theme.of(context).colorScheme.primary;

      case DoseRecordStatus.skipped:
        return Colors.amber.shade700;

      case DoseRecordStatus.missed:
        return Theme.of(context).colorScheme.error;
    }
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No dose history yet',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Completed doses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not load dose history',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

String _recordCountText(int count) {
  if (count == 1) {
    return '1 recorded dose';
  }

  return '$count recorded doses';
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
