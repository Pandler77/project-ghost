import 'package:flutter/material.dart';

import 'models/app_theme_mode.dart';

import 'models/profile_module.dart';

import 'screens/main_screen.dart';

import 'screens/onboarding_setup_screen.dart';

import 'screens/welcome_screen.dart';

import 'services/app_reset_service.dart';

import 'services/notification_service.dart';

import 'services/profile_service.dart';

import 'services/settings_service.dart';

import 'theme/app_theme.dart';

class ProjectGhostApp extends StatefulWidget {

  const ProjectGhostApp({super.key});

  @override

  State<ProjectGhostApp> createState() => _ProjectGhostAppState();

}

class _ProjectGhostAppState extends State<ProjectGhostApp> {

  final SettingsService _settingsService = SettingsService();

  final AppResetService _appResetService = AppResetService.instance;

  final ProfileService _profileService = ProfileService();

  final NotificationService _notificationService = NotificationService.instance;

  Widget _buildKeyboardDismissWrapper(BuildContext context, Widget? child) {

    return Listener(

behavior: HitTestBehavior.translucent,

onPointerDown: (_) {

        FocusManager.instance.primaryFocus?.unfocus();

      },

child: Stack(

fit: StackFit.expand,

children: [

          const _GlobalAppBackground(),

child ?? const SizedBox.shrink(),

        ],

      ),

    );

  }

AppThemeMode _themeMode = AppThemeMode.system;

  bool _isLoadingSettings = true;

  bool _isOnboardingComplete = false;

  bool _isShowingSetup = false;

  String? _notificationProtocolId;

  @override

  void initState() {

super.initState();

    _notificationProtocolId = _notificationService.pendingProtocolId;

    _notificationService.protocolNavigation.addListener(

      _handleNotificationNavigation,

    );

    _appResetService.resetRevision.addListener(_handleAppReset);

    _loadSettings();

  }

  @override

  void dispose() {

    _notificationService.protocolNavigation.removeListener(

      _handleNotificationNavigation,

    );

    _appResetService.resetRevision.removeListener(_handleAppReset);

super.dispose();

  }

  void _handleAppReset() {

    _reloadAfterAppReset();

  }

  Future<void> _reloadAfterAppReset() async {

    if (!mounted) {

      return;

    }

    setState(() {

      _isLoadingSettings = true;

      _isOnboardingComplete = false;

      _isShowingSetup = false;

      _notificationProtocolId = null;

    });

    await _loadSettings();

  }

  void _handleNotificationNavigation() {

    final protocolId = _notificationService.protocolNavigation.value;

    if (protocolId == null || protocolId.isEmpty || !mounted) {

      return;

    }

    setState(() {

      _notificationProtocolId = protocolId;

    });

  }

  void _completeNotificationNavigation() {

    _notificationService.clearPendingNavigation();

    if (!mounted) {

      return;

    }

    setState(() {

      _notificationProtocolId = null;

    });

  }

