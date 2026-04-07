// lib/models/timer_state.dart
enum TimerStatus { idle, running, paused }

class TimerState {
  final TimerStatus status;
  final Duration duration;
  final Duration remaining;
  // Seconds elapsed since the gun (remaining reached 0). Incremented by ticker.
  final int raceElapsedSeconds;

  const TimerState({
    required this.status,
    required this.duration,
    required this.remaining,
    this.raceElapsedSeconds = 0,
  });

  factory TimerState.initial() => const TimerState(
        status: TimerStatus.idle,
        duration: Duration(minutes: 5),
        remaining: Duration(minutes: 5),
      );

  bool get isRunning => status == TimerStatus.running;
  bool get isCountingDown => remaining > Duration.zero;

  Duration get raceElapsed => Duration(seconds: raceElapsedSeconds);

  TimerState copyWith({
    TimerStatus? status,
    Duration? duration,
    Duration? remaining,
    int? raceElapsedSeconds,
  }) =>
      TimerState(
        status: status ?? this.status,
        duration: duration ?? this.duration,
        remaining: remaining ?? this.remaining,
        raceElapsedSeconds: raceElapsedSeconds ?? this.raceElapsedSeconds,
      );
}
