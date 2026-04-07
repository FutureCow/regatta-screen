// test/services/settings_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:regatta_screen/models/app_settings.dart';
import 'package:regatta_screen/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns defaults when nothing saved', () async {
    final svc = SettingsService();
    final settings = await svc.load();
    expect(settings.darkMode, isTrue);
    expect(settings.speedUnit, SpeedUnit.knots);
    expect(settings.panel1.fieldCount, 2);
  });

  test('save and reload preserves darkMode=false', () async {
    final svc = SettingsService();
    final original = AppSettings.defaults().copyWith(darkMode: false);
    await svc.save(original);
    final loaded = await svc.load();
    expect(loaded.darkMode, isFalse);
  });

  test('save and reload preserves windDirectionDeg', () async {
    final svc = SettingsService();
    final s = AppSettings.defaults().copyWith(windDirectionDeg: 225.0);
    await svc.save(s);
    final loaded = await svc.load();
    expect(loaded.windDirectionDeg, closeTo(225.0, 0.01));
  });
}
