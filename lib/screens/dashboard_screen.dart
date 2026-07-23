import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/protocol.dart';
import '../services/dose_service.dart';
import '../services/protocol_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/today_doses_card.dart';
import '../widgets/weight_card.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Protocol'),
              content: const Text('This screen is coming in the next sprint.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const DashboardHeader(name: 'Frank'),
            const SizedBox(height: 24),

            TodayDosesCard(
              doses: doses,
              onDosePressed: (dose) {
                setState(() {
                  dose.completedAt = dose.isCompleted ? null : DateTime.now();
                });
              },
            ),

            const SizedBox(height: 20),

            WeightCard(
              currentWeight: 361.4,
              startingWeight: 405.2,
              onLogWeight: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Weight'),
                    content: const Text(
                      'Weight logging is coming later this sprint.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
