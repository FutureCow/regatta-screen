// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';

/// Immutable authentication state.
class AuthState {
  final String? token;
  final String? email;

  const AuthState({this.token, this.email});

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Hydrate from persisted settings synchronously
    final settings = ref.watch(settingsProvider).valueOrNull;
    return AuthState(
      token: settings?.authToken,
      email: settings?.authEmail,
    );
  }

  Future<void> login(String email, String password) async {
    final data = await ref.read(apiServiceProvider).login(email, password);
    await _persist(data['token'] as String, data['email'] as String);
  }

  Future<void> register(String email, String password) async {
    final data = await ref.read(apiServiceProvider).register(email, password);
    await _persist(data['token'] as String, data['email'] as String);
  }

  void logout() {
    state = const AuthState();
    final current = ref.read(settingsProvider).valueOrNull;
    if (current != null) {
      ref.read(settingsProvider.notifier).save(
            current.copyWith(authToken: null, authEmail: null),
          );
    }
  }

  Future<void> fetchProfile() async {
    final token = state.token;
    if (token == null) return;
    try {
      final profile = await ref.read(apiServiceProvider).fetchProfile(token);
      final current = ref.read(settingsProvider).valueOrNull;
      if (current != null) {
        await ref.read(settingsProvider.notifier).save(
              current.copyWith(
                boatType: profile['boatType'] as String?,
                boatName: profile['boatName'] as String?,
                teamName: profile['teamName'] as String?,
              ),
            );
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    String? boatType,
    String? boatName,
    String? teamName,
  }) async {
    final token = state.token;
    if (token == null) return;
    await ref.read(apiServiceProvider).updateProfile(
      token,
      boatType: boatType,
      boatName: boatName,
      teamName: teamName,
    );
    final current = ref.read(settingsProvider).valueOrNull;
    if (current != null) {
      await ref.read(settingsProvider.notifier).save(
            current.copyWith(
              boatType: boatType ?? current.boatType,
              boatName: boatName ?? current.boatName,
              teamName: teamName ?? current.teamName,
            ),
          );
    }
  }

  Future<void> _persist(String token, String email) async {
    state = AuthState(token: token, email: email);
    final current = ref.read(settingsProvider).valueOrNull;
    if (current != null) {
      await ref.read(settingsProvider.notifier).save(
            current.copyWith(authToken: token, authEmail: email),
          );
    }
    // Fetch boat/team profile from server
    fetchProfile();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
