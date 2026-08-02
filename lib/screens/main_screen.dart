import 'package:flutter/material.dart';

import '../models/app_theme_mode.dart';
import '../models/home_layout.dart';
import '../models/protocol.dart';
import '../models/tracking_preferences.dart';
import '../services/app_data_service.dart';
import '../services/settings_service.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'edit_home_screen.dart';
import 'protocols_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AppDataService _appDataService = AppDataService();
  final SettingsService _settingsService = SettingsService();

  int _selectedIndex = 0;
  int _dataRevision = 0;

  HomeLayout _homeLayout = HomeLayout.defaultLayout;
  TrackingPreferences _trackingPreferences = TrackingPreferences.defaults;

  List<Protocol> _protocols = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _loadProtocols();
    _loadHomeLayout();
    _loadTrackingPreferences();
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


  Future<void> _loadProtocols() async {
    try {
      final protocols = await _appDataService.getProtocols();

      if (!mounted) {
        return;
      }

      setState(() {
        _protocols = protocols;
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

  Future<void> _loadHomeLayout() async {
    final layout = await _settingsService.getHomeLayout();

    if (!mounted) {
      return;
    }

    setState(() {
      _homeLayout = layout;
    });
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

    await _loadTrackingPreferences();
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

                      _loadProtocols();
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

    final screens = <Widget>[
      DashboardScreen(
        protocols: _protocols,
        onProtocolAdded: _addProtocol,
        dataService: _appDataService,
        displayName: _appDataService.displayName,
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
        toolbarHeight: 52,
        leading: _selectedIndex == 0
            ? IconButton(
                onPressed: _openEditHome,
                tooltip: 'Edit Home',
                icon: const Icon(Icons.tune),
              )
            : null,
        title: _selectedIndex == 0
            ? null
            : Text(
                _pageTitle(_selectedIndex),
                style: const TextStyle(fontWeight: FontWeight.w600),
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

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Home',
      1 => 'Protocols',
      2 => 'Calendar',
      3 => 'Tools',
      _ => '',
    };
  }
}
