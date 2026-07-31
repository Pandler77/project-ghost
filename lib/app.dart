import 'package:flutter/material.dart';

import 'models/app_theme_mode.dart';
import 'screens/main_screen.dart';
import 'services/settings_service.dart';

class ProjectGhostApp extends StatefulWidget {
  const ProjectGhostApp({super.key});

  @override
  State<ProjectGhostApp> createState() => _ProjectGhostAppState();
}

class _ProjectGhostAppState extends State<ProjectGhostApp> {
  final SettingsService _settingsService = SettingsService();

  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeMode = await _settingsService.getThemeMode();

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = themeMode;
      _isLoadingSettings = false;
    });
  }

  Future<void> _changeThemeMode(AppThemeMode themeMode) async {
    await _settingsService.saveThemeMode(themeMode);

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = themeMode;
    });
  }

  ThemeMode get _materialThemeMode {
    return switch (_themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const _StartupScreen(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Ghost',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _materialThemeMode,
      home: MainScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB69DF8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121216),
      cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
