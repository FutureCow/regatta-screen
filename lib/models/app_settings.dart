// lib/models/app_settings.dart
import 'panel_config.dart';

enum SpeedUnit { knots, kmh, ms }
enum DistanceUnit { meters, nauticalMiles }
enum HeadingMode { magnetic, trueNorth }

class AppSettings {
  final SpeedUnit speedUnit;
  final DistanceUnit distanceUnit;
  final HeadingMode headingMode;
  final bool darkMode;
  final bool keepScreenOn;
  final double? windDirectionDeg;
  final PanelConfig panel1;
  final PanelConfig panel2;

  const AppSettings({
    this.speedUnit = SpeedUnit.knots,
    this.distanceUnit = DistanceUnit.meters,
    this.headingMode = HeadingMode.magnetic,
    this.darkMode = true,
    this.keepScreenOn = true,
    this.windDirectionDeg,
    required this.panel1,
    required this.panel2,
  });

  factory AppSettings.defaults() => AppSettings(
        panel1: PanelConfig.defaults1(),
        panel2: PanelConfig.defaults2(),
      );

  // Sentinel so copyWith can distinguish "not passed" from "explicitly null"
  static const _unset = Object();

  AppSettings copyWith({
    SpeedUnit? speedUnit,
    DistanceUnit? distanceUnit,
    HeadingMode? headingMode,
    bool? darkMode,
    bool? keepScreenOn,
    Object? windDirectionDeg = _unset, // use _unset sentinel to allow null
    PanelConfig? panel1,
    PanelConfig? panel2,
  }) =>
      AppSettings(
        speedUnit: speedUnit ?? this.speedUnit,
        distanceUnit: distanceUnit ?? this.distanceUnit,
        headingMode: headingMode ?? this.headingMode,
        darkMode: darkMode ?? this.darkMode,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        windDirectionDeg: windDirectionDeg == _unset
            ? this.windDirectionDeg
            : windDirectionDeg as double?,
        panel1: panel1 ?? this.panel1,
        panel2: panel2 ?? this.panel2,
      );
}
