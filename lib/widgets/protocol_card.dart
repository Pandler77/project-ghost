import 'package:flutter/material.dart';

import '../models/protocol.dart';

class ProtocolCard extends StatelessWidget {
  const ProtocolCard({
    required this.protocol,
    super.key,
  });

  final Protocol protocol;

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
          ],
        ),
      ),
    );
  }
}