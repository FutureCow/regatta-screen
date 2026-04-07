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
  // Smoothing: number of seconds for rolling average (1, 3, 5, or 10)
  final int headingSmoothing;
  final int speedSmoothing;
  // After countdown reaches 0: null = stay, 1 = panel 1, 2 = panel 2
  final int? afterTimerPanel;
  // Tack indicator: show on each panel?
  final bool tackIndicatorPanel1;
  final bool tackIndicatorPanel2;
  // Degrees of heading change per tack indicator block (default 3)
  final int tackDegreesPerBlock;

  const AppSettings({
    this.speedUnit = SpeedUnit.knots,
    this.distanceUnit = DistanceUnit.meters,
    this.headingMode = HeadingMode.magnetic,
    this.darkMode = true,
    this.keepScreenOn = true,
    this.windDirectionDeg,
    required this.panel1,
    required this.panel2,
    this.headingSmoothing = 1,
    this.speedSmoothing = 1,
    this.afterTimerPanel,
    this.tackIndicatorPanel1 = false,
    this.tackIndicatorPanel2 = false,
    this.tackDegreesPerBlock = 3,
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
    Object? windDirectionDeg = _unset,
    PanelConfig? panel1,
    PanelConfig? panel2,
    int? headingSmoothing,
    int? speedSmoothing,
    Object? afterTimerPanel = _unset,
    bool? tackIndicatorPanel1,
    bool? tackIndicatorPanel2,
    int? tackDegreesPerBlock,
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
        headingSmoothing: headingSmoothing ?? this.headingSmoothing,
        speedSmoothing: speedSmoothing ?? this.speedSmoothing,
        afterTimerPanel: afterTimerPanel == _unset
            ? this.afterTimerPanel
            : afterTimerPanel as int?,
        tackIndicatorPanel1: tackIndicatorPanel1 ?? this.tackIndicatorPanel1,
        tackIndicatorPanel2: tackIndicatorPanel2 ?? this.tackIndicatorPanel2,
        tackDegreesPerBlock: tackDegreesPerBlock ?? this.tackDegreesPerBlock,
      );
}
