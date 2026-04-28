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
            final key = (t['original_filename'] as String?)?.isNotEmpty == true
                ? t['original_filename'] as String
                : t['filename'] as String;
            _serverTracks[key] = t['id'] as int?;
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

      int? newTrackId;
      if (mounted) {
        setState(() {
          _uploading.remove(filename);
          for (final t in updated) {
            final key = (t['original_filename'] as String?)?.isNotEmpty == true
                ? t['original_filename'] as String
                : t['filename'] as String;
            _serverTracks[key] = t['id'] as int?;
            if (key == filename) newTrackId = t['id'] as int?;
          }
        });
      }

      // Auto-join active race if set
      final code = settings?.activeRaceCode;
      if (code != null && newTrackId != null && mounted) {
        try {
          await ref.read(apiServiceProvider).joinWithCode(auth.token!, code, newTrackId!);
          if (mounted) {
            final label = settings?.activeRaceLabel ?? code;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Track geüpload en gekoppeld aan $label')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Track geüpload (koppelen aan wedstrijd mislukt)')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Track geüpload')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading.remove(filename));
        final msg = e.toString() == 'already_on_server'
            ? 'Track staat al op de server'
            : 'Upload mislukt: $e';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        if (e.toString() == 'already_on_server') {
          _loadServerTracks();
        }
      }
    }
  }

  Future<void> _linkToRace(String filename) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    final trackId = _serverTracks[filename];
    if (trackId == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CodeJoinSheet(
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

    final settings = ref.watch(settingsProvider).valueOrNull;
    final activeCode = settings?.activeRaceCode;
    final activeLabel = settings?.activeRaceLabel;

    return Scaffold(
      appBar: AppBar(title: const Text('Opgeslagen tracks')),
      body: Column(
        children: [
          if (loggedIn)
            _RaceCodeBanner(
              code: activeCode,
              label: activeLabel,
              onSet: (code, label) {
                if (settings == null) return;
                ref.read(settingsProvider.notifier).save(
                      settings.copyWith(activeRaceCode: code, activeRaceLabel: label),
                    );
              },
              onClear: () {
                if (settings == null) return;
                ref.read(settingsProvider.notifier).save(
                      settings.copyWith(activeRaceCode: null, activeRaceLabel: null),
                    );
              },
              token: auth.token ?? '',
              apiService: ref.read(apiServiceProvider),
            ),
          Expanded(
            child: tracksAsync.when(
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
          ),
        ],
      ),
    );
  }
}

// ── Actieve wedstrijdcode banner ──────────────────────────────────────────────

class _RaceCodeBanner extends StatelessWidget {
  final String? code;
  final String? label;
  final void Function(String code, String label) onSet;
  final VoidCallback onClear;
  final String token;
  final ApiService apiService;

  const _RaceCodeBanner({
    required this.code,
    required this.label,
    required this.onSet,
    required this.onClear,
    required this.token,
    required this.apiService,
  });

  Future<void> _openSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SetRaceCodeSheet(
        token: token,
        apiService: apiService,
        onConfirm: onSet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCode = code != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasCode
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            hasCode ? Icons.flag : Icons.flag_outlined,
            size: 20,
            color: hasCode
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: hasCode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label ?? code!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Code: $code · nieuwe tracks worden automatisch gekoppeld',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Geen actieve wedstrijd — tik om code in te stellen',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          if (hasCode)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Code wissen',
              onPressed: onClear,
              color: theme.colorScheme.onPrimaryContainer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            TextButton(
              onPressed: () => _openSheet(context),
              child: const Text('Instellen'),
            ),
          if (hasCode) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => _openSheet(context),
              child: Text(
                'Wijzigen',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Code invoer bottom sheet ──────────────────────────────────────────────────

class _SetRaceCodeSheet extends StatefulWidget {
  final String token;
  final ApiService apiService;
  final void Function(String code, String label) onConfirm;

  const _SetRaceCodeSheet({
    required this.token,
    required this.apiService,
    required this.onConfirm,
  });

  @override
  State<_SetRaceCodeSheet> createState() => _SetRaceCodeSheetState();
}

class _SetRaceCodeSheetState extends State<_SetRaceCodeSheet> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _preview;
  String? _error;
  bool _looking = false;

  Future<void> _lookup() async {
    final code = _controller.text.toUpperCase().trim();
    if (code.length < 6) return;
    setState(() { _looking = true; _error = null; _preview = null; });
    try {
      final info = await widget.apiService.lookupCode(widget.token, code);
      if (mounted) setState(() { _preview = info; _looking = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _looking = false; });
    }
  }

  void _confirm() {
    final code = _controller.text.toUpperCase().trim();
    final raceName = _preview!['race_name'] as String;
    final className = _preview!['class_name'] as String;
    final label = '$raceName · $className';
    widget.onConfirm(code, label);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wedstrijdcode instellen', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Nieuwe tracks worden automatisch aan deze wedstrijd gekoppeld.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'bijv. AB3K7M',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _looking
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _lookup),
            ),
            onChanged: (_) => setState(() { _preview = null; _error = null; }),
            onSubmitted: (_) => _lookup(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_preview != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_preview!['series_name'] != null)
                    Text(_preview!['series_name'] as String,
                        style: theme.textTheme.labelSmall),
                  Text(_preview!['race_name'] as String,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.flag, size: 14),
                    const SizedBox(width: 6),
                    Text(_preview!['class_name'] as String,
                        style: theme.textTheme.bodyMedium),
                  ]),
                  if (_preview!['race_date'] != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 6),
                      Text(_preview!['race_date'] as String,
                          style: theme.textTheme.bodySmall),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _confirm,
              child: const Text('Instellen'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeJoinSheet extends StatefulWidget {
  final String token;
  final int trackId;
  final ApiService apiService;

  const _CodeJoinSheet({
    required this.token,
    required this.trackId,
    required this.apiService,
  });

  @override
  State<_CodeJoinSheet> createState() => _CodeJoinSheetState();
}

class _CodeJoinSheetState extends State<_CodeJoinSheet> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _preview;
  String? _error;
  bool _looking = false;
  bool _joining = false;

  Future<void> _lookup() async {
    final code = _controller.text.toUpperCase().trim();
    if (code.length < 6) return;
    setState(() { _looking = true; _error = null; _preview = null; });
    try {
      final info = await widget.apiService.lookupCode(widget.token, code);
      if (mounted) setState(() { _preview = info; _looking = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _looking = false; });
    }
  }

  Future<void> _join() async {
    final code = _controller.text.toUpperCase().trim();
    setState(() { _joining = true; _error = null; });
    try {
      await widget.apiService.joinWithCode(widget.token, code, widget.trackId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track gekoppeld aan wedstrijd')),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _joining = false; });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deelnamecode invoeren', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Vraag de code aan de wedstrijdleiding.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'bijv. AB3K7M',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _looking
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _lookup),
            ),
            onChanged: (_) => setState(() { _preview = null; _error = null; }),
            onSubmitted: (_) => _lookup(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_preview != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_preview!['series_name'] != null)
                    Text(_preview!['series_name'] as String,
                        style: theme.textTheme.labelSmall),
                  Text(_preview!['race_name'] as String,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.flag, size: 14),
                    const SizedBox(width: 6),
                    Text(_preview!['class_name'] as String,
                        style: theme.textTheme.bodyMedium),
                  ]),
                  if (_preview!['race_date'] != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 6),
                      Text(_preview!['race_date'] as String,
                          style: theme.textTheme.bodySmall),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Koppelen'),
            ),
          ],
        ],
      ),
    );
  }
}
