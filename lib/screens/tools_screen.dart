import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Tools',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _ToolTile(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
          ),

          _ToolTile(
            icon: Icons.calculate_outlined,
            title: 'Dose Calculator',
          ),

          _ToolTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Weight History',
          ),

          _ToolTile(
            icon: Icons.photo_library_outlined,
            title: 'Progress Photos',
          ),

          _ToolTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
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
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}