import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/protocol.dart';
import '../services/dose_service.dart';
import '../services/protocol_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dose_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final protocolService = ProtocolService();
  final doseService = DoseService();

  late final List<Protocol> protocols;
  late final List<Dose> doses;

  @override
  void initState() {
    super.initState();

    protocols = protocolService.getAllProtocols();
    doses = doseService.getTodaysDoses(protocols);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const DashboardHeader(name: 'Frank'),
            const SizedBox(height: 24),
            const Text(
              'Today\'s Doses',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final dose in doses) ...[
              DoseCard(
                dose: dose,
                onPressed: () {
                  setState(() {
                    dose.completedAt =
                        dose.isCompleted ? null : DateTime.now();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}