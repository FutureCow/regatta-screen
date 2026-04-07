// lib/logic/tack_detector.dart
// Pure functions used by TackNotifier. Exported for testing.

typedef HeadingEntry = ({double value, DateTime time});

/// Signed angular difference from [from] to [to], range −180 to +180.
/// Positive = clockwise/starboard, negative = counter-clockwise/port (bakboord).
double angularDiff(double from, double to) {
  return ((to - from + 540) % 360) - 180;
}

/// Returns true if the angular change between the first and last entry
/// in [buf] is >= 80°.
bool isTackInBuffer(List<HeadingEntry> buf) {
  if (buf.length < 2) return false;
  return angularDiff(buf.first.value, buf.last.value).abs() >= 80;
}

/// Returns the absolute angular change from the oldest entry within
/// the last [windowSeconds] seconds to the newest entry in [buf].
double recentHeadingChange(List<HeadingEntry> buf, int windowSeconds) {
  if (buf.isEmpty) return 0;
  final cutoff = buf.last.time.subtract(Duration(seconds: windowSeconds));
  final recent = buf.where((e) => !e.time.isBefore(cutoff)).toList();
  if (recent.length < 2) return 0;
  return angularDiff(recent.first.value, recent.last.value).abs();
}

/// Computes (blocksLeft, blocksRight) from deviation of [current] from [baseline].
/// Port/bakboord deviation → blocksLeft; starboard/stuurboord → blocksRight.
/// Each block represents [degreesPerBlock] degrees, capped at 5 (max visible blocks).
/// Capping is intentional — larger deviations still show as 5 blocks.
(int, int) computeBlocks({
  required double baseline,
  required double current,
  required int degreesPerBlock,
}) {
  final safeDeg = degreesPerBlock < 1 ? 1 : degreesPerBlock;
  final diff = angularDiff(baseline, current);
  final blocks = (diff.abs() / safeDeg).floor().clamp(0, 5);
  if (diff < 0) return (blocks, 0); // port = left
  if (diff > 0) return (0, blocks); // starboard = right
  return (0, 0);
}
