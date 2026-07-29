import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/app_data_service.dart';
import 'dose_history_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({
    required this.dataService,
    required this.protocols,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Tools',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          _ToolTile(
            icon: Icons.history_outlined,
            title: 'Dose History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoseHistoryScreen(
                    dataService: dataService,
                    protocols: protocols,
                  ),
                ),
              );
            },
          ),

          _ToolTile(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
            onTap: () {},
          ),

          _ToolTile(
            icon: Icons.calculate_outlined,
            title: 'Dose Calculator',
            onTap: () {},
          ),

          _ToolTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Weight History',
            onTap: () {},
          ),

          _ToolTile(
            icon: Icons.photo_library_outlined,
            title: 'Progress Photos',
            onTap: () {},
          ),

          _ToolTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
