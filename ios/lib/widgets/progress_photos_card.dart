import 'package:flutter/material.dart';

import '../models/progress_photo_session.dart';
import '../models/tracking_preferences.dart';
import '../services/progress_photo_schedule_service.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class ProgressPhotosCard extends StatelessWidget {
  const ProgressPhotosCard({
    required this.preferences,
    required this.sessions,
    required this.onOpen,
    required this.onStartSession,
    super.key,
  });

  final TrackingPreferences preferences;
  final List<ProgressPhotoSession> sessions;
  final VoidCallback onOpen;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final status = ProgressPhotoScheduleService().getStatus(
      preferences: preferences,
      sessions: sessions,
    );

    if (!status.isEnabled) {
      return const SizedBox.shrink();
    }

    final frequencyLabel = switch (preferences.photoFrequency) {
      TrackingFrequency.daily => 'Daily',
      TrackingFrequency.weekly => 'Weekly',
      TrackingFrequency.monthly => 'Monthly',
    };

    return Container(
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  ArcticIcons.photo_camera_outlined,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Progress Photos',
                  style: TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (status.lastSession == null) ...[
            Text(
              '$frequencyLabel progress photos are enabled.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No progress session has been logged yet.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartSession,
                icon: const Icon(ArcticIcons.add_a_photo_outlined),
                label: const Text('Start Progress Session'),
              ),
            ),
          ] else if (status.isDue) ...[
            Text(
              '$frequencyLabel progress photos are due.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Front • Side • Back',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartSession,
                icon: const Icon(ArcticIcons.photo_camera_outlined),
                label: const Text('Start Session'),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Current $frequencyLabel session complete',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (status.nextDueDate != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Next due ${_formatDate(status.nextDueDate!)}',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(ArcticIcons.photo_library_outlined),
                label: const Text('View Progress Photos'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
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

  return '${months[value.month - 1]} '
      '${value.day}, ${value.year}';
}
