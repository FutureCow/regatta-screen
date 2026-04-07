// lib/providers/tack_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tack_state.dart';
import '../logic/tack_detector.dart';
import '../providers/smoothing_provider.dart';
import '../providers/settings_provider.dart';

final tackStateProvider = NotifierProvider<TackNotifier, TackState>(TackNotifier.new);

class TackNotifier extends Notifier<TackState> {
  final _buffer = <HeadingEntry>[];
  DateTime? _tackDetectedAt;

  @override
  TackState build() {
    ref.listen(smoothedHeadingProvider, (_, next) {
      if (next.hasValue) _onHeading(next.value!);
    });
    return TackState.initial();
  }

  void _onHeading(double heading) {
    if (heading.isNaN || heading.isInfinite) return;
    final now = DateTime.now();
    _buffer.add((value: heading, time: now));
    // Keep only the last 5 seconds
    _buffer.removeWhere(
      (e) => now.difference(e.time) > const Duration(seconds: 5),
    );

    // --- Settling phase ---
    if (_tackDetectedAt != null) {
      final timeSinceTack = now.difference(_tackDetectedAt!);
      final settled = recentHeadingChange(_buffer, 2) < 5.0;

      if (settled || timeSinceTack >= const Duration(seconds: 10)) {
        // Settle: record current heading as the new baseline
        _tackDetectedAt = null;
        state = state.copyWith(
          baseline: heading,
          blocksLeft: 0,
          blocksRight: 0,
          isSettling: false,
        );
      }
      return; // don't do anything else during settling
    }

    // --- Tack detection ---
    if (isTackInBuffer(_buffer)) {
      _tackDetectedAt = now;
      _buffer.clear();
      _buffer.add((value: heading, time: now));
      state = state.copyWith(
        isSettling: true,
        blocksLeft: 0,
        blocksRight: 0,
      );
      return;
    }

    // --- Normal tracking ---
    if (state.baseline == null) return;
    final degreesPerBlock =
        ref.read(settingsProvider).valueOrNull?.tackDegreesPerBlock ?? 3;
    final (left, right) = computeBlocks(
      baseline: state.baseline!,
      current: heading,
      degreesPerBlock: degreesPerBlock,
    );
    state = state.copyWith(blocksLeft: left, blocksRight: right);
  }
}
