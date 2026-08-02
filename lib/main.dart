import 'package:flutter/material.dart';
import 'package:project_ghost/app.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  runApp(const ProjectGhostApp());
}
