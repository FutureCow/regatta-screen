// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import 'panel_config_screen.dart';
import 'gpx_tracks_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      data: (settings) => _SettingsBody(settings: settings),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fout: $e'))),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(AppSettings s) => ref.read(settingsProvider.notifier).save(s);

    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: ListView(
        children: [
          // ── Eenheden ──────────────────────────────────────────────────────
          _Section('Eenheden', [
            _DropdownTile<SpeedUnit>(
              label: 'Snelheid',
              value: settings.speedUnit,
              items: SpeedUnit.values,
              itemLabel: (u) => switch (u) {
                SpeedUnit.knots => 'Knopen (kts)',
                SpeedUnit.kmh => 'km/u',
                SpeedUnit.ms => 'm/s',
              },
              onChanged: (u) => update(settings.copyWith(speedUnit: u)),
            ),
            _DropdownTile<DistanceUnit>(
              label: 'Afstand',
              value: settings.distanceUnit,
              items: DistanceUnit.values,
              itemLabel: (u) => switch (u) {
                DistanceUnit.meters => 'Meter',
                DistanceUnit.nauticalMiles => 'Nautische mijl',
              },
              onChanged: (u) => update(settings.copyWith(distanceUnit: u)),
            ),
          ]),

          // ── Smoothing ────────────────────────────────────────────────────
          _Section('Vertraging / middeling', [
            _DropdownTile<int>(
              label: 'Koers (magnetisch)',
              value: settings.headingSmoothing,
              items: const [1, 3, 5, 10],
              itemLabel: (v) => v == 1 ? '1 seconde' : '$v seconden',
              onChanged: (v) => update(settings.copyWith(headingSmoothing: v)),
            ),
            _DropdownTile<int>(
              label: 'Snelheid',
              value: settings.speedSmoothing,
              items: const [1, 3, 5, 10],
              itemLabel: (v) => v == 1 ? '1 seconde' : '$v seconden',
              onChanged: (v) => update(settings.copyWith(speedSmoothing: v)),
            ),
          ]),

          // ── Windrichting ──────────────────────────────────────────────────
          _Section('Windrichting', [
            ListTile(
              title: const Text('Windrichting'),
              subtitle: Text(
                settings.windDirectionDeg != null
                    ? '${settings.windDirectionDeg!.toStringAsFixed(0)}°'
                    : 'Niet ingesteld (bias uitgeschakeld)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showWindPicker(context, settings, update),
            ),
          ]),

          // ── Weergave ──────────────────────────────────────────────────────
          _Section('Weergave', [
            SwitchListTile(
              title: const Text('Donker thema'),
              value: settings.darkMode,
              onChanged: (v) => update(settings.copyWith(darkMode: v)),
            ),
            SwitchListTile(
              title: const Text('Scherm altijd aan'),
              value: settings.keepScreenOn,
              onChanged: (v) => update(settings.copyWith(keepScreenOn: v)),
            ),
          ]),

          // ── Na timer ─────────────────────────────────────────────────────
          _Section('Na timer', [
            _DropdownTile<int?>(
              label: 'Ga naar na aftellen',
              value: settings.afterTimerPanel,
              items: const [null, 1, 2],
              itemLabel: (v) => switch (v) {
                null => 'Blijf op huidig scherm',
                1 => 'Paneel 1',
                2 => 'Paneel 2',
                _ => '',
              },
              onChanged: (v) => update(settings.copyWith(afterTimerPanel: v)),
            ),
          ]),

          // ── Koersverandering ──────────────────────────────────────────────
          _Section('Koersverandering (tack-indicator)', [
            SwitchListTile(
              title: const Text('Toon op paneel 1'),
              value: settings.tackIndicatorPanel1,
              onChanged: (v) =>
                  update(settings.copyWith(tackIndicatorPanel1: v)),
            ),
            SwitchListTile(
              title: const Text('Toon op paneel 2'),
              value: settings.tackIndicatorPanel2,
              onChanged: (v) =>
                  update(settings.copyWith(tackIndicatorPanel2: v)),
            ),
            _DropdownTile<int>(
              label: 'Graden per blokje',
              value: settings.tackDegreesPerBlock,
              items: const [1, 2, 3, 5, 10],
              itemLabel: (v) => '$v°',
              onChanged: (v) =>
                  update(settings.copyWith(tackDegreesPerBlock: v)),
            ),
          ]),

          // ── Datapanelen ───────────────────────────────────────────────────
          _Section('Datapanelen', [
            ListTile(
              title: const Text('Paneel 1 instellen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PanelConfigScreen(panelIndex: 1),
                ),
              ),
            ),
            ListTile(
              title: const Text('Paneel 2 instellen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PanelConfigScreen(panelIndex: 2),
                ),
              ),
            ),
          ]),

          // ── GPS Opname ────────────────────────────────────────────────────
          _Section('GPS Opname', [
            ListTile(
              title: const Text('Opgeslagen tracks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GpxTracksScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showWindPicker(BuildContext context, AppSettings settings,
      void Function(AppSettings) update) {
    double wind = settings.windDirectionDeg ?? 180;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Windrichting'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${wind.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Slider(
                value: wind,
                min: 0,
                max: 359,
                divisions: 359,
                onChanged: (v) => setState(() => wind = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                update(settings.copyWith(windDirectionDeg: null));
                Navigator.pop(ctx);
              },
              child: const Text('Wissen')),
          TextButton(
              onPressed: () {
                update(settings.copyWith(windDirectionDeg: wind));
                Navigator.pop(ctx);
              },
              child: const Text('Opslaan')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label),
      trailing: SizedBox(
        width: 160,
        child: Align(
          alignment: Alignment.centerRight,
          child: DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            alignment: AlignmentDirectional.centerEnd,
            items: items
                .map((i) => DropdownMenuItem(
                      value: i,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        itemLabel(i),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.right,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                onChanged(v);
              } else {
                onChanged(v as T);
              }
            },
          ),
        ),
      ),
    );
  }
}
