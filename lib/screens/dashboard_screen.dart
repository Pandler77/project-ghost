import 'package:flutter/material.dart';
import '../widgets/dashboard_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: DashboardHeader(name: 'Frank'),
      ),
    );
  }
}