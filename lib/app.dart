// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'theme/app_theme.dart';

class RegattaApp extends ConsumerWidget {
  const RegattaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final darkMode = settingsAsync.valueOrNull?.darkMode ?? true;

    // Determine initial route based on auth state.
    // We wait for settings to finish loading so we can read the persisted token.
    // While loading, show a dark splash screen instead of a flash.
    final Widget home;
    if (settingsAsync.isLoading) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      final auth = ref.watch(authProvider);
      home = auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
    }

    return MaterialApp(
      title: 'Regatta Screen',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}
