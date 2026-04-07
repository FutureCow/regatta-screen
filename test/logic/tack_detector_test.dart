// test/logic/tack_detector_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:regatta_screen/logic/tack_detector.dart';

void main() {
  group('angularDiff', () {
    test('positive delta (turning right/starboard)', () {
      expect(angularDiff(90, 100), closeTo(10, 0.01));
    });

    test('negative delta (turning left/port)', () {
      expect(angularDiff(90, 80), closeTo(-10, 0.01));
    });

    test('wraparound: 350 to 10 is +20', () {
      expect(angularDiff(350, 10), closeTo(20, 0.01));
    });

    test('wraparound: 10 to 350 is -20', () {
      expect(angularDiff(10, 350), closeTo(-20, 0.01));
    });
  });

  group('isTackInBuffer', () {
    test('returns false when change < 80°', () {
      final buf = [
        (value: 90.0, time: DateTime(2024, 1, 1, 0, 0, 0)),
        (value: 130.0, time: DateTime(2024, 1, 1, 0, 0, 3)),
      ];
      expect(isTackInBuffer(buf), isFalse);
    });

    test('returns true when change >= 80°', () {
      final buf = [
        (value: 90.0, time: DateTime(2024, 1, 1, 0, 0, 0)),
        (value: 175.0, time: DateTime(2024, 1, 1, 0, 0, 4)),
      ];
      expect(isTackInBuffer(buf), isTrue);
    });

    test('handles wraparound tack near 0°', () {
      final buf = [
        (value: 355.0, time: DateTime(2024, 1, 1, 0, 0, 0)),
        (value: 275.0, time: DateTime(2024, 1, 1, 0, 0, 4)),
      ];
      expect(isTackInBuffer(buf), isTrue);
    });

    test('returns false for empty/single-element buffer', () {
      expect(isTackInBuffer([]), isFalse);
      expect(
        isTackInBuffer([(value: 90.0, time: DateTime(2024))]),
        isFalse,
      );
    });
  });

  group('recentHeadingChange', () {
    test('returns 0 for single point', () {
      final buf = [(value: 90.0, time: DateTime(2024, 1, 1, 0, 0, 0))];
      expect(recentHeadingChange(buf, 2), closeTo(0, 0.01));
    });

    test('returns change over last N seconds only', () {
      final t = DateTime(2024, 1, 1, 0, 0, 0);
      final buf = [
        (value: 50.0, time: t),                           // 10 seconds ago — excluded
        (value: 90.0, time: t.add(const Duration(seconds: 9))),  // 1 second ago
        (value: 95.0, time: t.add(const Duration(seconds: 10))), // now
      ];
      // Only last 2 seconds: 90→95 = 5°
      expect(recentHeadingChange(buf, 2), closeTo(5, 0.01));
    });
  });

  group('computeBlocks', () {
    test('no deviation → 0 blocks each side', () {
      final (left, right) = computeBlocks(baseline: 90, current: 90, degreesPerBlock: 3);
      expect(left, 0);
      expect(right, 0);
    });

    test('6° to port (left) with 3 deg/block → 2 blocks left', () {
      final (left, right) = computeBlocks(baseline: 90, current: 84, degreesPerBlock: 3);
      expect(left, 2);
      expect(right, 0);
    });

    test('9° to starboard (right) → 3 blocks right', () {
      final (left, right) = computeBlocks(baseline: 90, current: 99, degreesPerBlock: 3);
      expect(left, 0);
      expect(right, 3);
    });

    test('deviation > 15° with 3 deg/block → capped at 5', () {
      final (left, right) = computeBlocks(baseline: 90, current: 120, degreesPerBlock: 3);
      expect(left, 0);
      expect(right, 5);
    });

    test('handles wraparound correctly', () {
      // baseline 5°, current 355° → 10° to port
      final (left, right) = computeBlocks(baseline: 5, current: 355, degreesPerBlock: 3);
      expect(left, 3);
      expect(right, 0);
    });
  });
}
