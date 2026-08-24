import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/app_theme_mode.dart';
import '../models/display_preferences.dart';
import '../models/home_layout.dart';
import '../models/home_section.dart';
import '../models/measurement_system.dart';
import '../models/profile.dart';
import '../models/profile_module.dart';
import '../models/protocol.dart';
import '../models/tracking_preferences.dart';
import '../models/weight_record.dart';
import '../services/app_data_service.dart';
import '../services/missed_dose_reconciliation_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/milestone_celebration_dialog.dart';
import '../widgets/profile_avatar.dart';
import 'calendar_screen.dart';
import 'create_profile_screen.dart';
import 'dashboard_screen.dart';
import 'edit_home_screen.dart';
import 'edit_profile_screen.dart';
import 'premium_screen.dart';
import 'protocols_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    this.notificationProtocolId,
    this.onNotificationHandled,
    super.key,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;
  final String? notificationProtocolId;
  final VoidCallback? onNotificationHandled;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AppDataService _appDataService = AppDataService();
  final SettingsService _settingsService = SettingsService();
  final ProfileService _profileService = ProfileService();

  final MissedDoseReconciliationService _missedDoseReconciliationService =
      const MissedDoseReconciliationService();

  int _selectedIndex = 0;
  int _dataRevision = 0;

  HomeLayout _homeLayout = HomeLayout.defaultLayout;
  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;
  DisplayPreferences _displayPreferences = const DisplayPreferences();
  MeasurementSystem _measurementSystem = MeasurementSystem.imperial;

  List<Protocol> _protocols = [];
  List<Profile> _profiles = [];

  Profile? _activeProfile;

  bool _isLoading = true;
  bool _isSwitchingProfile = false;
  bool _isShowingMilestone = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _initializeApp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation();
    });
  }

  void _handleMeasurementSystemChanged(MeasurementSystem measurementSystem) {
    setState(() {
      _measurementSystem = measurementSystem;
      _dataRevision++;
    });
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.notificationProtocolId != oldWidget.notificationProtocolId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation();
      });
    }
  }

  Future<void> _synchronizeAllProfileNotifications({
    List<Profile>? profilesOverride,
  }) async {
    final profiles = profilesOverride ?? await _profileService.getProfiles();

    final schedules = <ProfileNotificationSchedule>[];

    for (final profile in profiles) {
      final protocols = await _appDataService.getProtocolsForProfile(
        profile.id,
      );

      schedules.add(
        ProfileNotificationSchedule(
          profileId: profile.id,
          profileName: profile.name,
          protocols: protocols,
        ),
      );
    }

    await NotificationService.instance.synchronizeAllProfileReminders(
      schedules,
    );
  }

  Future<void> _showPendingMilestoneIfNeeded() async {
    if (_isShowingMilestone || !mounted) {
      return;
    }

    final profile = _activeProfile;

    if (profile == null) {
      return;
    }

    final enabled = await _settingsService.getCelebrationsEnabled();

    if (!enabled || !mounted) {
      return;
    }

    final milestone = await _settingsService.takePendingMilestone(profile.id);

    if (milestone == null || !mounted) {
      return;
    }

    _isShowingMilestone = true;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MilestoneCelebrationDialog(achievement: milestone),
      );
    } finally {
      _isShowingMilestone = false;
    }

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingMilestoneIfNeeded();
    });
  }

  void _queueMilestoneCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingMilestoneIfNeeded();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final activeProfile = await _profileService.getActiveProfile();
      final profiles = await _profileService.getProfiles();

      final results = await Future.wait<Object>([
        _appDataService.getProtocols(),
        _settingsService.getHomeLayout(),
        _settingsService.getTrackingPreferences(),
        _settingsService.getMeasurementSystem(),
        _settingsService.getDisplayPreferences(),
      ]);

      final protocols = results[0] as List<Protocol>;
      final homeLayout = results[1] as HomeLayout;
      final trackingPreferences = results[2] as TrackingPreferences;
      final measurementSystem = results[3] as MeasurementSystem;
      final displayPreferences = results[4] as DisplayPreferences;

      await _missedDoseReconciliationService.reconcile(
        dataService: _appDataService,
        protocols: protocols,
      );

      await _synchronizeAllProfileNotifications(profilesOverride: profiles);

      if (!mounted) {
        return;
      }

      setState(() {
        _activeProfile = activeProfile;
        _profiles = profiles;
        _protocols = protocols;
        _homeLayout = homeLayout;
        _trackingPreferences = trackingPreferences;
        _measurementSystem = measurementSystem;
        _displayPreferences = displayPreferences;
        _isLoading = false;
        _loadError = null;
      });

      _queueMilestoneCheck();
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

  void _handleNotificationNavigation() {
    final protocolId = widget.notificationProtocolId;

    if (protocolId == null || protocolId.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _selectedIndex = 0;
      _dataRevision++;
    });

    widget.onNotificationHandled?.call();
  }

  Future<void> _loadTrackingPreferences() async {
    final preferences = await _settingsService.getTrackingPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _trackingPreferences = preferences;
    });
  }

  Future<void> _loadDisplayPreferences() async {
    final preferences = await _settingsService.getDisplayPreferences();

    if (!mounted) {
      return;
    }

    setState(() {
      _displayPreferences = preferences;
      _dataRevision++;
    });
  }

  Future<void> _loadProfiles() async {
    final profiles = await _profileService.getProfiles();

    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = profiles;
    });
  }

  Future<void> _loadHomeLayout() async {
    final layout = await _settingsService.getHomeLayout();

    if (!mounted) {
      return;
    }

    setState(() {
      _homeLayout = layout;
    });
  }

  Future<void> _switchProfile(Profile profile) async {
    if (_activeProfile?.id == profile.id || _isSwitchingProfile) {
      return;
    }

    setState(() {
      _isSwitchingProfile = true;
      _loadError = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));

      await _profileService.setActiveProfile(profile.id);

      final protocols = await _appDataService.getProtocols();

      await _synchronizeAllProfileNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _activeProfile = profile;
        _protocols = protocols;
        _dataRevision++;
      });

      UsageAnalyticsService.instance.track(
        UsageAnalyticsEvent.profileSwitched,
      );

      _queueMilestoneCheck();

      await Future<void>.delayed(const Duration(milliseconds: 80));
    } on ProfileAccessRequiresPremiumException {
      if (!mounted) {
        return;
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PremiumScreen(dataService: _appDataService),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingProfile = false;
        });
      }
    }
  }

  Future<void> _openProfileSelector() async {
    final freeProfileId = await _profileService.getFreeProfileId();

    if (!mounted) {
      return;
    }

    final selectedProfile = await showModalBottomSheet<Profile>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profiles',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                for (final profile in _profiles) ...[
                  _ProfileSelectorTile(
                    profile: profile,
                    isActive: profile.id == _activeProfile?.id,
                    isLocked:
                        !_profileService.hasPremium &&
                        profile.id != freeProfileId,
                    onSelect: () {
                      Navigator.pop(sheetContext, profile);
                    },
                    onEdit: () {
                      Navigator.pop(sheetContext);

                      Future<void>.delayed(
                        Duration.zero,
                        () => _openEditProfile(profile),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Add Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _profileService.hasPremium
                        ? 'Create another profile'
                        : 'Available with MODOSE Premium',
                  ),
                  trailing: _profileService.hasPremium
                      ? const Icon(LucideIcons.chevronRight)
                      : _GhostPremiumBadge(colorScheme: colors),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAddProfile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedProfile == null || !mounted) {
      return;
    }

    await _switchProfile(selectedProfile);
  }

  Future<void> _openAddProfile() async {
    if (!_profileService.hasPremium) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PremiumScreen(dataService: _appDataService),
        ),
      );

      return;
    }

    final result = await Navigator.push<CreateProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateProfileScreen(measurementSystem: _measurementSystem),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final profile = await _profileService.createProfile(
      name: result.name,
      type: result.type,
      colorValue: result.colorValue,
      iconCodePoint: result.iconCodePoint,
      avatarImagePath: result.avatarImagePath,
      startingWeight: result.startingWeight,
      goalWeight: result.goalWeight,
      heightCm: result.heightCm,
      enabledModules: result.enabledModules,
    );

    await _profileService.setActiveProfile(profile.id);

    if (result.startingWeight != null) {
      final now = DateTime.now();

      await _appDataService.saveWeightRecord(
        WeightRecord(
          id: '${profile.id}_initial_${now.microsecondsSinceEpoch}',
          weight: result.startingWeight!,
          recordedAt: now,
        ),
      );
    }

    final profiles = await _profileService.getProfiles();
    final protocols = await _appDataService.getProtocols();

    await _synchronizeAllProfileNotifications(profilesOverride: profiles);

    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = profiles;
      _activeProfile = profile;
      _protocols = protocols;
      _dataRevision++;
    });

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.profileCreated,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${profile.name} created.')));
  }

  Future<void> _openEditProfile(Profile profile) async {
    final result = await Navigator.push<EditProfileResult>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
          canDelete: _profiles.length > 1,
          measurementSystem: _measurementSystem,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      final profiles = await _profileService.getProfiles();
      final activeProfile = await _profileService.getActiveProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
        _activeProfile = activeProfile;
        _dataRevision++;
      });

      return;
    }

    if (result.action == EditProfileAction.saved) {
      final updatedProfile = result.profile;

      if (updatedProfile == null) {
        return;
      }

      await _profileService.updateProfile(updatedProfile);

      final profiles = await _profileService.getProfiles();
      final activeProfile = await _profileService.getActiveProfile();

      await _synchronizeAllProfileNotifications(profilesOverride: profiles);

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
        _activeProfile = activeProfile;
        _dataRevision++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updatedProfile.name} updated.')),
      );

      return;
    }

    if (result.action == EditProfileAction.deleted) {
      await _profileService.deleteProfile(profile.id);

      final profiles = await _profileService.getProfiles();
      final activeProfile = await _profileService.getActiveProfile();
      final protocols = await _appDataService.getProtocols();

      await _synchronizeAllProfileNotifications(profilesOverride: profiles);

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;
        _activeProfile = activeProfile;
        _protocols = protocols;
        _dataRevision++;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${profile.name} deleted.')));
    }
  }

  Future<void> _openTrackingModules() async {
    final activeProfile = _activeProfile;

    if (activeProfile == null || !mounted) {
      return;
    }

    // Supply remains a protocol companion internally. The picker mirrors the
    // choices shown during onboarding rather than exposing implementation-only
    // module state.
    const selectableModules = <ProfileModule>[
      ProfileModule.protocols,
      ProfileModule.weight,
      ProfileModule.photos,
      ProfileModule.notes,
    ];

    final selectedModules = Set<ProfileModule>.from(
      activeProfile.enabledModules.where(selectableModules.contains),
    );

    final updatedSelection = await showModalBottomSheet<Set<ProfileModule>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedModules.length == selectableModules.length
                          ? 'Edit Tracking'
                          : 'Add More Tracking',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose what this profile tracks. You can change these choices anytime.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final module in selectableModules)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selectedModules.contains(module),
                        title: Text(
                          module.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(module.description),
                        onChanged: (enabled) {
                          setSheetState(() {
                            if (enabled) {
                              selectedModules.add(module);
                            } else {
                              selectedModules.remove(module);
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selectedModules.isEmpty
                            ? null
                            : () {
                                Navigator.pop(
                                  sheetContext,
                                  Set<ProfileModule>.from(selectedModules),
                                );
                              },
                        child: const Text('Save Tracking'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updatedSelection == null || !mounted) {
      return;
    }

    final storedModules = Set<ProfileModule>.from(updatedSelection);

    if (storedModules.contains(ProfileModule.protocols)) {
      storedModules.add(ProfileModule.inventory);
    } else {
      storedModules.remove(ProfileModule.inventory);
    }

    final updatedProfile = activeProfile.copyWith(
      enabledModules: storedModules,
      updatedAt: DateTime.now(),
    );

    var updatedPreferences = _trackingPreferences.copyWith(
      trackWeight: updatedSelection.contains(ProfileModule.weight),
      trackPhotos: updatedSelection.contains(ProfileModule.photos),
      trackNotes: updatedSelection.contains(ProfileModule.notes),
    );

    await Future.wait([
      _profileService.updateProfile(updatedProfile),
      _settingsService.saveTrackingPreferences(updatedPreferences),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _activeProfile = updatedProfile;
      _trackingPreferences = updatedPreferences;
      _dataRevision++;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tracking updated.')));
  }

  Future<void> _openEditHome() async {
    final updatedLayout = await Navigator.push<HomeLayout>(
      context,
      MaterialPageRoute(
        builder: (_) => EditHomeScreen(
          initialLayout: _homeLayout,
          trackingPreferences: _trackingPreferences,
        ),
      ),
    );

    if (updatedLayout == null || !mounted) {
      return;
    }

    await _settingsService.saveHomeLayout(updatedLayout);

    final activeProfile = _activeProfile;

    if (activeProfile == null) {
      return;
    }

    final modulesToEnable = Set<ProfileModule>.from(
      activeProfile.enabledModules,
    );

    var updatedTrackingPreferences = _trackingPreferences;

    for (final section in updatedLayout.visibleSections) {
      switch (section) {
        case HomeSection.today:
        case HomeSection.upcoming:
          modulesToEnable.add(ProfileModule.protocols);
          modulesToEnable.add(ProfileModule.inventory);
          break;

        case HomeSection.ghostSupply:
          modulesToEnable.add(ProfileModule.inventory);
          break;

        case HomeSection.weight:
          modulesToEnable.add(ProfileModule.weight);
          updatedTrackingPreferences = updatedTrackingPreferences.copyWith(
            trackWeight: true,
          );
          break;

        case HomeSection.progressPhotos:
          modulesToEnable.add(ProfileModule.photos);
          updatedTrackingPreferences = updatedTrackingPreferences.copyWith(
            trackPhotos: true,
          );
          break;

        case HomeSection.notesSymptoms:
          modulesToEnable.add(ProfileModule.notes);
          updatedTrackingPreferences = updatedTrackingPreferences.copyWith(
            trackNotes: true,
          );
          break;

        case HomeSection.recentActivity:
          break;
      }
    }

    final updatedProfile = activeProfile.copyWith(
      enabledModules: modulesToEnable,
      updatedAt: DateTime.now(),
    );

    await Future.wait([
      _profileService.updateProfile(updatedProfile),
      _settingsService.saveTrackingPreferences(updatedTrackingPreferences),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _homeLayout = updatedLayout;
      _trackingPreferences = updatedTrackingPreferences;
      _activeProfile = updatedProfile;
      _dataRevision++;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Home layout saved.')));
  }

  Future<void> _addProtocol(Protocol protocol) async {
    await _appDataService.addProtocol(protocol);
    await _synchronizeAllProfileNotifications();

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.protocolCreated,
      properties: {
        'protocol_type': protocol.type.name,
        'has_advanced_dose': protocol.doseDetails != null,
        'reminders_enabled': protocol.reminderEnabled,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _protocols.add(protocol);
      _dataRevision++;
    });
  }

  Future<void> _updateProtocol(Protocol protocol) async {
    await _appDataService.updateProtocol(protocol);
    await _synchronizeAllProfileNotifications();

    UsageAnalyticsService.instance.track(
      UsageAnalyticsEvent.protocolEdited,
      properties: {
        'protocol_type': protocol.type.name,
        'has_advanced_dose': protocol.doseDetails != null,
        'reminders_enabled': protocol.reminderEnabled,
      },
    );

    if (!mounted) {
      return;
    }

    final index = _protocols.indexWhere((item) => item.id == protocol.id);

    setState(() {
      if (index != -1) {
        _protocols[index] = protocol;
      }

      _dataRevision++;
    });
  }

  void _notifyDataChanged() {
    _refreshSharedData();
  }

  Future<void> _refreshSharedData() async {
    final protocols = await _appDataService.getProtocols();

    if (!mounted) {
      return;
    }

    setState(() {
      _protocols = protocols;
      _dataRevision++;
    });

    _queueMilestoneCheck();
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          measurementSystem: _measurementSystem,
          onMeasurementSystemChanged: _handleMeasurementSystemChanged,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadTrackingPreferences(),
      _loadDisplayPreferences(),
      _loadHomeLayout(),
      _loadProfiles(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.circleAlert, size: 42),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load app data.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _loadError = null;
                      });

                      _initializeApp();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final activeProfile = _activeProfile;

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(child: Text('No active profile found.')),
      );
    }

    final screens = <Widget>[
      DashboardScreen(
        profile: activeProfile,
        protocols: _protocols,
        onProtocolAdded: _addProtocol,
        dataService: _appDataService,
        dataRevision: _dataRevision,
        homeLayout: _homeLayout,
        trackingPreferences: _trackingPreferences,
        displayPreferences: _displayPreferences,
        measurementSystem: _measurementSystem,
        onDataChanged: _notifyDataChanged,
        onAddMoreModules: _openTrackingModules,
        onArrangeHome: _openEditHome,
      ),
      ProtocolsScreen(
        protocols: _protocols,
        onProtocolsChanged: _notifyDataChanged,
        onProtocolAdded: _addProtocol,
        onProtocolUpdated: _updateProtocol,
        displayPreferences: _displayPreferences,
      ),
      CalendarScreen(
        dataService: _appDataService,
        protocols: _protocols,
        onDataChanged: _notifyDataChanged,
        measurementSystem: _measurementSystem,
      ),
      ToolsScreen(
        dataService: _appDataService,
        protocols: _protocols,
        measurementSystem: _measurementSystem,
        onDataChanged: _notifyDataChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 58,
        leading: _selectedIndex == 0
            ? IconButton(
                onPressed: _openEditHome,
                tooltip: 'Edit Home',
                icon: const Icon(LucideIcons.slidersHorizontal),
              )
            : const SizedBox(width: 48),
        title: _ProfileSelectorButton(
          profile: activeProfile,
          onTap: _openProfileSelector,
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Settings',
            icon: const Icon(LucideIcons.settings),
          ),
        ],
      ),
      body: AnimatedOpacity(
        opacity: _isSwitchingProfile ? 0.35 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: _isSwitchingProfile,
          child: IndexedStack(index: _selectedIndex, children: screens),
        ),
      ),
      bottomNavigationBar: _MODOSEBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _MODOSEBottomNavigation extends StatelessWidget {
  const _MODOSEBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colors.surface.withValues(alpha: 0.78)
                  : Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.outlineVariant.withValues(
                  alpha: isDark ? 0.42 : 0.50,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: isDark ? 0.24 : 0.09),
                  blurRadius: 24,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: NavigationBar(
              height: 68,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              indicatorColor: colors.primary.withValues(
                alpha: isDark ? 0.19 : 0.12,
              ),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(LucideIcons.house),
                  selectedIcon: Icon(LucideIcons.house),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.syringe),
                  selectedIcon: Icon(LucideIcons.syringe),
                  label: 'Protocols',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.calendarCheck),
                  selectedIcon: Icon(LucideIcons.calendarCheck),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.layoutGrid),
                  selectedIcon: Icon(LucideIcons.layoutGrid),
                  label: 'Tools',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSelectorButton extends StatelessWidget {
  const _ProfileSelectorButton({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(profile: profile, radius: 15),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  profile.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSelectorTile extends StatelessWidget {
  const _ProfileSelectorTile({
    required this.profile,
    required this.isActive,
    required this.isLocked,
    required this.onSelect,
    required this.onEdit,
  });

  final Profile profile;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLocked ? null : onSelect,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Opacity(
                      opacity: isLocked ? 0.55 : 1,
                      child: ProfileAvatar(profile: profile, radius: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isLocked
                                        ? colors.onSurfaceVariant
                                        : null,
                                  ),
                                ),
                              ),
                              if (isLocked) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  LucideIcons.lock,
                                  size: 16,
                                  color: colors.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLocked
                                ? 'MODOSE Premium profile'
                                : profile.type.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle, color: colors.primary)
                    else if (isLocked)
                      _GhostPremiumBadge(colorScheme: colors)
                    else
                      Icon(
                        LucideIcons.chevronRight,
                        color: colors.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit ${profile.name}',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onPressed: onEdit,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _GhostPremiumBadge extends StatelessWidget {
  const _GhostPremiumBadge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'MODOSE Premium',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
