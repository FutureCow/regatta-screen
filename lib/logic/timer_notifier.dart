// lib/logic/timer_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';

final timerNotifierProvider =
    NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() => TimerState.initial();

  void start() {
    if (state.status == TimerStatus.running) return;
    state = state.copyWith(status: TimerStatus.running);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _ticker?.cancel();
    if (state.status == TimerStatus.running) {
      state = state.copyWith(status: TimerStatus.paused);
    }
  }

  void reset() {
    _ticker?.cancel();
    state = TimerState.initial().copyWith(
      duration: state.duration,
      remaining: state.duration,
    );
  }

  void setDuration(Duration d) {
    if (state.status == TimerStatus.idle) {
      state = state.copyWith(duration: d, remaining: d);
    }
  }

  void roundDown() {
    final secs = state.remaining.inSeconds;
    final rounded = (secs ~/ 60) * 60;
    state = state.copyWith(remaining: Duration(seconds: rounded));
  }

  void roundUp() {
    final secs = state.remaining.inSeconds;
    if (secs % 60 == 0) return;
    final rounded = ((secs ~/ 60) + 1) * 60;
    state = state.copyWith(remaining: Duration(seconds: rounded));
  }

  /// For testing only
  void setRemaining(Duration d) {
    state = state.copyWith(remaining: d);
  }

  void _tick() {
    if (state.remaining > Duration.zero) {
      // Counting down
      state = state.copyWith(
        remaining: state.remaining - const Duration(seconds: 1),
      );
    } else if (state.isRunning) {
      // Counting up (race in progress) — increment raceElapsedSeconds to force rebuild
      state = state.copyWith(
        raceElapsedSeconds: state.raceElapsedSeconds + 1,
      );
    }
  }
}
