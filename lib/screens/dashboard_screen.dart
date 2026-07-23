import 'package:flutter/material.dart';

import '../models/protocol.dart';
import '../services/protocol_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/protocol_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final protocolService = ProtocolService();

  late final List<Protocol> protocols;

  @override
  void initState() {
    super.initState();
    protocols = protocolService.getAllProtocols();
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
              'Today',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            for (final protocol in protocols) ...[
              ProtocolCard(
                protocol: protocol,
                isTaken: protocol.isTaken,
                onPressed: () {
                  setState(() {
                    protocol.completedAt = protocol.isTaken
                        ? null
                        : DateTime.now();
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