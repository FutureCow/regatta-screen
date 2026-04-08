// lib/services/settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/panel_config.dart';

class SettingsService {
  static const _key = 'app_settings_v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return AppSettings.defaults();
    try {
      return _fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(s)));
  }

  Map<String, dynamic> _toJson(AppSettings s) => {
        'speedUnit': s.speedUnit.name,
        'distanceUnit': s.distanceUnit.name,
        'headingMode': s.headingMode.name,
        'darkMode': s.darkMode,
        'keepScreenOn': s.keepScreenOn,
        'windDirectionDeg': s.windDirectionDeg,
        'panel1': s.panel1.toJson(),
        'panel2': s.panel2.toJson(),
        'headingSmoothing': s.headingSmoothing,
        'speedSmoothing': s.speedSmoothing,
        'afterTimerPanel': s.afterTimerPanel,
        'tackIndicatorPanel1': s.tackIndicatorPanel1,
        'tackIndicatorPanel2': s.tackIndicatorPanel2,
        'tackDegreesPerBlock': s.tackDegreesPerBlock,
      };

  AppSettings _fromJson(Map<String, dynamic> j) => AppSettings(
        speedUnit: SpeedUnit.values.byName(j['speedUnit'] as String),
        distanceUnit: DistanceUnit.values.byName(j['distanceUnit'] as String),
        headingMode: HeadingMode.values.byName((j['headingMode'] as String?) ?? 'magnetic'),
        darkMode: j['darkMode'] as bool,
        keepScreenOn: j['keepScreenOn'] as bool,
        windDirectionDeg: (j['windDirectionDeg'] as num?)?.toDouble(),
        panel1: PanelConfig.fromJson(j['panel1'] as Map<String, dynamic>),
        panel2: PanelConfig.fromJson(j['panel2'] as Map<String, dynamic>),
        headingSmoothing: (j['headingSmoothing'] as int?) ?? 1,
        speedSmoothing: (j['speedSmoothing'] as int?) ?? 1,
        afterTimerPanel: j['afterTimerPanel'] as int?,
        tackIndicatorPanel1: (j['tackIndicatorPanel1'] as bool?) ?? false,
        tackIndicatorPanel2: (j['tackIndicatorPanel2'] as bool?) ?? false,
        tackDegreesPerBlock: (j['tackDegreesPerBlock'] as int?) ?? 3,
      );
}
