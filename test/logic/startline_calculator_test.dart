// test/logic/startline_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:regatta_screen/logic/startline_calculator.dart';
import 'package:regatta_screen/models/lat_lng.dart';
import 'package:regatta_screen/models/start_line.dart';

void main() {
  group('haversineDistance', () {
    test('returns ~0 for identical points', () {
      final p = LatLng(52.370, 4.895);
      expect(haversineDistance(p, p), closeTo(0, 0.01));
    });

    test('returns ~111 km per degree latitude', () {
      final a = LatLng(0.0, 0.0);
      final b = LatLng(1.0, 0.0);
      expect(haversineDistance(a, b), closeTo(111195, 100));
    });

    test('200m line between two close points', () {
      // 0.002° latitude ≈ 222m
      final a = LatLng(52.370, 4.895);
      final b = LatLng(52.372, 4.895);
      expect(haversineDistance(a, b), closeTo(222, 5));
    });
  });

  group('bearingBetween', () {
    test('north is 0 degrees', () {
      final from = LatLng(52.0, 4.0);
      final to = LatLng(53.0, 4.0);
      expect(bearingBetween(from, to), closeTo(0, 1));
    });

    test('east is 90 degrees', () {
      final from = LatLng(52.0, 4.0);
      final to = LatLng(52.0, 5.0);
      expect(bearingBetween(from, to), closeTo(90, 2));
    });
  });

  group('distanceToLine', () {
    // Line runs east-west at lat 52.370
    final pin = LatLng(52.370, 4.890);
    final boat = LatLng(52.370, 4.900);
    final line = StartLine(pin: pin, boat: boat);

    test('point on line has distance ~0', () {
      final onLine = LatLng(52.370, 4.895);
      expect(distanceToLine(onLine, line).abs(), lessThan(2));
    });

    test('point north of east-west line is negative (in front)', () {
      final north = LatLng(52.371, 4.895);
      expect(distanceToLine(north, line), isNegative);
    });

    test('point south of east-west line is positive (behind)', () {
      final south = LatLng(52.369, 4.895);
      expect(distanceToLine(south, line), isPositive);
    });
  });

  group('lineBias', () {
    // Line runs east (090°) — square wind is 180° (south)
    final pin = LatLng(52.370, 4.890);
    final boat = LatLng(52.370, 4.900);
    final line = StartLine(pin: pin, boat: boat);

    test('square wind returns square', () {
      expect(lineBias(line, 180), equals('square'));
    });

    test('wind from SE (135°) favors pin', () {
      expect(lineBias(line, 135), equals('pin'));
    });

    test('wind from SW (225°) favors boat', () {
      expect(lineBias(line, 225), equals('boat'));
    });
  });
}
