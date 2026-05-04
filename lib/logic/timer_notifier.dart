// lib/logic/timer_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timer_state.dart';

final timerNotifierProvider =
    NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;
  DateTime? _lastRoundUpAt;

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

  void setTimerTo(Duration d) {
    _ticker?.cancel();
    state = TimerState.initial().copyWith(duration: d, remaining: d);
  }

  void roundDown() {
    final secs = state.remaining.inSeconds;
    final rounded = (secs ~/ 60) * 60;
    state = state.copyWith(remaining: Duration(seconds: rounded));
  }

  void roundUp() {
    final now = DateTime.now();
    final secs = state.remaining.inSeconds;
    if (_lastRoundUpAt != null &&
        now.difference(_lastRoundUpAt!) < const Duration(seconds: 2)) {
      // Subsequent tap within 2s: add 1 minute on top
      state = state.copyWith(
        remaining: state.remaining + const Duration(minutes: 1),
      );
    } else {
      // First tap: round up to next minute boundary
      if (secs % 60 != 0) {
        final rounded = ((secs ~/ 60) + 1) * 60;
        state = state.copyWith(remaining: Duration(seconds: rounded));
      }
    }
    _lastRoundUpAt = now;
  }

  /// For testing only
  void setRemaining(Duration d) {
    state = state.copyWith(remaining: d);
  }

  void _tick() {
    if (state.remaining > Duration.zero) {
      state = state.copyWith(
        remaining: state.remaining - const Duration(seconds: 1),
      );
    } else if (state.isRunning) {
      state = state.copyWith(
        raceElapsedSeconds: state.raceElapsedSeconds + 1,
      );
    }
  }
}