  Future<void> _loadSettings() async {

    final results = await Future.wait([

      _settingsService.getThemeMode(),

      _settingsService.getOnboardingComplete(),

    ]);

    if (!mounted) {

      return;

    }

    setState(() {

      _themeMode = results[0] as AppThemeMode;

      _isOnboardingComplete = results[1] as bool;

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

  void _startOnboarding() {

    setState(() {

      _isShowingSetup = true;

    });

  }

  void _cancelOnboarding() {

    setState(() {

      _isShowingSetup = false;

    });

  }

  Future<void> _completeOnboarding(OnboardingSetupResult result) async {

    final activeProfile = await _profileService.getActiveProfile();

    await _profileService.updateProfile(

      activeProfile.copyWith(

name: result.profileName,

type: result.profileType,

heightCm: result.heightCm,

enabledModules: Set<ProfileModule>.from(result.enabledModules),

updatedAt: DateTime.now(),

      ),

    );

    await _profileService.setActiveProfile(activeProfile.id);

    await _settingsService.saveTrackingPreferences(result.preferences);

    await _settingsService.saveMeasurementSystem(result.measurementSystem);

    await _settingsService.saveOnboardingComplete(true);

    if (!mounted) {

      return;

    }

    setState(() {

      _isOnboardingComplete = true;

      _isShowingSetup = false;

    });

  }

ThemeMode get _materialThemeMode {

    return switch (_themeMode) {

AppThemeMode.system => ThemeMode.system,

AppThemeMode.light => ThemeMode.light,

AppThemeMode.dark => ThemeMode.dark,

    };

  }

  Widget _buildHome() {

    if (_isOnboardingComplete) {

      return MainScreen(

themeMode: _themeMode,

onThemeModeChanged: _changeThemeMode,

notificationProtocolId: _notificationProtocolId,

onNotificationHandled: _completeNotificationNavigation,

      );

    }

    if (_isShowingSetup) {

      return OnboardingSetupScreen(

onComplete: _completeOnboarding,

onBackToWelcome: _cancelOnboarding,

      );

    }

    return WelcomeScreen(onGetStarted: _startOnboarding);

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

builder: _buildKeyboardDismissWrapper,

      );

    }

    return MaterialApp(

debugShowCheckedModeBanner: false,

title: 'MODOSE',

theme: _buildLightTheme(),

darkTheme: _buildDarkTheme(),

themeMode: _materialThemeMode,

home: _buildHome(),

builder: _buildKeyboardDismissWrapper,

    );

  }

  ThemeData _buildLightTheme() {

    final colorScheme = ColorScheme.fromSeed(

seedColor: ArcticPalette.purple,

brightness: Brightness.light,

    );

    return ThemeData(

pageTransitionsTheme: const PageTransitionsTheme(

builders: {

TargetPlatform.android: _MODOSEPageTransitionsBuilder(),

TargetPlatform.iOS: _MODOSEPageTransitionsBuilder(),

TargetPlatform.macOS: _MODOSEPageTransitionsBuilder(),

TargetPlatform.windows: _MODOSEPageTransitionsBuilder(),

TargetPlatform.linux: _MODOSEPageTransitionsBuilder(),

},

),

useMaterial3: true,

brightness: Brightness.light,

colorScheme: colorScheme,

scaffoldBackgroundColor: Colors.transparent,

appBarTheme: AppBarTheme(

elevation: 0,

scrolledUnderElevation: 0,

centerTitle: false,

backgroundColor: Colors.transparent,

foregroundColor: colorScheme.onSurface,

surfaceTintColor: Colors.transparent,

titleTextStyle: TextStyle(

fontSize: 22,

fontWeight: FontWeight.w800,

color: colorScheme.onSurface,

        ),

      ),

cardTheme: CardThemeData(

elevation: 2,

shadowColor: Colors.black.withValues(alpha: 0.10),

margin: EdgeInsets.zero,

color: ArcticPalette.lightCard.withValues(alpha: 0.94),

surfaceTintColor: Colors.transparent,

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(16),

side: BorderSide(

color: colorScheme.outline.withValues(alpha: 0.45),

width: 1.35,

          ),

        ),

      ),

dividerTheme: DividerThemeData(

thickness: 1,

space: 1,

color: colorScheme.outlineVariant.withValues(alpha: 0.60),

      ),

filledButtonTheme: FilledButtonThemeData(

style: FilledButton.styleFrom(

minimumSize: const Size(0, 46),

padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

outlinedButtonTheme: OutlinedButtonThemeData(

style: OutlinedButton.styleFrom(

minimumSize: const Size(0, 46),

padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

side: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.72),

          ),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

textButtonTheme: TextButtonThemeData(

style: TextButton.styleFrom(

padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(10),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

inputDecorationTheme: InputDecorationTheme(

filled: true,

fillColor: ArcticPalette.lightRaised,

contentPadding: const EdgeInsets.symmetric(

horizontal: 14,

vertical: 14,

        ),

border: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(color: colorScheme.outlineVariant),

        ),

enabledBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(color: colorScheme.outlineVariant),

        ),

focusedBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(color: colorScheme.primary, width: 1.5),

        ),

      ),

navigationBarTheme: NavigationBarThemeData(

height: 68,

elevation: 0,

backgroundColor: ArcticPalette.lightSurface,

surfaceTintColor: Colors.transparent,

indicatorColor: colorScheme.primary.withValues(alpha: 0.12),

indicatorShape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

        ),

      ),

bottomSheetTheme: const BottomSheetThemeData(

showDragHandle: true,

elevation: 0,

surfaceTintColor: Colors.transparent,

      ),

snackBarTheme: SnackBarThemeData(

behavior: SnackBarBehavior.floating,

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      ),

floatingActionButtonTheme: FloatingActionButtonThemeData(

elevation: 0,

highlightElevation: 0,

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      ),

    );

  }

