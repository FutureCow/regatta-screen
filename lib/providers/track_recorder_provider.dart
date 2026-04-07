// lib/providers/track_recorder_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/track_recorder.dart';

final trackRecorderProvider = Provider<TrackRecorder>((ref) => TrackRecorder());
