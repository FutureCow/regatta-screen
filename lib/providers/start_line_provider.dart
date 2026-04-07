// lib/providers/start_line_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lat_lng.dart';
import '../models/start_line.dart';

class StartLineState {
  final LatLng? pin;
  final LatLng? boat;
  const StartLineState({this.pin, this.boat});
  bool get isComplete => pin != null && boat != null;
  StartLine? get line => isComplete ? StartLine(pin: pin!, boat: boat!) : null;
  StartLineState copyWith({LatLng? pin, LatLng? boat}) =>
      StartLineState(pin: pin ?? this.pin, boat: boat ?? this.boat);
}

final startLineProvider =
    NotifierProvider<StartLineNotifier, StartLineState>(StartLineNotifier.new);

class StartLineNotifier extends Notifier<StartLineState> {
  @override
  StartLineState build() => const StartLineState();

  void setPin(LatLng point) => state = state.copyWith(pin: point);
  void setBoat(LatLng point) => state = state.copyWith(boat: point);
  void clearPin() => state = StartLineState(boat: state.boat);
  void clearBoat() => state = StartLineState(pin: state.pin);
}
