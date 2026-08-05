import 'package:flutter/material.dart';

import '../models/app_theme_mode.dart';
import '../models/home_layout.dart';
import '../models/profile.dart';
import '../models/protocol.dart';
import '../models/tracking_preferences.dart';
import '../services/app_data_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
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

  int _selectedIndex = 0;
  int _dataRevision = 0;

  HomeLayout _homeLayout = HomeLayout.defaultLayout;
  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;

  List<Protocol> _protocols = [];
  List<Profile> _profiles = [];

  Profile? _activeProfile;

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _initializeApp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation();
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

  Future<void> _initializeApp() async {
    try {
      final activeProfile = await _profileService.getActiveProfile();
      final profiles = await _profileService.getProfiles();

      final results = await Future.wait<Object>([
        _appDataService.getProtocols(),
        _settingsService.getHomeLayout(),
        _settingsService.getTrackingPreferences(),
      ]);

      final protocols = results[0] as List<Protocol>;
      final homeLayout = results[1] as HomeLayout;
      final trackingPreferences = results[2] as TrackingPreferences;

      await NotificationService.instance.synchronizeProtocolReminders(
        protocols,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeProfile = activeProfile;
        _profiles = profiles;
        _protocols = protocols;
        _homeLayout = homeLayout;
        _trackingPreferences = trackingPreferences;
        _isLoading = false;
        _loadError = null;
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
    if (_activeProfile?.id == profile.id) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _profileService.setActiveProfile(profile.id);

      final protocols = await _appDataService.getProtocols();

      await NotificationService.instance.synchronizeProtocolReminders(
        protocols,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeProfile = profile;
        _protocols = protocols;
        _dataRevision++;
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

  Future<void> _openProfileSelector() async {
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
                for (final profile in _profiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: profile.id == _activeProfile?.id
                            ? colors.primaryContainer
                            : colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: profile.id == _activeProfile?.id
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.pop(sheetContext, profile);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    _ProfileAvatar(profile: profile, size: 42),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile.type.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (profile.id == _activeProfile?.id)
                                      Icon(
                                        Icons.check_circle,
                                        color: colors.primary,
                                      )
                                    else
                                      Icon(
                                        Icons.chevron_right,
                                        color: colors.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit ${profile.name}',
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              Navigator.pop(sheetContext);

                              Future<void>.delayed(
                                Duration.zero,
                                () => _openEditProfile(profile),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: colors.primary),
                  ),
                  title: const Text(
                    'Add Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _profileService.hasPremium
                        ? 'Create another profile'
                        : 'Available with Ghost Premium',
                  ),
                  trailing: _profileService.hasPremium
                      ? const Icon(Icons.chevron_right)
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
      MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
    );

    if (result == null || !mounted) {
      return;
    }

    final profile = await _profileService.createProfile(
      name: result.name,
      type: result.type,
    );

    await _profileService.setActiveProfile(profile.id);

    final profiles = await _profileService.getProfiles();
    final protocols = await _appDataService.getProtocols();

    await NotificationService.instance.synchronizeProtocolReminders(protocols);

    if (!mounted) {
      return;
    }

    setState(() {
      _profiles = profiles;
      _activeProfile = profile;
      _protocols = protocols;
      _dataRevision++;
    });

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
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.action == EditProfileAction.saved) {
      final updatedProfile = result.profile;

      if (updatedProfile == null) {
        return;
      }

      await _profileService.updateProfile(updatedProfile);

      final profiles = await _profileService.getProfiles();

      if (!mounted) {
        return;
      }

      setState(() {
        _profiles = profiles;

        if (_activeProfile?.id == updatedProfile.id) {
          _activeProfile = updatedProfile;
        }

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

      await NotificationService.instance.synchronizeProtocolReminders(
        protocols,
      );

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

    if (!mounted) {
      return;
    }

    setState(() {
      _homeLayout = updatedLayout;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Home layout saved.')));
  }

  Future<void> _addProtocol(Protocol protocol) async {
    await _appDataService.addProtocol(protocol);

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
    setState(() {
      _dataRevision++;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadTrackingPreferences(),
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
                  const Icon(Icons.error_outline, size: 42),
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
        protocols: _protocols,
        onProtocolAdded: _addProtocol,
        dataService: _appDataService,
        displayName: activeProfile.name,
        dataRevision: _dataRevision,
        homeLayout: _homeLayout,
        trackingPreferences: _trackingPreferences,
        onDataChanged: _notifyDataChanged,
      ),
      ProtocolsScreen(
        protocols: _protocols,
        onProtocolsChanged: _notifyDataChanged,
        onProtocolAdded: _addProtocol,
        onProtocolUpdated: _updateProtocol,
      ),
      CalendarScreen(
        dataService: _appDataService,
        protocols: _protocols,
        onDataChanged: _notifyDataChanged,
      ),
      ToolsScreen(dataService: _appDataService, protocols: _protocols),
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
                icon: const Icon(Icons.tune),
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
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Protocols',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
        ],
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
              _ProfileAvatar(profile: profile, size: 30),
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
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.size});

  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final icon = _defaultProfileIcon(profile.type);

    final backgroundColor = profile.colorValue == null
        ? colors.primaryContainer
        : Color(profile.colorValue!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(
        icon,
        size: size * 0.56,
        color: profile.colorValue == null
            ? colors.onPrimaryContainer
            : Colors.white,
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
        'Ghost Premium',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

IconData _defaultProfileIcon(ProfileType type) {
  return switch (type) {
    ProfileType.self => Icons.person,
    ProfileType.familyMember => Icons.people,
    ProfileType.child => Icons.child_care,
    ProfileType.pet => Icons.pets,
    ProfileType.other => Icons.account_circle,
  };
}
