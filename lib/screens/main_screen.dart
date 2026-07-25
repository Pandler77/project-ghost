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

  late final List<Protocol> _protocols;

  @override
  void initState() {
    super.initState();

    _protocols = _appDataService.getInitialProtocols();
  }

  void _addProtocol(Protocol protocol) {
    setState(() {
      _protocols.add(protocol);
    });
  }

  void _refreshProtocols() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        protocols: _protocols,
        onProtocolAdded: _addProtocol,
        displayName: _appDataService.displayName,
        currentWeight: _appDataService.currentWeight,
        startingWeight: _appDataService.startingWeight,
      ),
      ProtocolsScreen(
        protocols: _protocols,
        onProtocolsChanged: _refreshProtocols,
        onProtocolAdded: _addProtocol,
      ),
      const CalendarScreen(),
      const ToolsScreen(),
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
