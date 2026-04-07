// lib/services/gpx_exporter.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GpxExporter {
  Future<List<File>> listTracks() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.gpx'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  Future<void> share(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Regatta track');
  }

  Future<void> delete(File file) async {
    if (await file.exists()) await file.delete();
  }
}
