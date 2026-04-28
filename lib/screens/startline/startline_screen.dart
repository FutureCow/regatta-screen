// lib/screens/startline/startline_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/startline_calculator.dart';
import '../../models/lat_lng.dart';
import '../../models/start_line.dart';
import '../../providers/gps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/start_line_provider.dart';
import '../../theme/app_colors.dart';
import '../../logic/timer_notifier.dart';

class StartlineScreen extends ConsumerWidget {
  const StartlineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineState = ref.watch(startLineProvider);
    final lineNotifier = ref.read(startLineProvider.notifier);
    final gpsAsync = ref.watch(gpsStreamProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    final currentPos = gpsAsync.valueOrNull?.latLng;
    final line = lineState.line;

    double? distanceM;
    String? bias;
    if (line != null && currentPos != null) {
      distanceM = distanceToLine(currentPos, line);
      if (settings?.windDirectionDeg != null) {
        bias = lineBias(line, settings!.windDirectionDeg!);
      }
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      return _LandscapeLayout(
        lineState: lineState,
        lineNotifier: lineNotifier,
        currentPos: currentPos,
        line: line,
        distanceM: distanceM,
        bias: bias,
      );
    }

    // Portrait: scrollable column
    return Column(
      children: [
        const _MiniTimerTop(large: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _WaypointCard(
                        label: 'Pin',
                        color: AppColors.accentGreen,
                        position: lineState.pin,
                        currentPos: currentPos,
                        onRecord: currentPos != null
                            ? () => lineNotifier.setPin(currentPos)
                            : null,
                        onClear: lineState.pin != null
                            ? lineNotifier.clearPin
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WaypointCard(
                        label: 'Startboot',
                        color: AppColors.accentBlue,
                        position: lineState.boat,
                        currentPos: currentPos,
                        onRecord: currentPos != null
                            ? () => lineNotifier.setBoat(currentPos)
                            : null,
                        onClear: lineState.boat != null
                            ? lineNotifier.clearBoat
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (line != null) ...[
                  _LineInfoCard(
                    length: haversineDistance(line.pin, line.boat),
                    bearing: bearingBetween(line.pin, line.boat),
                    distanceM: distanceM,
                    bias: bias,
                  ),
                  const SizedBox(height: 16),
                  if (currentPos != null)
                    _LineVisual(
                        pin: line.pin, boat: line.boat, pos: currentPos),
                ],
                if (!lineState.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Vaar naar de pin en startboot\nom de lijn vast te leggen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.5),
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Landscape layout ─────────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final StartLineState lineState;
  final StartLineNotifier lineNotifier;
  final LatLng? currentPos;
  final StartLine? line;
  final double? distanceM;
  final String? bias;

  const _LandscapeLayout({
    required this.lineState,
    required this.lineNotifier,
    required this.currentPos,
    required this.line,
    required this.distanceM,
    required this.bias,
  });

  @override
  Widget build(BuildContext context) {
    final pos = currentPos;
    final l = line;

    return Column(
      children: [
        const _MiniTimerTop(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Pin + Startboot naast elkaar
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _WaypointCard(
                          label: 'Pin',
                          color: AppColors.accentGreen,
                          position: lineState.pin,
                          currentPos: pos,
                          compact: true,
                          onRecord: pos != null
                              ? () => lineNotifier.setPin(pos)
                              : null,
                          onClear: lineState.pin != null
                              ? lineNotifier.clearPin
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WaypointCard(
                          label: 'Startboot',
                          color: AppColors.accentBlue,
                          position: lineState.boat,
                          currentPos: pos,
                          compact: true,
                          onRecord: pos != null
                              ? () => lineNotifier.setBoat(pos)
                              : null,
                          onClear: lineState.boat != null
                              ? lineNotifier.clearBoat
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Bottom row: data blokken
                if (l != null)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _LineInfoCard(
                            length: haversineDistance(l.pin, l.boat),
                            bearing: bearingBetween(l.pin, l.boat),
                            distanceM: distanceM,
                            bias: bias,
                          ),
                        ),
                        if (pos != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LineVisual(
                              pin: l.pin,
                              boat: l.boat,
                              pos: pos,
                              expand: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Vaar naar de pin en startboot\nom de lijn vast te leggen',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .hintColor
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mini timer — horizontal strip ───────────────────────────────────────────

class _MiniTimerTop extends ConsumerWidget {
  final bool large;
  const _MiniTimerTop({this.large = false});

  String _format(Duration d) {
    final abs = d.isNegative ? -d : d;
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.isNegative ? '-' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerNotifierProvider);
    final theme = Theme.of(context);
    final display = state.isCountingDown
        ? _format(state.remaining)
        : '+${_format(state.raceElapsed)}';

    final textStyle = large
        ? theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.0,
          )
        : theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          );

    return Container(
      width: double.infinity,
      padding: large
          ? const EdgeInsets.fromLTRB(0, 36, 0, 10)
          : const EdgeInsets.symmetric(vertical: 8),
      color: theme.cardColor,
      child: Column(
        children: [
          Text(
            state.isCountingDown ? 'AFTELLEN' : 'RACE',
            style: theme.textTheme.labelSmall,
          ),
          Text(display, style: textStyle),
        ],
      ),
    );
  }
}

// ─── Waypoint card ───────────────────────────────────────────────────────────

class _WaypointCard extends StatelessWidget {
  final String label;
  final Color color;
  final LatLng? position;
  final LatLng? currentPos;
  final VoidCallback? onRecord;
  final VoidCallback? onClear;
  final bool compact;

  const _WaypointCard({
    required this.label,
    required this.color,
    this.position,
    this.currentPos,
    this.onRecord,
    this.onClear,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = position != null;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: recorded ? color : theme.dividerColor, width: 2),
        ),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(width: 8),
            if (recorded)
              Text(
                '✓ Vastgelegd',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 12),
              ),
            const Spacer(),
            GestureDetector(
              onTap: recorded ? onClear : onRecord,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: recorded
                      ? color.withValues(alpha: 0.15)
                      : (onRecord != null ? color : theme.dividerColor),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  recorded ? 'Opnieuw' : 'Vastleggen',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: recorded ? color : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal (portrait) card — no coordinates
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: recorded ? color : theme.dividerColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 6),
          if (recorded) ...[
            Text(
              '✓ Vastgelegd',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 13),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Opnieuw',
                      style: TextStyle(fontSize: 12, color: color)),
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: onRecord,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: onRecord != null ? color : theme.dividerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Vastleggen',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Line info card ──────────────────────────────────────────────────────────

class _LineInfoCard extends StatelessWidget {
  final double length;
  final double bearing;
  final double? distanceM;
  final String? bias;

  const _LineInfoCard({
    required this.length,
    required this.bearing,
    this.distanceM,
    this.bias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _infoRow('Lijnlengte', '${length.toStringAsFixed(0)} m', theme),
          _infoRow('Lijnrichting', '${bearing.toStringAsFixed(0)}°', theme),
          if (distanceM != null) ...[
            const Divider(),
            _infoRow(
              'Afstand tot lijn',
              '${distanceM!.abs().toStringAsFixed(0)} m ${distanceM! < 0 ? '(voor)' : '(achter)'}',
              theme,
              valueColor: distanceM! < 0
                  ? AppColors.accentAmber
                  : AppColors.accentGreen,
              large: true,
            ),
          ],
          if (bias != null)
            _infoRow(
              'Bias',
              bias == 'square'
                  ? 'Vierkant'
                  : '${bias == 'pin' ? 'Pin' : 'Startboot'} → voordeel',
              theme,
              valueColor: AppColors.accentGreen,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme,
      {Color? valueColor, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 22 : 16,
              fontWeight: large ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line visual ─────────────────────────────────────────────────────────────

class _LineVisual extends StatelessWidget {
  final LatLng pin;
  final LatLng boat;
  final LatLng pos;
  final bool expand;

  const _LineVisual({
    required this.pin,
    required this.boat,
    required this.pos,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final painter = _LinePainter(
      pin: pin,
      boat: boat,
      position: pos,
      pinColor: AppColors.accentGreen,
      boatColor: AppColors.accentBlue,
      posColor: AppColors.accentAmber,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Positie t.o.v. lijn', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          if (expand)
            Expanded(child: CustomPaint(painter: painter))
          else
            CustomPaint(
              size: const Size(double.infinity, 60),
              painter: painter,
            ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final LatLng pin, boat, position;
  final Color pinColor, boatColor, posColor;

  _LinePainter({
    required this.pin,
    required this.boat,
    required this.position,
    required this.pinColor,
    required this.boatColor,
    required this.posColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minLng =
        [pin.lng, boat.lng, position.lng].reduce((a, b) => a < b ? a : b);
    final maxLng =
        [pin.lng, boat.lng, position.lng].reduce((a, b) => a > b ? a : b);
    final lngRange =
        (maxLng - minLng).abs() < 0.0001 ? 0.001 : (maxLng - minLng);

    double lngToX(double lng) =>
        0.1 * size.width + ((lng - minLng) / lngRange) * 0.8 * size.width;

    final pinX = lngToX(pin.lng);
    final boatX = lngToX(boat.lng);
    final posX = lngToX(position.lng);
    final midY = size.height / 2;

    canvas.drawLine(
      Offset(pinX, midY),
      Offset(boatX, midY),
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.4)
        ..strokeWidth = 2,
    );

    canvas.drawCircle(Offset(pinX, midY), 6, Paint()..color = pinColor);
    canvas.drawCircle(Offset(boatX, midY), 6, Paint()..color = boatColor);
    canvas.drawCircle(Offset(posX, midY * 0.4), 7,
        Paint()..color = posColor..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(posX, midY * 0.4),
        7,
        Paint()
          ..color = posColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
