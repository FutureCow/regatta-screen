// lib/services/compass_service.dart
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  Stream<double> get headingStream =>
      FlutterCompass.events!
          .where((e) => e.heading != null)
          .map((e) => e.heading!);
}
