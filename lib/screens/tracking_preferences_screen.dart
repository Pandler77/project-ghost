import 'package:flutter/material.dart';

import '../models/tracking_preferences.dart';
import '../theme/app_theme.dart';

class TrackingPreferencesScreen extends StatefulWidget {
  const TrackingPreferencesScreen({
    required this.initialPreferences,
    super.key,
  });

  final TrackingPreferences initialPreferences;

  @override
  State<TrackingPreferencesScreen> createState() =>
      _TrackingPreferencesScreenState();
}

class _TrackingPreferencesScreenState extends State<TrackingPreferencesScreen> {
  late TrackingPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  void _save() {
    Navigator.pop(context, _preferences);
  }

  void _updatePreferences(TrackingPreferences preferences) {
    setState(() {
      _preferences = preferences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Preferences'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SectionHeader(title: 'Features'),
            const SizedBox(height: AppSpacing.sm),
            const Card(
              child: ListTile(
                leading: Icon(Icons.medication_outlined),
                title: Text('Protocols'),
                subtitle: Text('Core protocol and dose tracking.'),
                trailing: Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Weight'),
                subtitle: const Text('Track weight and progress trends.'),
                value: _preferences.trackWeight,
                onChanged: (value) {
                  _updatePreferences(_preferences.copyWith(trackWeight: value));
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.photo_camera_outlined),
                title: const Text('Progress Photos'),
                subtitle: const Text('Organize progress photos by date.'),
                value: _preferences.trackPhotos,
                onChanged: (value) {
                  _updatePreferences(_preferences.copyWith(trackPhotos: value));
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.notes_outlined),
                title: const Text('Notes & Symptoms'),
                subtitle: const Text('Record notes and side effects.'),
                value: _preferences.trackNotes,
                onChanged: (value) {
                  _updatePreferences(_preferences.copyWith(trackNotes: value));
                },
              ),
            ),
            if (_preferences.trackWeight || _preferences.trackPhotos) ...[
              const SizedBox(height: AppSpacing.lg),
              const _SectionHeader(title: 'Frequency'),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_preferences.trackWeight)
              _FrequencyCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Weight',
                value: _preferences.weightFrequency,
                onChanged: (frequency) {
                  _updatePreferences(
                    _preferences.copyWith(weightFrequency: frequency),
                  );
                },
              ),
            if (_preferences.trackWeight && _preferences.trackPhotos)
              const SizedBox(height: AppSpacing.sm),
            if (_preferences.trackPhotos)
              _FrequencyCard(
                icon: Icons.photo_camera_outlined,
                title: 'Progress Photos',
                value: _preferences.photoFrequency,
                onChanged: (frequency) {
                  _updatePreferences(
                    _preferences.copyWith(photoFrequency: frequency),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTypography.title,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final TrackingFrequency value;
  final ValueChanged<TrackingFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<TrackingFrequency>(
              segments: const [
                ButtonSegment(
                  value: TrackingFrequency.daily,
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: TrackingFrequency.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: TrackingFrequency.monthly,
                  label: Text('Monthly'),
                ),
              ],
              selected: {value},
              onSelectionChanged: (selection) {
                onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