  ThemeData _buildDarkTheme() {

    final colorScheme = ColorScheme.fromSeed(

seedColor: ArcticPalette.lavender,

brightness: Brightness.dark,

    );

    return ThemeData(

pageTransitionsTheme: const PageTransitionsTheme(

builders: {

TargetPlatform.android: _MODOSEPageTransitionsBuilder(),

TargetPlatform.iOS: _MODOSEPageTransitionsBuilder(),

TargetPlatform.macOS: _MODOSEPageTransitionsBuilder(),

TargetPlatform.windows: _MODOSEPageTransitionsBuilder(),

TargetPlatform.linux: _MODOSEPageTransitionsBuilder(),

},

),

useMaterial3: true,

brightness: Brightness.dark,

colorScheme: colorScheme,

scaffoldBackgroundColor: Colors.transparent,

canvasColor: Colors.transparent,

dividerColor: const Color(0xFF303038),

appBarTheme: AppBarTheme(

elevation: 0,

scrolledUnderElevation: 0,

centerTitle: false,

backgroundColor: Colors.transparent,

foregroundColor: colorScheme.onSurface,

surfaceTintColor: Colors.transparent,

titleTextStyle: TextStyle(

fontSize: 22,

fontWeight: FontWeight.w800,

color: colorScheme.onSurface,

        ),

      ),

cardTheme: CardThemeData(

elevation: 2,

shadowColor: Colors.black.withValues(alpha: 0.24),

margin: EdgeInsets.zero,

color: ArcticPalette.darkCard.withValues(alpha: 0.92),

surfaceTintColor: Colors.transparent,

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(16),

side: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.58),

          ),

        ),

      ),

dividerTheme: DividerThemeData(

thickness: 1,

space: 1,

color: colorScheme.outlineVariant.withValues(alpha: 0.50),

      ),

filledButtonTheme: FilledButtonThemeData(

style: FilledButton.styleFrom(

minimumSize: const Size(0, 46),

padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

outlinedButtonTheme: OutlinedButtonThemeData(

style: OutlinedButton.styleFrom(

minimumSize: const Size(0, 46),

padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

side: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.72),

          ),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

textButtonTheme: TextButtonThemeData(

style: TextButton.styleFrom(

padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(10),

          ),

textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),

        ),

      ),

inputDecorationTheme: InputDecorationTheme(

filled: true,

fillColor: ArcticPalette.darkRaised,

contentPadding: const EdgeInsets.symmetric(

horizontal: 14,

vertical: 14,

        ),

border: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.60),

          ),

        ),

enabledBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.60),

          ),

        ),

focusedBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(color: colorScheme.primary, width: 1.5),

        ),

disabledBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(12),

borderSide: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.30),

          ),

        ),

hintStyle: TextStyle(

color: colorScheme.onSurfaceVariant.withValues(alpha: 0.68),

        ),

      ),

navigationBarTheme: NavigationBarThemeData(

height: 68,

elevation: 0,

backgroundColor: ArcticPalette.darkSurface,

surfaceTintColor: Colors.transparent,

indicatorColor: colorScheme.primary.withValues(alpha: 0.16),

indicatorShape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(12),

        ),

      ),

bottomSheetTheme: const BottomSheetThemeData(

showDragHandle: true,

elevation: 0,

backgroundColor: Color(0xFF1C1C22),

modalBackgroundColor: Color(0xFF1C1C22),

surfaceTintColor: Colors.transparent,

      ),

dialogTheme: DialogThemeData(

elevation: 0,

backgroundColor: ArcticPalette.darkCard,

surfaceTintColor: Colors.transparent,

shape: RoundedRectangleBorder(

borderRadius: BorderRadius.circular(16),

side: BorderSide(

color: colorScheme.outlineVariant.withValues(alpha: 0.52),

          ),

        ),

      ),

snackBarTheme: SnackBarThemeData(

behavior: SnackBarBehavior.floating,

backgroundColor: const Color(0xFF25232E),

contentTextStyle: TextStyle(

color: colorScheme.onSurface,

fontWeight: FontWeight.w600,

        ),

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      ),

