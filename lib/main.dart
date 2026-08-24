import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:project_ghost/app.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/usage_analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await UsageAnalyticsService.instance.initialize();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const ProjectGhostApp());

  await UsageAnalyticsService.instance.track(UsageAnalyticsEvent.appOpened);
}
