import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/app_data_service.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'protocols_screen.dart';
import 'tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AppDataService _appDataService = AppDataService();

  int _selectedIndex = 0;
  int _dataRevision = 0;

  List<Protocol> _protocols = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProtocols();
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
