// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

class RegattaApp extends ConsumerWidget {
  const RegattaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final darkMode = settingsAsync.valueOrNull?.darkMode ?? true;

    return MaterialApp(
      title: 'Regatta Screen',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
