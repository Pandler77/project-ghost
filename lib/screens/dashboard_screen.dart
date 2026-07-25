import 'dart:async';

import 'package:flutter/material.dart';

import '../models/dose.dart';
import '../models/protocol.dart';
import '../services/dose_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_dose_card.dart';
import '../widgets/today_doses_card.dart';
import '../widgets/weight_card.dart';
import 'add_protocol_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.protocols,
    required this.onProtocolAdded,
    required this.displayName,
    required this.currentWeight,
    required this.startingWeight,
    super.key,
  });

  final List<Protocol> protocols;
  final ValueChanged<Protocol> onProtocolAdded;

  final String displayName;
  final double currentWeight;
  final double startingWeight;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DoseService _doseService = DoseService();

  late List<Dose> _doses;
  Dose? _nextDose;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _doses = [];
    _refreshDoseData();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _refreshDoseData();
      });
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    _refreshDoseData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshDoseData() {
    final completionTimes = <String, DateTime?>{
      for (final dose in _doses) dose.protocolId: dose.completedAt,
    };

    final refreshedDoses = _doseService.getTodaysDoses(widget.protocols);

    for (final dose in refreshedDoses) {
      dose.completedAt = completionTimes[dose.protocolId];
    }

    _doses = refreshedDoses;
    _nextDose = _doseService.getNextDose(widget.protocols);
  }

  Future<void> _openAddProtocol() async {
    final protocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => const AddProtocolScreen()),
    );

    if (protocol == null || !mounted) {
      return;
    }

    widget.onProtocolAdded(protocol);

    setState(() {
      _refreshDoseData();
    });
  }

  void _openWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: const Text('Weight logging is coming later this sprint.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProtocol,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DashboardHeader(name: widget.displayName),
            const SizedBox(height: 24),

            TodayDosesCard(
              doses: _doses,
              onDosePressed: (dose) {
                setState(() {
                  dose.completedAt = dose.isCompleted ? null : DateTime.now();
                });
              },
            ),

            const SizedBox(height: 20),

            WeightCard(
              currentWeight: widget.currentWeight,
              startingWeight: widget.startingWeight,
              onLogWeight: _openWeightDialog,
            ),

            const SizedBox(height: 20),

            NextDoseCard(dose: _nextDose),
          ],
        ),
      ),
    );
  }
}
