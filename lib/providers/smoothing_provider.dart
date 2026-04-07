// lib/providers/smoothing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/smoothing.dart';
import '../providers/compass_provider.dart';
import '../providers/gps_provider.dart';
import '../providers/settings_provider.dart';

/// Smoothed compass heading (degrees) using circular mean over last N seconds.
/// N is configured via settingsProvider.headingSmoothing (read on each data point).
final smoothedHeadingProvider = StreamProvider<double>((ref) async* {
  final compassService = ref.read(compassServiceProvider);
  final buffer = <({double value, DateTime time})>[];

  await for (final h in compassService.headingStream) {
    final seconds =
        ref.read(settingsProvider).valueOrNull?.headingSmoothing ?? 1;
    final now = DateTime.now();
    buffer.add((value: h, time: now));
    buffer.removeWhere(
      (e) => now.difference(e.time) > Duration(seconds: seconds),
    );
    yield circularMean(buffer.map((e) => e.value).toList());
  }
});

/// Smoothed GPS speed (m/s) using arithmetic mean over last N seconds.
/// N is configured via settingsProvider.speedSmoothing (read on each data point).
final smoothedSpeedProvider = StreamProvider<double>((ref) async* {
  final gpsService = ref.read(gpsServiceProvider);
  final buffer = <({double value, DateTime time})>[];

  await for (final p in gpsService.positionStream) {
    final seconds =
        ref.read(settingsProvider).valueOrNull?.speedSmoothing ?? 1;
    final now = DateTime.now();
    buffer.add((value: p.speedMs, time: now));
    buffer.removeWhere(
      (e) => now.difference(e.time) > Duration(seconds: seconds),
    );
    yield simpleAverage(buffer.map((e) => e.value).toList());
  }
});
