import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/app_data_service.dart';
import 'calculator_hub_screen.dart';
import 'dose_history_screen.dart';
import 'inventory_screen.dart';

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
            title: 'Ghost Supply™',
            subtitle: 'Inventory and low-stock tracking',
            badge: 'Premium',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InventoryScreen(
                    dataService: dataService,
                    protocols: protocols,
                  ),
                ),
              );
            },
          ),

          _ToolTile(
            icon: Icons.calculate_outlined,
            title: 'Ghost Calculator',
            subtitle: 'Dose, dilution, and concentration tools',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalculatorHubScreen()),
              );
            },
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
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Row(
          children: [
            Flexible(child: Text(title)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
