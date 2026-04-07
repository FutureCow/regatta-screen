// lib/screens/timer/timer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/timer_notifier.dart';
import '../../models/timer_state.dart';
import '../../providers/track_recorder_provider.dart';
import '../../providers/gps_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  StreamSubscription? _gpsSub;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerNotifierProvider);
    final notifier = ref.read(timerNotifierProvider.notifier);
    final recorder = ref.watch(trackRecorderProvider);

    ref.listen(timerNotifierProvider, (prev, next) {
      // Auto-start GPS recording when timer starts and <= 5 min remaining
      if (next.isRunning && !recorder.isRecording) {
        if (next.remaining <= const Duration(minutes: 5)) {
          recorder.start();
          _gpsSub?.cancel();
          _gpsSub = ref
              .read(gpsServiceProvider)
              .positionStream
              .listen((p) => recorder.addPoint(p));
        }
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DurationSelector(
            selected: state.duration,
            onSelect: notifier.setDuration,
            enabled: state.status == TimerStatus.idle,
          ),
          _TimerDisplay(state: state),
          Row(
            children: [
              Expanded(
                child: _RoundButton(label: '−1m', onTap: notifier.roundDown),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoundButton(label: '+1m', onTap: notifier.roundUp),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _StartButton(
                  isRunning: state.isRunning,
                  onTap: state.isRunning ? notifier.stop : notifier.start,
                ),
              ),
              const SizedBox(width: 12),
              _ResetButton(onTap: notifier.reset),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }
}

class _DurationSelector extends StatelessWidget {
  final Duration selected;
  final void Function(Duration) onSelect;
  final bool enabled;

  const _DurationSelector({
    required this.selected,
    required this.onSelect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 15),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options
          .map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DurationChip(
                  label: '${d.inMinutes}m',
                  selected: selected == d,
                  onTap: enabled ? () => onSelect(d) : null,
                ),
              ))
          .toList(),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _DurationChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final TimerState state;
  const _TimerDisplay({required this.state});

  String _format(Duration d) {
    final abs = d.isNegative ? -d : d;
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.isNegative ? '-' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = state.isCountingDown
        ? _format(state.remaining)
        : '+${_format(state.raceElapsed)}';

    return Column(
      children: [
        Text(
          state.isCountingDown ? 'AFTELLEN' : 'RACE',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            display,
            style: theme.textTheme.displayLarge,
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RoundButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;
  const _StartButton({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF166534),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            isRunning ? 'STOP' : 'START',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'RESET',
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
