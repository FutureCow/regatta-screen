// test/logic/smoothing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:regatta_screen/logic/smoothing.dart';

void main() {
  group('circularMean', () {
    test('returns single value unchanged', () {
      expect(circularMean([45.0]), closeTo(45.0, 0.01));
    });

    test('averages two symmetric angles', () {
      expect(circularMean([80.0, 100.0]), closeTo(90.0, 0.01));
    });

    test('handles 0/360 wraparound', () {
      // Mean of 350° and 10° should be 0° (or 360°)
      final result = circularMean([350.0, 10.0]);
      expect(result < 5.0 || result > 355.0, isTrue,
          reason: 'Expected ~0°, got $result');
    });

    test('handles list of identical values', () {
      expect(circularMean([180.0, 180.0, 180.0]), closeTo(180.0, 0.01));
    });
  });

  group('simpleAverage', () {
    test('returns single value unchanged', () {
      expect(simpleAverage([5.0]), closeTo(5.0, 0.001));
    });

    test('averages multiple values', () {
      expect(simpleAverage([2.0, 4.0, 6.0]), closeTo(4.0, 0.001));
    });

    test('returns 0 for empty list', () {
      expect(simpleAverage([]), closeTo(0.0, 0.001));
    });
  });
}
