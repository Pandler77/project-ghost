import 'package:flutter/material.dart';

import '../models/tracking_preferences.dart';
import '../theme/app_theme.dart';

class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({required this.onComplete, super.key});

  final Future<void> Function(TrackingPreferences preferences) onComplete;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  final PageController _pageController = PageController();

  TrackingPreferences _preferences = TrackingPreferences.defaults;

  int _currentPage = 0;
  bool _isSaving = false;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage == _pageCount - 1) {
      await _finishSetup();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previousPage() async {
    if (_currentPage == 0) {
      Navigator.pop(context);
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishSetup() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onComplete(_preferences);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updatePreferences(TrackingPreferences preferences) {
    setState(() {
      _preferences = preferences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              currentPage: _currentPage,
              pageCount: _pageCount,
              onBack: _previousPage,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _TrackingSelectionPage(
                    preferences: _preferences,
                    onChanged: _updatePreferences,
                  ),
                  _CustomizeTrackingPage(
                    preferences: _preferences,
                    onChanged: _updatePreferences,
                  ),
                  _FinishSetupPage(preferences: _preferences),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _nextPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentPage == _pageCount - 1
                                ? 'Start Tracking'
                                : 'Continue',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentPage,
    required this.pageCount,
    required this.onBack,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          const Spacer(),
          Row(
            children: [
              for (var index = 0; index < pageCount; index++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == currentPage ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == currentPage
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TrackingSelectionPage extends StatelessWidget {
  const _TrackingSelectionPage({
    required this.preferences,
    required this.onChanged,
  });

  final TrackingPreferences preferences;
  final ValueChanged<TrackingPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      icon: Icons.tune_outlined,
      title: 'Let’s personalize your tracker.',
      subtitle: 'Choose what you want Ghost to keep track of.',
      children: [
        const _LockedTrackingTile(
          icon: Icons.medication_outlined,
          title: 'Protocols',
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: Icons.monitor_weight_outlined,
          title: 'Weight',
          value: preferences.trackWeight,
          onChanged: (value) {
            onChanged(preferences.copyWith(trackWeight: value));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: Icons.photo_camera_outlined,
          title: 'Progress Photos',
          value: preferences.trackPhotos,
          onChanged: (value) {
            onChanged(preferences.copyWith(trackPhotos: value));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: Icons.notes_outlined,
          title: 'Notes & Symptoms',
          value: preferences.trackNotes,
          onChanged: (value) {
            onChanged(preferences.copyWith(trackNotes: value));
          },
        ),
      ],
    );
  }
}

class _CustomizeTrackingPage extends StatelessWidget {
  const _CustomizeTrackingPage({
    required this.preferences,
    required this.onChanged,
  });

  final TrackingPreferences preferences;
  final ValueChanged<TrackingPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasOptionalTracking =
        preferences.trackWeight ||
        preferences.trackPhotos ||
        preferences.trackNotes;

    return _OnboardingPageLayout(
      icon: Icons.settings_suggest_outlined,
      title: 'Customize your routine.',
      subtitle: hasOptionalTracking
          ? 'Choose how often you want to check in.'
          : 'You can enable more tracking options later in Settings.',
      children: [
        if (!hasOptionalTracking) const _NothingSelectedCard(),

        if (preferences.trackWeight) ...[
          _FrequencyCard(
            icon: Icons.monitor_weight_outlined,
            title: 'Weight',
            subtitle: 'How often do you plan to weigh in?',
            value: preferences.weightFrequency,
            onChanged: (frequency) {
              onChanged(preferences.copyWith(weightFrequency: frequency));
            },
          ),
        ],

        if (preferences.trackWeight && preferences.trackPhotos)
          const SizedBox(height: AppSpacing.md),

        if (preferences.trackPhotos) ...[
          _FrequencyCard(
            icon: Icons.photo_camera_outlined,
            title: 'Progress Photos',
            subtitle: 'How often do you want new photos?',
            value: preferences.photoFrequency,
            onChanged: (frequency) {
              onChanged(preferences.copyWith(photoFrequency: frequency));
            },
          ),
        ],

        if ((preferences.trackWeight || preferences.trackPhotos) &&
            preferences.trackNotes)
          const SizedBox(height: AppSpacing.md),

        if (preferences.trackNotes)
          const _EnabledTrackingCard(
            icon: Icons.notes_outlined,
            title: 'Notes & Symptoms',
            subtitle: 'Add notes whenever you need them.',
          ),
      ],
    );
  }
}

class _FinishSetupPage extends StatelessWidget {
  const _FinishSetupPage({required this.preferences});

  final TrackingPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      icon: Icons.check_circle_outline,
      title: 'You’re all set.',
      subtitle: 'Your tracker is ready. You can change these choices anytime.',
      children: [
        const _SummaryRow(
          icon: Icons.medication_outlined,
          title: 'Protocols',
          value: 'Enabled',
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(
          icon: Icons.monitor_weight_outlined,
          title: 'Weight',
          value: preferences.trackWeight
              ? _frequencyLabel(preferences.weightFrequency)
              : 'Off',
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(
          icon: Icons.photo_camera_outlined,
          title: 'Progress Photos',
          value: preferences.trackPhotos
              ? _frequencyLabel(preferences.photoFrequency)
              : 'Off',
        ),
        const SizedBox(height: AppSpacing.md),
        _SummaryRow(
          icon: Icons.notes_outlined,
          title: 'Notes & Symptoms',
          value: preferences.trackNotes ? 'Enabled' : 'Off',
        ),
      ],
    );
  }
}

class _OnboardingPageLayout extends StatelessWidget {
  const _OnboardingPageLayout({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTypography.body,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _LockedTrackingTile extends StatelessWidget {
  const _LockedTrackingTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.check_circle, color: colorScheme.primary),
      ),
    );
  }
}

class _TrackingSwitchTile extends StatelessWidget {
  const _TrackingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final TrackingFrequency value;
  final ValueChanged<TrackingFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            _FrequencySelector(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _EnabledTrackingCard extends StatelessWidget {
  const _EnabledTrackingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.check_circle, color: colorScheme.primary),
      ),
    );
  }
}

class _NothingSelectedCard extends StatelessWidget {
  const _NothingSelectedCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Protocols will still be available. You can turn on weight, photos, or notes later.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.value, required this.onChanged});

  final TrackingFrequency value;
  final ValueChanged<TrackingFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrackingFrequency>(
      segments: const [
        ButtonSegment(value: TrackingFrequency.daily, label: Text('Daily')),
        ButtonSegment(value: TrackingFrequency.weekly, label: Text('Weekly')),
        ButtonSegment(value: TrackingFrequency.monthly, label: Text('Monthly')),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 21, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

String _frequencyLabel(TrackingFrequency frequency) {
  return switch (frequency) {
    TrackingFrequency.daily => 'Daily',
    TrackingFrequency.weekly => 'Weekly',
    TrackingFrequency.monthly => 'Monthly',
  };
}
