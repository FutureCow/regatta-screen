// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(settingsServiceProvider).load();
  }

  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
    await ref.read(settingsServiceProvider).save(settings);
  }
}
