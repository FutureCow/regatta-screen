// lib/screens/settings/races_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RacesScreen extends ConsumerStatefulWidget {
  const RacesScreen({super.key});

  @override
  ConsumerState<RacesScreen> createState() => _RacesScreenState();
}

class _RacesScreenState extends ConsumerState<RacesScreen> {
  List<Map<String, dynamic>> _races = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(authProvider).token;
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final races = await ref.read(apiServiceProvider).listRaces(token);
      if (mounted) setState(() { _races = races; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wedstrijden')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _races.isEmpty
              ? const Center(child: Text('Geen wedstrijden beschikbaar'))
              : ListView.builder(
                  itemCount: _races.length,
                  itemBuilder: (ctx, i) {
                    final r = _races[i];
                    return ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(r['name'] as String),
                      subtitle: Text([
                        if (r['race_date'] != null) r['race_date'] as String,
                        '${r['participant_count']} deelnemer(s)',
                      ].join(' · ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RaceDetailScreen(race: r),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ── Race detail: deelnemers en hun stats ─────────────────────────────────────

class RaceDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> race;
  const RaceDetailScreen({super.key, required this.race});

  @override
  ConsumerState<RaceDetailScreen> createState() => _RaceDetailScreenState();
}

class _RaceDetailScreenState extends ConsumerState<RaceDetailScreen> {
  List<Map<String, dynamic>> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(authProvider).token;
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final tracks = await ref
          .read(apiServiceProvider)
          .getRaceTracks(token, widget.race['id'] as int);
      if (mounted) setState(() { _tracks = tracks; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDuration(dynamic seconds) {
    if (seconds == null) return '--';
    final d = Duration(seconds: (seconds as num).round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _fmtKnots(dynamic v) =>
      v != null ? '${(v as num).toStringAsFixed(1)} kts' : '--';

  String _fmtDist(dynamic v) =>
      v != null ? '${((v as num) / 1000).toStringAsFixed(2)} km' : '--';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raceName = widget.race['name'] as String;
    final raceDate = widget.race['race_date'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text(raceName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(child: Text('Nog geen deelnemers gekoppeld'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tracks.length,
                  itemBuilder: (ctx, i) {
                    final t = _tracks[i];
                    final pos = i + 1;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: pos == 1
                                      ? Colors.amber
                                      : pos == 2
                                          ? Colors.grey.shade400
                                          : pos == 3
                                              ? Colors.brown.shade300
                                              : theme.dividerColor,
                                  child: Text('$pos',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t['user_email'] as String,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _statRow(theme, [
                              ('Gem. snelheid', _fmtKnots(t['avg_speed_knots'])),
                              ('Max. snelheid', _fmtKnots(t['max_speed_knots'])),
                            ]),
                            const SizedBox(height: 4),
                            _statRow(theme, [
                              ('Afstand', _fmtDist(t['distance_meters'])),
                              ('Tijd', _fmtDuration(t['duration_seconds'])),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _statRow(ThemeData theme, List<(String, String)> items) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: theme.textTheme.labelSmall),
                    Text(item.$2,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
