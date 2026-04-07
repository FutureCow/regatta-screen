// lib/providers/compass_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compass_service.dart';

final compassServiceProvider = Provider<CompassService>((ref) => CompassService());

final compassStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(compassServiceProvider).headingStream;
});