floatingActionButtonTheme: FloatingActionButtonThemeData(

elevation: 0,

highlightElevation: 0,

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      ),

    );

  }

}

class _MODOSEPageTransitionsBuilder extends PageTransitionsBuilder {

  const _MODOSEPageTransitionsBuilder();

  @override

  Widget buildTransitions<T>(

    PageRoute<T> route,

    BuildContext context,

    Animation<double> animation,

    Animation<double> secondaryAnimation,

    Widget child,

  ) {

    final contentAnimation = CurvedAnimation(

      parent: animation,

      curve: Curves.easeOutCubic,

      reverseCurve: Curves.easeInCubic,

    );

    return Stack(

      fit: StackFit.expand,

      children: [

        const _GlobalAppBackground(),

        FadeTransition(

          opacity: contentAnimation,

          child: child,

        ),

      ],

    );

  }

}

class _GlobalAppBackground extends StatelessWidget {

  const _GlobalAppBackground();

  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(

child: Stack(

fit: StackFit.expand,

children: [

          DecoratedBox(

decoration: BoxDecoration(

gradient: LinearGradient(

begin: Alignment.topLeft,

end: Alignment.bottomRight,

stops: const [0.0, 0.42, 0.72, 1.0],

colors: isDark

                    ? const [

                        Color(0xFF0A0E1D),

                        Color(0xFF17132E),

                        Color(0xFF101A2E),

                        Color(0xFF081522),

                      ]

                    : const [

                        Color(0xFFEDE7FF),

                        Color(0xFFF5F1FF),

                        Color(0xFFEEF5FF),

                        Color(0xFFE6F4FF),

                      ],

              ),

            ),

          ),

          DecoratedBox(

decoration: BoxDecoration(

gradient: LinearGradient(

begin: const Alignment(-1.0, -0.35),

end: const Alignment(1.0, 0.35),

colors: isDark

                    ? [

                        const Color(0xFF7C3AED).withValues(alpha: 0.11),

                        const Color(0xFF6366F1).withValues(alpha: 0.045),

                        const Color(0xFF0EA5E9).withValues(alpha: 0.10),

                      ]

                    : [

                        const Color(0xFF8B5CF6).withValues(alpha: 0.12),

                        const Color(0xFF818CF8).withValues(alpha: 0.045),

                        const Color(0xFF38BDF8).withValues(alpha: 0.11),

                      ],

              ),

            ),

          ),

          Positioned(

top: 170,

left: -90,

right: -90,

child: Transform.rotate(

angle: -0.10,

child: Container(

height: 150,

decoration: BoxDecoration(

borderRadius: BorderRadius.circular(999),

gradient: LinearGradient(

colors: isDark

                        ? [

                            const Color(0xFF8B5CF6).withValues(alpha: 0.00),

                            const Color(0xFF8B5CF6).withValues(alpha: 0.08),

                            const Color(0xFF38BDF8).withValues(alpha: 0.07),

                            const Color(0xFF38BDF8).withValues(alpha: 0.00),

                          ]

                        : [

                            const Color(0xFF8B5CF6).withValues(alpha: 0.00),

                            const Color(0xFF8B5CF6).withValues(alpha: 0.065),

                            const Color(0xFF38BDF8).withValues(alpha: 0.06),

                            const Color(0xFF38BDF8).withValues(alpha: 0.00),

                          ],

                  ),

                ),

              ),

            ),

          ),

          Positioned(

bottom: 130,

left: -100,

right: -100,

child: Transform.rotate(

angle: 0.08,

child: Container(

height: 180,

decoration: BoxDecoration(

borderRadius: BorderRadius.circular(999),

gradient: LinearGradient(

colors: isDark

                        ? [

                            const Color(0xFF4F46E5).withValues(alpha: 0.00),

                            const Color(0xFF4F46E5).withValues(alpha: 0.065),

                            const Color(0xFF0EA5E9).withValues(alpha: 0.055),

                            const Color(0xFF0EA5E9).withValues(alpha: 0.00),

                          ]

                        : [

                            const Color(0xFF6366F1).withValues(alpha: 0.00),

                            const Color(0xFF6366F1).withValues(alpha: 0.050),

                            const Color(0xFF38BDF8).withValues(alpha: 0.050),

                            const Color(0xFF38BDF8).withValues(alpha: 0.00),

                          ],

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

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