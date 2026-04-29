import 'dart:async';
import 'package:flutter/services.dart';

/// Commando's die de Garmin watch kan sturen
enum GarminCommand { startStop, plusOne, minusOne }

class GarminService {
  static const _method = MethodChannel('nl.regattascreen/garmin');
  static const _events = EventChannel('nl.regattascreen/garmin_events');

  Stream<GarminCommand>? _commandStream;

  /// Stream van commando's van het horloge.
  Stream<GarminCommand> get commands {
    _commandStream ??= _events
        .receiveBroadcastStream()
        .map((event) => _parse(event as String))
        .where((cmd) => cmd != null)
        .cast<GarminCommand>();
    return _commandStream!;
  }

  /// Stuur de huidige timerstatus naar het horloge.
  Future<void> sendTimerState({
    required int remainingSeconds,
    required bool running,
  }) async {
    try {
      await _method.invokeMethod('sendTimerState', {
        'remaining': remainingSeconds,
        'running': running,
      });
    } on PlatformException {
      // Horloge niet verbonden — stil negeren
    }
  }

  GarminCommand? _parse(String cmd) {
    switch (cmd) {
      case 'start_stop': return GarminCommand.startStop;
      case 'plus_one':   return GarminCommand.plusOne;
      case 'minus_one':  return GarminCommand.minusOne;
      default:           return null;
    }
  }
}
