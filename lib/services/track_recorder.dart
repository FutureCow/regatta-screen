// lib/services/track_recorder.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gps_point.dart';

class TrackRecorder extends ChangeNotifier {
  final List<GpsPoint> _points = [];
  bool _recording = false;
  StreamSubscription<GpsPoint>? _gpsSub;

  bool get isRecording => _recording;

  /// Start recording. Subscribes to [gpsStream] for GPS points.
  void start(Stream<GpsPoint> gpsStream) {
    _points.clear();
    _gpsSub?.cancel();
    _gpsSub = gpsStream.listen(_addPoint);
    _recording = true;
    notifyListeners();
  }

  void _addPoint(GpsPoint point) {
    if (_recording) _points.add(point);
  }

  Future<File?> stop() async {
    _gpsSub?.cancel();
    _gpsSub = null;
    if (!_recording || _points.isEmpty) {
      _recording = false;
      notifyListeners();
      return null;
    }
    _recording = false;
    notifyListeners();
    return _writeGpx();
  }

  Future<File> _writeGpx() async {
    // getApplicationSupportDirectory avoids the deprecated PathUtils on Android
    final dir = await getApplicationSupportDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final file = File('${dir.path}/track_$ts.gpx');

    final gpx = Gpx()
      ..creator = 'Regatta Screen'
      ..trks = [
        Trk(
          name: 'Race $ts',
          trksegs: [
            Trkseg(
              trkpts: _points
                  .map((p) => Wpt(
                        lat: p.latitude,
                        lon: p.longitude,
                        time: p.timestamp,
                      ))
                  .toList(),
            )
          ],
        )
      ];

    await file.writeAsString(GpxWriter().asString(gpx, pretty: true));
    return file;
  }
}
