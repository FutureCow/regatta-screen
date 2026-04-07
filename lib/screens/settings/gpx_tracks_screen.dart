// lib/screens/settings/gpx_tracks_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gpx_exporter.dart';

final _gpxExporterProvider = Provider<GpxExporter>((ref) => GpxExporter());

final _tracksProvider = FutureProvider<List<File>>((ref) async {
  return ref.watch(_gpxExporterProvider).listTracks();
});

class GpxTracksScreen extends ConsumerWidget {
  const GpxTracksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(_tracksProvider);
    final exporter = ref.read(_gpxExporterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opgeslagen tracks')),
      body: tracksAsync.when(
        data: (tracks) => tracks.isEmpty
            ? const Center(child: Text('Geen tracks opgeslagen'))
            : ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (ctx, i) {
                  final file = tracks[i];
                  final name = file.path.split('/').last;
                  final modified = file.lastModifiedSync();
                  return ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(name),
                    subtitle: Text(
                        '${modified.day}-${modified.month}-${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => exporter.share(file),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await exporter.delete(file);
                            ref.invalidate(_tracksProvider);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fout: $e')),
      ),
    );
  }
}
