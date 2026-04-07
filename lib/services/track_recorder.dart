// lib/services/track_recorder.dart
import 'dart:io';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gps_point.dart';

class TrackRecorder {
  final List<GpsPoint> _points = [];
  bool _recording = false;

  bool get isRecording => _recording;

  void start() {
    _points.clear();
    _recording = true;
  }

  void addPoint(GpsPoint point) {
    if (_recording) _points.add(point);
  }

  Future<File?> stop() async {
    if (!_recording || _points.isEmpty) {
      _recording = false;
      return null;
    }
    _recording = false;
    return _writeGpx();
  }

  Future<File> _writeGpx() async {
    final dir = await getApplicationDocumentsDirectory();
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
