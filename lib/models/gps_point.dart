// lib/models/gps_point.dart
import 'lat_lng.dart';

class GpsPoint {
  final double latitude;
  final double longitude;
  final double speedMs;
  final double? headingDeg;
  final DateTime timestamp;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.speedMs,
    this.headingDeg,
    required this.timestamp,
  });

  double get speedKnots => speedMs * 1.94384;
  double get speedKmh => speedMs * 3.6;
  LatLng get latLng => LatLng(latitude, longitude);
}
