// lib/logic/startline_calculator.dart
import 'dart:math' as math;
import '../models/lat_lng.dart';
import '../models/start_line.dart';

double haversineDistance(LatLng a, LatLng b) {
  const r = 6371000.0;
  final lat1 = a.lat * math.pi / 180;
  final lat2 = b.lat * math.pi / 180;
  final dLat = (b.lat - a.lat) * math.pi / 180;
  final dLng = (b.lng - a.lng) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double bearingBetween(LatLng from, LatLng to) {
  final dLng = (to.lng - from.lng) * math.pi / 180;
  final lat1 = from.lat * math.pi / 180;
  final lat2 = to.lat * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Signed distance from [position] to the start line.
/// Negative = in front of line (start side), positive = behind.
double distanceToLine(LatLng position, StartLine line) {
  final p1 = line.pin;
  final p2 = line.boat;
  const metersPerDeg = 111319.0;
  final cosLat = math.cos(p1.lat * math.pi / 180);
  final x2 = (p2.lng - p1.lng) * cosLat * metersPerDeg;
  final y2 = (p2.lat - p1.lat) * metersPerDeg;
  final xp = (position.lng - p1.lng) * cosLat * metersPerDeg;
  final yp = (position.lat - p1.lat) * metersPerDeg;
  final lineLen = math.sqrt(x2 * x2 + y2 * y2);
  if (lineLen == 0) return haversineDistance(position, p1);
  return (x2 * (0 - yp) - (0 - xp) * y2) / lineLen;
}

/// Returns 'pin', 'boat', or 'square' (within ±2° of 90°).
String lineBias(StartLine line, double windDirectionDeg) {
  final lb = bearingBetween(line.pin, line.boat);
  double angle = (windDirectionDeg - lb + 360) % 360;
  if (angle > 180) angle = 360 - angle;
  final deviation = angle - 90;
  if (deviation.abs() <= 2) return 'square';
  return deviation < 0 ? 'pin' : 'boat';
}

/// VMG of [speedMs] toward [target] given current [headingDeg].
double vmgToTarget(LatLng position, LatLng target, double headingDeg, double speedMs) {
  final bearing = bearingBetween(position, target);
  final angle = (headingDeg - bearing + 360) % 360;
  return speedMs * math.cos(angle * math.pi / 180);
}
