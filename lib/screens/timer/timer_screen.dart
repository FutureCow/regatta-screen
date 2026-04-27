// lib/screens/timer/timer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/timer_notifier.dart';
import '../../models/timer_state.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerNotifierProvider);
    final notifier = ref.read(timerNotifierProvider.notifier);

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return _LandscapeLayout(state: state, notifier: notifier);
        }
        return _PortraitLayout(state: state, notifier: notifier);
      },
    );
  }
}

// ─── Portrait ────────────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  final TimerState state;
  final TimerNotifier notifier;
  const _PortraitLayout({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _DurationSelector(
            selected: state.duration,
            onSelect: notifier.setDuration,
            enabled: state.status == TimerStatus.idle,
          ),
          Expanded(
            flex: 3,
            child: _TimerDisplay(state: state),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: _RoundButton(label: '−1m', onTap: notifier.roundDown)),
                const SizedBox(width: 16),
                Expanded(child: _RoundButton(label: '+1m', onTap: notifier.roundUp)),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
}

// ─── Landscape ───────────────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final TimerState state;
  final TimerNotifier notifier;
  const _LandscapeLayout({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left: controls column
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _DurationSelector(
                  selected: state.duration,
                  onSelect: notifier.setDuration,
                  enabled: state.status == TimerStatus.idle,
                ),
                const SizedBox(height: 8),
                // Large square round-buttons filling available height
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _RoundButton(
                          label: '−1m',
                          onTap: notifier.roundDown,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoundButton(
                          label: '+1m',
                          onTap: notifier.roundUp,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StartButton(
                        isRunning: state.isRunning,
                        onTap: state.isRunning ? notifier.stop : notifier.start,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ResetButton(onTap: notifier.reset),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: clock fills the space
          Expanded(
            flex: 3,
            child: _TimerDisplay(state: state),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.isCountingDown ? 'AFTELLEN' : 'RACE',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              display,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
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
        height: double.infinity,
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
