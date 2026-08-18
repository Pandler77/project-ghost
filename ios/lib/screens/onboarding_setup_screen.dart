import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/profile.dart';
import '../models/tracking_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/arctic_icons.dart';

class OnboardingSetupResult {
  const OnboardingSetupResult({
    required this.profileName,
    required this.profileType,
    required this.preferences,
    required this.heightCm,
    required this.measurementSystem,
  });

  final String profileName;
  final ProfileType profileType;
  final TrackingPreferences preferences;
  final double heightCm;
  final MeasurementSystem measurementSystem;
}

class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    required this.onComplete,
    required this.onBackToWelcome,
    super.key,
  });

  final Future<void> Function(OnboardingSetupResult result) onComplete;
  final VoidCallback onBackToWelcome;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  final PageController _pageController = PageController();

  late final TextEditingController _profileNameController;
  late final TextEditingController _heightFeetController;
  late final TextEditingController _heightInchesController;
  late final TextEditingController _heightCmController;

  TrackingPreferences _preferences = TrackingPreferences.defaults;
  ProfileType _profileType = ProfileType.self;
  MeasurementSystem _measurementSystem = MeasurementSystem.imperial;

  int _currentPage = 0;
  bool _isSaving = false;

  static const int _pageCount = 4;

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();

    _profileNameController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _heightCmController = TextEditingController();
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _heightCmController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  double? get _heightCm {
    if (_measurementSystem == MeasurementSystem.metric) {
      final value = double.tryParse(_heightCmController.text.trim());

      if (value == null || value <= 0) {
        return null;
      }

      return value;
    }

    final feet = int.tryParse(_heightFeetController.text.trim());
    final inches = int.tryParse(_heightInchesController.text.trim()) ?? 0;

    if (feet == null || feet <= 0 || inches < 0 || inches >= 12) {
      return null;
    }

    return ((feet * 12) + inches) * 2.54;
  }

  Future<void> _nextPage() async {
    _dismissKeyboard();

    if (_currentPage == 0) {
      if (_profileNameController.text.trim().isEmpty) {
        _showMessage('Profile name is required.');
        return;
      }

      if (_heightCm == null) {
        _showMessage(
          _measurementSystem == MeasurementSystem.imperial
              ? 'Enter a valid height in feet and inches.'
              : 'Enter a valid height in centimeters.',
        );
        return;
      }
    }

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
    _dismissKeyboard();

    if (_currentPage == 0) {
      widget.onBackToWelcome();
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishSetup() async {
    _dismissKeyboard();

    if (_isSaving) {
      return;
    }

    final profileName = _profileNameController.text.trim();
    final heightCm = _heightCm;

    if (profileName.isEmpty || heightCm == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onComplete(
        OnboardingSetupResult(
          profileName: profileName,
          profileType: _profileType,
          preferences: _preferences,
          heightCm: heightCm,
          measurementSystem: _measurementSystem,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _updatePreferences(TrackingPreferences preferences) {
    setState(() {
      _preferences = preferences;
    });
  }

  void _setMeasurementSystem(MeasurementSystem system) {
    if (_measurementSystem == system) {
      return;
    }

    final currentHeightCm = _heightCm;

    setState(() {
      _measurementSystem = system;

      if (currentHeightCm == null) {
        return;
      }

      if (system == MeasurementSystem.metric) {
        _heightCmController.text = currentHeightCm.toStringAsFixed(1);
      } else {
        final totalInches = currentHeightCm / 2.54;
        final feet = totalInches ~/ 12;
        final inches = (totalInches - (feet * 12)).round().clamp(0, 11);

        _heightFeetController.text = feet.toString();
        _heightInchesController.text = inches.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                  _dismissKeyboard();

                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _ProfileSetupPage(
                    nameController: _profileNameController,
                    selectedType: _profileType,
                    onTypeChanged: (type) {
                      setState(() {
                        _profileType = type;
                      });
                    },
                    measurementSystem: _measurementSystem,
                    onMeasurementSystemChanged: _setMeasurementSystem,
                    heightFeetController: _heightFeetController,
                    heightInchesController: _heightInchesController,
                    heightCmController: _heightCmController,
                  ),
                  _TrackingSelectionPage(
                    preferences: _preferences,
                    onChanged: _updatePreferences,
                  ),
                  _CustomizeTrackingPage(
                    preferences: _preferences,
                    onChanged: _updatePreferences,
                  ),
                  _FinishSetupPage(
                    profileNameController: _profileNameController,
                    profileType: _profileType,
                    preferences: _preferences,
                    measurementSystem: _measurementSystem,
                    heightCm: _heightCm,
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _nextPage,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
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
                          style: const TextStyle(
                            fontSize: AppTypography.primary,
                            fontWeight: FontWeight.w800,
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
    final colors = Theme.of(context).colorScheme;
    final progress = (currentPage + 1) / pageCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SETUP',
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                        color: colors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currentPage + 1} / $pageCount',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: colors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSetupPage extends StatelessWidget {
  const _ProfileSetupPage({
    required this.nameController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.measurementSystem,
    required this.onMeasurementSystemChanged,
    required this.heightFeetController,
    required this.heightInchesController,
    required this.heightCmController,
  });

  final TextEditingController nameController;
  final ProfileType selectedType;
  final ValueChanged<ProfileType> onTypeChanged;

  final MeasurementSystem measurementSystem;
  final ValueChanged<MeasurementSystem> onMeasurementSystemChanged;

  final TextEditingController heightFeetController;
  final TextEditingController heightInchesController;
  final TextEditingController heightCmController;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageLayout(
      eyebrow: 'YOUR PROFILE',
      icon: ArcticIcons.person_outline_rounded,
      title: 'Set up your profile.',
      subtitle:
          'ArcticDose uses your profile to keep protocols, progress, inventory, and history organized.',
      children: [
        const _FieldLabel(
          title: 'Profile name',
          subtitle: 'This is how ArcticDose will address this profile.',
        ),
        const SizedBox(height: AppSpacing.sm),

        TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Name',
            prefixIcon: Icon(ArcticIcons.person_outline_rounded),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        const _FieldLabel(
          title: 'Profile type',
          subtitle: 'Choose who this profile belongs to.',
        ),
        const SizedBox(height: AppSpacing.sm),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (
                var index = 0;
                index < ProfileType.values.length;
                index++
              ) ...[
                _ProfileTypeChip(
                  type: ProfileType.values[index],
                  selected: selectedType == ProfileType.values[index],
                  onTap: () => onTypeChanged(ProfileType.values[index]),
                ),
                if (index < ProfileType.values.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        const _FieldLabel(
          title: 'Height',
          subtitle:
              'Used for BMI and future body-composition insights. Stored internally in centimeters.',
        ),
        const SizedBox(height: AppSpacing.sm),

        _MeasurementToggle(
          value: measurementSystem,
          onChanged: onMeasurementSystemChanged,
        ),

        const SizedBox(height: AppSpacing.md),

        if (measurementSystem == MeasurementSystem.imperial)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: heightFeetController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Feet',
                    hintText: '6',
                    suffixText: 'ft',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: heightInchesController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Inches',
                    hintText: '0',
                    suffixText: 'in',
                  ),
                ),
              ),
            ],
          )
        else
          TextField(
            controller: heightCmController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Height',
              hintText: '180',
              suffixText: 'cm',
            ),
          ),
      ],
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
      eyebrow: 'TRACKING',
      icon: ArcticIcons.tune_rounded,
      title: 'Choose what matters.',
      subtitle:
          'Protocols are always available. Turn on the additional tracking you want to use.',
      children: [
        const _LockedTrackingTile(
          icon: ArcticIcons.medication_outlined,
          title: 'Protocols',
          subtitle: 'Schedules, doses, cycles, reminders, and history.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: ArcticIcons.monitor_weight_outlined,
          title: 'Weight',
          subtitle: 'Track weight history, trends, and BMI.',
          value: preferences.trackWeight,
          onChanged: (value) {
            onChanged(preferences.copyWith(trackWeight: value));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: ArcticIcons.photo_camera_outlined,
          title: 'Progress Photos',
          subtitle: 'Build visual progress sessions over time.',
          value: preferences.trackPhotos,
          onChanged: (value) {
            onChanged(preferences.copyWith(trackPhotos: value));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _TrackingSwitchTile(
          icon: ArcticIcons.notes_outlined,
          title: 'Notes & Symptoms',
          subtitle: 'Log symptoms, notes, and protocol-related observations.',
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
      eyebrow: 'ROUTINE',
      icon: ArcticIcons.calendar_month_outlined,
      title: 'Build your routine.',
      subtitle: hasOptionalTracking
          ? 'Set a simple check-in cadence. You can change it later.'
          : 'Protocols are ready. Additional tracking can be enabled later in Settings.',
      children: [
        if (!hasOptionalTracking) const _NothingSelectedCard(),

        if (preferences.trackWeight)
          _FrequencyCard(
            icon: ArcticIcons.monitor_weight_outlined,
            title: 'Weight',
            subtitle: 'How often do you plan to weigh in?',
            value: preferences.weightFrequency,
            onChanged: (frequency) {
              onChanged(preferences.copyWith(weightFrequency: frequency));
            },
          ),

        if (preferences.trackWeight && preferences.trackPhotos)
          const SizedBox(height: AppSpacing.md),

        if (preferences.trackPhotos)
          _FrequencyCard(
            icon: ArcticIcons.photo_camera_outlined,
            title: 'Progress Photos',
            subtitle: 'How often do you want a new progress session?',
            value: preferences.photoFrequency,
            onChanged: (frequency) {
              onChanged(preferences.copyWith(photoFrequency: frequency));
            },
          ),

        if ((preferences.trackWeight || preferences.trackPhotos) &&
            preferences.trackNotes)
          const SizedBox(height: AppSpacing.md),

        if (preferences.trackNotes)
          const _EnabledTrackingCard(
            icon: ArcticIcons.notes_outlined,
            title: 'Notes & Symptoms',
            subtitle: 'Log these whenever you need them.',
          ),
      ],
    );
  }
}

class _FinishSetupPage extends StatelessWidget {
  const _FinishSetupPage({
    required this.profileNameController,
    required this.profileType,
    required this.preferences,
    required this.measurementSystem,
    required this.heightCm,
  });

  final TextEditingController profileNameController;
  final ProfileType profileType;
  final TrackingPreferences preferences;
  final MeasurementSystem measurementSystem;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    final profileName = profileNameController.text.trim();

    return _OnboardingPageLayout(
      eyebrow: 'READY',
      icon: Icons.check_rounded,
      title: 'ArcticDose is ready.',
      subtitle:
          'Review your setup. Everything here can be changed later from Settings.',
      children: [
        _SummaryCard(
          children: [
            _SummaryRow(
              icon: _profileTypeIcon(profileType),
              title: 'Profile',
              value: profileName.isEmpty ? 'Not set' : profileName,
            ),
            const _SummaryDivider(),
            _SummaryRow(
              icon: ArcticIcons.height_rounded,
              title: 'Height',
              value: _heightLabel(heightCm, measurementSystem),
            ),
            const _SummaryDivider(),
            const _SummaryRow(
              icon: ArcticIcons.medication_outlined,
              title: 'Protocols',
              value: 'Enabled',
            ),
            const _SummaryDivider(),
            _SummaryRow(
              icon: ArcticIcons.monitor_weight_outlined,
              title: 'Weight',
              value: preferences.trackWeight
                  ? _frequencyLabel(preferences.weightFrequency)
                  : 'Off',
            ),
            const _SummaryDivider(),
            _SummaryRow(
              icon: ArcticIcons.photo_camera_outlined,
              title: 'Progress Photos',
              value: preferences.trackPhotos
                  ? _frequencyLabel(preferences.photoFrequency)
                  : 'Off',
            ),
            const _SummaryDivider(),
            _SummaryRow(
              icon: ArcticIcons.notes_outlined,
              title: 'Notes & Symptoms',
              value: preferences.trackNotes ? 'Enabled' : 'Off',
            ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingPageLayout extends StatelessWidget {
  const _OnboardingPageLayout({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(icon, size: AppIcon.lg, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.65,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            subtitle,
            style: TextStyle(
              fontSize: AppTypography.body,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 26),

          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTypography.caption,
            height: 1.35,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MeasurementToggle extends StatelessWidget {
  const _MeasurementToggle({required this.value, required this.onChanged});

  final MeasurementSystem value;
  final ValueChanged<MeasurementSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MeasurementSystem>(
      segments: const [
        ButtonSegment(
          value: MeasurementSystem.imperial,
          label: Text('Imperial'),
        ),
        ButtonSegment(value: MeasurementSystem.metric, label: Text('Metric')),
      ],
      selected: {value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _ProfileTypeChip extends StatelessWidget {
  const _ProfileTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ProfileType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      avatar: Icon(
        _profileTypeIcon(type),
        size: 17,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      label: Text(type.label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      side: BorderSide(
        color: selected
            ? colors.primary.withValues(alpha: 0.65)
            : colors.outlineVariant,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? colors.primary : colors.onSurface,
      ),
    );
  }
}

class _LockedTrackingTile extends StatelessWidget {
  const _LockedTrackingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _TrackingTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Icon(Icons.check_circle_rounded, color: colors.primary),
      emphasized: true,
    );
  }
}

class _TrackingSwitchTile extends StatelessWidget {
  const _TrackingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TrackingTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      emphasized: value,
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}

class _TrackingTileShell extends StatelessWidget {
  const _TrackingTileShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: emphasized
                ? colors.primary.withValues(alpha: 0.07)
                : Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: emphasized
                  ? colors.primary.withValues(alpha: 0.28)
                  : colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: AppIcon.md, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ),
        ),
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: AppIcon.sm, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencySelector(value: value, onChanged: onChanged),
        ],
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
    final colors = Theme.of(context).colorScheme;

    return _TrackingTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      emphasized: true,
      trailing: Icon(Icons.check_circle_rounded, color: colors.primary),
    );
  }
}

class _NothingSelectedCard extends StatelessWidget {
  const _NothingSelectedCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ArcticIcons.info_outline_rounded, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Protocols will still be available. Weight, photos, and notes can be enabled later in Settings.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TrackingFrequency>(
        segments: const [
          ButtonSegment(value: TrackingFrequency.daily, label: Text('Daily')),
          ButtonSegment(value: TrackingFrequency.weekly, label: Text('Weekly')),
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.60),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 58);
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
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: AppIcon.sm, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ],
      ),
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

String _heightLabel(double? heightCm, MeasurementSystem measurementSystem) {
  if (heightCm == null) {
    return 'Not set';
  }

  if (measurementSystem == MeasurementSystem.metric) {
    return '${heightCm.toStringAsFixed(1)} cm';
  }

  final totalInches = heightCm / 2.54;
  final feet = totalInches ~/ 12;
  final inches = (totalInches - (feet * 12)).round();

  return '$feet ft $inches in';
}

IconData _profileTypeIcon(ProfileType type) {
  return switch (type) {
    ProfileType.self => ArcticIcons.person_outline_rounded,
    ProfileType.familyMember => ArcticIcons.people_outline_rounded,
    ProfileType.child => ArcticIcons.child_care_outlined,
    ProfileType.pet => ArcticIcons.pets_outlined,
    ProfileType.other => ArcticIcons.account_circle_outlined,
  };
}
