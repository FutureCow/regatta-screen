// lib/screens/settings/gpx_tracks_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/api_service.dart';
import '../../services/gpx_exporter.dart';

final _gpxExporterProvider = Provider<GpxExporter>((ref) => GpxExporter());

final _tracksProvider = FutureProvider<List<File>>((ref) async {
  return ref.watch(_gpxExporterProvider).listTracks();
});

class GpxTracksScreen extends ConsumerStatefulWidget {
  const GpxTracksScreen({super.key});

  @override
  ConsumerState<GpxTracksScreen> createState() => _GpxTracksScreenState();
}

class _GpxTracksScreenState extends ConsumerState<GpxTracksScreen> {
  final Set<String> _uploading = {};
  // filename → server track id (null = not on server yet)
  final Map<String, int?> _serverTracks = {};
  bool _serverChecked = false;

  @override
  void initState() {
    super.initState();
    _loadServerTracks();
  }

  Future<void> _loadServerTracks() async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    try {
      final tracks =
          await ref.read(apiServiceProvider).listServerTracks(auth.token!);
      if (mounted) {
        setState(() {
          _serverTracks.clear();
          for (final t in tracks) {
            _serverTracks[t['filename'] as String] = t['id'] as int?;
          }
          _serverChecked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _serverChecked = true);
    }
  }

  Future<void> _upload(File file) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    final filename = file.uri.pathSegments.last;
    setState(() => _uploading.add(filename));
    try {
      final settings = ref.read(settingsProvider).valueOrNull;
      await ref.read(apiServiceProvider).uploadTrack(
            file, auth.token!,
            windDirectionDeg: settings?.windDirectionDeg,
          );
      final updated =
          await ref.read(apiServiceProvider).listServerTracks(auth.token!);
      if (mounted) {
        setState(() {
          _uploading.remove(filename);
          for (final t in updated) {
            _serverTracks[t['filename'] as String] = t['id'] as int?;
          }
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Track geüpload')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading.remove(filename));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload mislukt: $e')));
      }
    }
  }

  Future<void> _linkToRace(String filename) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    final trackId = _serverTracks[filename];
    if (trackId == null) return;

    List<Map<String, dynamic>> races = [];
    try {
      races = await ref.read(apiServiceProvider).listRaces(auth.token!);
    } catch (_) {}

    if (!mounted) return;

    if (races.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen wedstrijden beschikbaar')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => _RacePicker(
        races: races,
        token: auth.token!,
        trackId: trackId,
        apiService: ref.read(apiServiceProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(_tracksProvider);
    final exporter = ref.read(_gpxExporterProvider);
    final auth = ref.watch(authProvider);
    final loggedIn = auth.token != null;

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
                  final isUploading = _uploading.contains(name);
                  final onServer = _serverChecked && _serverTracks.containsKey(name);

                  return ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(name),
                    subtitle: Text(
                      '${modified.day}-${modified.month}-${modified.year} '
                      '${modified.hour}:${modified.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loggedIn)
                          if (isUploading)
                            const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (onServer) ...[
                            Tooltip(
                              message: 'Koppel aan wedstrijd',
                              child: IconButton(
                                icon: const Icon(Icons.flag_outlined),
                                onPressed: () => _linkToRace(name),
                              ),
                            ),
                            const Tooltip(
                              message: 'Al op server',
                              child: Icon(Icons.cloud_done, color: Colors.green),
                            ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.cloud_upload_outlined),
                              tooltip: 'Uploaden naar server',
                              onPressed: () => _upload(file),
                            ),
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

// ── Race picker bottom sheet ──────────────────────────────────────────────────

class _RacePicker extends StatefulWidget {
  final List<Map<String, dynamic>> races;
  final String token;
  final int trackId;
  final ApiService apiService;

  const _RacePicker({
    required this.races,
    required this.token,
    required this.trackId,
    required this.apiService,
  });

  @override
  State<_RacePicker> createState() => _RacePickerState();
}

class _RacePickerState extends State<_RacePicker> {
  bool _loading = false;

  Future<void> _link(int raceId) async {
    setState(() => _loading = true);
    try {
      await widget.apiService.linkTrackToRace(widget.token, raceId, widget.trackId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track gekoppeld aan wedstrijd')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Koppel aan wedstrijd',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          )
        else
          ...widget.races.map((r) => ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(r['name'] as String),
                subtitle: r['race_date'] != null
                    ? Text(r['race_date'] as String)
                    : null,
                trailing: Text('${r['participant_count']} deelnemer(s)'),
                onTap: () => _link(r['id'] as int),
              )),
        const SizedBox(height: 8),
      ],
    );
  }
}
