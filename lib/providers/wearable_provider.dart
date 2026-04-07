// lib/providers/wearable_provider.dart
// Stub interface for wearable command handling.
// Concrete implementations are in separate plans (Wear OS, Apple Watch, Garmin).
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WearableCommandHandler {
  void onTimerStart();
  void onTimerStop();
  void onNextScreen();
  void onPreviousScreen();
}

class NoOpWearableHandler implements WearableCommandHandler {
  @override void onTimerStart() {}
  @override void onTimerStop() {}
  @override void onNextScreen() {}
  @override void onPreviousScreen() {}
}

final wearableHandlerProvider = Provider<WearableCommandHandler>(
  (ref) => NoOpWearableHandler(),
);
