// lib/providers/gps_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gps_point.dart';
import '../services/gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());

final gpsStreamProvider = StreamProvider<GpsPoint>((ref) {
  return ref.watch(gpsServiceProvider).positionStream;
});
