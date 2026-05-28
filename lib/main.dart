// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (foreground notification keeps app alive)
  await BackgroundServiceManager.initialize();

  runApp(const ProviderScope(child: RegattaApp()));
}
