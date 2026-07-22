import 'package:flutter/material.dart';

import '../models/protocol.dart';

class ProtocolCard extends StatelessWidget {
  const ProtocolCard({
    required this.protocol,
    required this.isTaken,
    required this.onPressed,
    super.key,
  });

  final Protocol protocol;
  final bool isTaken;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              protocol.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('${protocol.dose} • ${protocol.time}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isTaken ? null : onPressed,
                child: Text(
                  isTaken ? '✓ Taken' : 'Take Shot',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}