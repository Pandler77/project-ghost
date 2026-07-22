import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/protocol_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final protocols = [
      const Protocol(
        name: 'Retatrutide',
        dose: '3 mg',
        time: '10:00 PM',
      ),
      const Protocol(
        name: 'GHK-Cu',
        dose: '2 mg',
        time: '10:05 PM',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const DashboardHeader(name: 'Frank'),
            const SizedBox(height: 24),
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final protocol in protocols) ...[
              ProtocolCard(protocol: protocol),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}