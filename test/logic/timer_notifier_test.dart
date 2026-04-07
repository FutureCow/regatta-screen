// test/logic/timer_notifier_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regatta_screen/logic/timer_notifier.dart';
import 'package:regatta_screen/models/timer_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is idle with 5 min remaining', () {
    final state = container.read(timerNotifierProvider);
    expect(state.status, TimerStatus.idle);
    expect(state.remaining, const Duration(minutes: 5));
  });

  test('start changes status to running', () {
    container.read(timerNotifierProvider.notifier).start();
    expect(container.read(timerNotifierProvider).status, TimerStatus.running);
  });

  test('stop changes status to paused', () {
    container.read(timerNotifierProvider.notifier).start();
    container.read(timerNotifierProvider.notifier).stop();
    expect(container.read(timerNotifierProvider).status, TimerStatus.paused);
  });

  test('reset restores duration and idle status', () {
    container.read(timerNotifierProvider.notifier).start();
    container.read(timerNotifierProvider.notifier).reset();
    final state = container.read(timerNotifierProvider);
    expect(state.status, TimerStatus.idle);
    expect(state.remaining, state.duration);
  });

  test('setDuration updates duration and remaining when idle', () {
    container.read(timerNotifierProvider.notifier).setDuration(const Duration(minutes: 10));
    final state = container.read(timerNotifierProvider);
    expect(state.duration, const Duration(minutes: 10));
    expect(state.remaining, const Duration(minutes: 10));
  });

  test('roundDown snaps remaining to nearest full minute below', () {
    // Set remaining to 4:32 manually
    final notifier = container.read(timerNotifierProvider.notifier);
    notifier.setRemaining(const Duration(minutes: 4, seconds: 32));
    notifier.roundDown();
    expect(container.read(timerNotifierProvider).remaining, const Duration(minutes: 4));
  });

  test('roundUp snaps remaining to nearest full minute above', () {
    final notifier = container.read(timerNotifierProvider.notifier);
    notifier.setRemaining(const Duration(minutes: 4, seconds: 32));
    notifier.roundUp();
    expect(container.read(timerNotifierProvider).remaining, const Duration(minutes: 5));
  });

  test('roundDown on exact minute leaves unchanged', () {
    final notifier = container.read(timerNotifierProvider.notifier);
    notifier.setRemaining(const Duration(minutes: 4));
    notifier.roundDown();
    expect(container.read(timerNotifierProvider).remaining, const Duration(minutes: 4));
  });
}
