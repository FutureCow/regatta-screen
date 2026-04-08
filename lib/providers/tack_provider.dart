// lib/providers/tack_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tack_state.dart';
import '../logic/tack_detector.dart';
import '../logic/smoothing.dart';
import '../providers/smoothing_provider.dart';
import '../providers/settings_provider.dart';

final tackStateProvider =
    NotifierProvider<TackNotifier, TackState>(TackNotifier.new);

class TackNotifier extends Notifier<TackState> {
  final _buffer = <HeadingEntry>[];
  DateTime? _tackDetectedAt;

  /// Candidates from the first tack before wind direction is known.
  /// Tuple of (candidate, candidateFlip) — two options 180° apart.
  (double, double)? _pendingCandidates;

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
        final prevBaseline = state.baseline;
        _tackDetectedAt = null;
        state = state.copyWith(
          baseline: heading,
          blocksLeft: 0,
          blocksRight: 0,
          isSettling: false,
        );
        // Estimate wind direction from the two headings
        if (prevBaseline != null) {
          _estimateWindDirection(prevBaseline, heading);
        }
      }
      return;
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

  /// Estimates wind direction from two close-hauled headings (before and after tack).
  ///
  /// First tack: stores two candidates (180° apart) in [_pendingCandidates].
  /// Second tack: resolves ambiguity by picking the pending candidate closest
  ///   to the new tack's candidates.
  /// Subsequent tacks: refines existing wind direction by picking the closest candidate.
  void _estimateWindDirection(double h1, double h2) {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null) return;

    final candidate = circularMean([h1, h2]);
    final candidateFlip = (candidate + 180) % 360;

    if (settings.windDirectionDeg != null) {
      // Refine existing wind: pick candidate closest to current value.
      // When equidistant (diffA == diffB), prefer candidate over its flip.
      final existing = settings.windDirectionDeg!;
      final diffA = angularDiff(existing, candidate).abs();
      final diffB = angularDiff(existing, candidateFlip).abs();
      final newWind = diffA <= diffB ? candidate : candidateFlip;
      ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(windDirectionDeg: newWind));
    } else if (_pendingCandidates == null) {
      // First tack: store both candidates, don't save yet — need second tack to disambiguate.
      _pendingCandidates = (candidate, candidateFlip);
    } else {
      // Second tack: pick the pending candidate (c1 or c2) that is closest to
      // either of the new tack's candidates, resolving the 180° ambiguity.
      final (c1, c2) = _pendingCandidates!;
      final pairs = [
        (angularDiff(c1, candidate).abs(), c1),
        (angularDiff(c1, candidateFlip).abs(), c1),
        (angularDiff(c2, candidate).abs(), c2),
        (angularDiff(c2, candidateFlip).abs(), c2),
      ];
      pairs.sort((a, b) => a.$1.compareTo(b.$1));
      final bestWind = pairs.first.$2;
      _pendingCandidates = null;
      ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(windDirectionDeg: bestWind));
    }
  }
}
