import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

class ProjectGhostApp extends StatelessWidget {
  const ProjectGhostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Ghost',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}