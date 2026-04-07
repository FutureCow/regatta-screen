// lib/logic/smoothing.dart
import 'dart:math' as math;

/// Circular mean of compass angles in degrees — handles the 0°/360° wraparound.
double circularMean(List<double> angles) {
  if (angles.isEmpty) return 0;
  final sinSum = angles.fold(0.0, (s, a) => s + math.sin(a * math.pi / 180));
  final cosSum = angles.fold(0.0, (s, a) => s + math.cos(a * math.pi / 180));
  return (math.atan2(sinSum, cosSum) * 180 / math.pi + 360) % 360;
}

/// Simple arithmetic mean. Returns 0 for an empty list.
double simpleAverage(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}
