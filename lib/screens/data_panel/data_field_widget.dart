// lib/screens/data_panel/data_field_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/data_field.dart';
import '../../models/app_settings.dart';
import '../../models/lat_lng.dart';
import '../../models/start_line.dart';
import '../../providers/gps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/start_line_provider.dart';
import '../../providers/smoothing_provider.dart';
import '../../logic/timer_notifier.dart';
import '../../logic/startline_calculator.dart';
import '../../widgets/large_value_display.dart';

class DataFieldWidget extends ConsumerWidget {
  final DataField field;
  final double fontSize;

  const DataFieldWidget({super.key, required this.field, this.fontSize = 48});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (value, unit) = _resolveValue(ref);
    return LargeValueDisplay(
      value: value,
      unit: unit,
      label: field.label,
      fontSize: fontSize,
    );
  }

  (String, String?) _resolveValue(WidgetRef ref) {
    final gps = ref.watch(gpsStreamProvider).valueOrNull;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final timerState = ref.watch(timerNotifierProvider);
    final lineState = ref.watch(startLineProvider);

    switch (field) {
      case DataField.speedGps:
        // Use smoothed speed (m/s), convert to configured unit
        final smoothedMs = ref.watch(smoothedSpeedProvider).valueOrNull;
        if (smoothedMs == null) return ('--', _speedUnit(settings));
        final speed = switch (settings?.speedUnit ?? SpeedUnit.knots) {
          SpeedUnit.knots => smoothedMs * 1.94384,
          SpeedUnit.kmh => smoothedMs * 3.6,
          SpeedUnit.ms => smoothedMs,
        };
        return (speed.toStringAsFixed(1), _speedUnit(settings));

      case DataField.headingGps:
        if (gps?.headingDeg == null) return ('--', '°');
        return (gps!.headingDeg!.toStringAsFixed(0), '°');

      case DataField.headingMagnetic:
        // Use smoothed heading
        final smoothedHeading = ref.watch(smoothedHeadingProvider).valueOrNull;
        if (smoothedHeading == null) return ('--', '°');
        return (smoothedHeading.toStringAsFixed(0), '°');

      case DataField.raceTime:
        final elapsed = timerState.raceElapsed;
        return (_formatDuration(elapsed), null);

      case DataField.countdown:
        return (_formatDuration(timerState.remaining), null);

      case DataField.clockTime:
        return (DateFormat('HH:mm:ss').format(DateTime.now()), null);

      case DataField.distanceToLine:
        final line = lineState.line;
        final pos = gps?.latLng;
        if (line == null || pos == null) return ('--', 'm');
        final d = distanceToLine(pos, line).abs();
        return (d.toStringAsFixed(0), 'm');

      case DataField.vmgToLine:
        final line = lineState.line;
        final pos = gps?.latLng;
        if (line == null || pos == null || gps?.headingDeg == null) {
          return ('--', 'kts');
        }
        final mid = _lineMidpoint(line);
        final vmgMs = vmgToTarget(pos, mid, gps!.headingDeg!, gps.speedMs);
        final vmgKts = vmgMs * 1.94384;
        return (vmgKts.toStringAsFixed(1), 'kts');

      case DataField.latitude:
        if (gps == null) return ('--', null);
        return (gps.latitude.toStringAsFixed(4), '°');

      case DataField.longitude:
        if (gps == null) return ('--', null);
        return (gps.longitude.toStringAsFixed(4), '°');

      case DataField.windDirection:
        if (settings?.windDirectionDeg == null) return ('--', '°');
        return (settings!.windDirectionDeg!.toStringAsFixed(0), '°');
    }
  }

  String _speedUnit(AppSettings? s) => switch (s?.speedUnit ?? SpeedUnit.knots) {
        SpeedUnit.knots => 'kts',
        SpeedUnit.kmh => 'km/h',
        SpeedUnit.ms => 'm/s',
      };

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  LatLng _lineMidpoint(StartLine line) => LatLng(
        (line.pin.lat + line.boat.lat) / 2,
        (line.pin.lng + line.boat.lng) / 2,
      );
}
