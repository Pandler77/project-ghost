import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../theme/app_theme.dart';

class ProtocolDetailsScreen extends StatefulWidget {
  const ProtocolDetailsScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<ProtocolDetailsScreen> createState() => _ProtocolDetailsScreenState();
}

class _ProtocolDetailsScreenState extends State<ProtocolDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final protocol = widget.protocol;

    return Scaffold(
      appBar: AppBar(title: Text(protocol.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _StatusBanner(status: protocol.status),

            const SizedBox(height: AppSpacing.md),

            _DetailTile(label: 'Dose', value: protocol.dose),

            const Divider(height: AppSpacing.lg),

            _DetailTile(label: 'Schedule', value: _formatSchedule(protocol)),

            const Divider(height: AppSpacing.lg),

            _DetailTile(
              label: 'Start Date',
              value: _formatDate(protocol.schedule.startDate),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (protocol.status == ProtocolStatus.active)
              FilledButton(
                onPressed: () {
                  setState(() {
                    protocol.status = ProtocolStatus.paused;
                  });
                },
                child: const Text('Pause Protocol'),
              )
            else if (protocol.status == ProtocolStatus.paused)
              FilledButton(
                onPressed: () {
                  setState(() {
                    protocol.status = ProtocolStatus.active;
                  });
                },
                child: const Text('Resume Protocol'),
              )
            else
              OutlinedButton(onPressed: null, child: const Text('Archived')),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(Protocol protocol) {
    final schedule = protocol.schedule;
    final time = _formatTime(schedule.hour, schedule.minute);

    switch (schedule.type.name) {
      case 'daily':
        return 'Daily • $time';

      case 'everyXDays':
        return 'Every ${schedule.intervalDays} days • $time';

      default:
        return time;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(int hour, int minute) {
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final formattedMinute = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:$formattedMinute $period';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ProtocolStatus status;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (status) {
      ProtocolStatus.active => Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.10),
      ProtocolStatus.paused => Colors.amber.withValues(alpha: 0.14),
      ProtocolStatus.archived => Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest,
    };

    final text = switch (status) {
      ProtocolStatus.active => 'Active',
      ProtocolStatus.paused => 'Paused',
      ProtocolStatus.archived => 'Archived',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
