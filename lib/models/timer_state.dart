// lib/models/timer_state.dart
enum TimerStatus { idle, running, paused }

class TimerState {
  final TimerStatus status;
  final Duration duration;
  final Duration remaining;
  final DateTime? startedAt;

  const TimerState({
    required this.status,
    required this.duration,
    required this.remaining,
    this.startedAt,
  });

  factory TimerState.initial() => const TimerState(
        status: TimerStatus.idle,
        duration: Duration(minutes: 5),
        remaining: Duration(minutes: 5),
      );

  bool get isRunning => status == TimerStatus.running;
  bool get isCountingDown => remaining > Duration.zero;

  /// Positive elapsed time after start (0 during countdown)
  Duration get raceElapsed =>
      startedAt != null && !isCountingDown
          ? DateTime.now().difference(startedAt!.add(duration))
          : Duration.zero;

  TimerState copyWith({
    TimerStatus? status,
    Duration? duration,
    Duration? remaining,
    DateTime? startedAt,
  }) =>
      TimerState(
        status: status ?? this.status,
        duration: duration ?? this.duration,
        remaining: remaining ?? this.remaining,
        startedAt: startedAt ?? this.startedAt,
      );
}
