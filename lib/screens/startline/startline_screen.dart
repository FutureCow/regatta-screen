// lib/screens/startline/startline_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/startline_calculator.dart';
import '../../models/lat_lng.dart';
import '../../providers/gps_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/start_line_provider.dart';
import '../../theme/app_colors.dart';

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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 52,
        16,
        16,
      ),
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
                  onClear: lineState.pin != null ? lineNotifier.clearPin : null,
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
                  onClear: lineState.boat != null ? lineNotifier.clearBoat : null,
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
              _LineVisual(pin: line.pin, boat: line.boat, pos: currentPos),
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
    );
  }
}

class _WaypointCard extends StatelessWidget {
  final String label;
  final Color color;
  final LatLng? position;
  final LatLng? currentPos;
  final VoidCallback? onRecord;
  final VoidCallback? onClear;

  const _WaypointCard({
    required this.label,
    required this.color,
    this.position,
    this.currentPos,
    this.onRecord,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = position != null;

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
            const SizedBox(height: 4),
            Text(
              position.toString(),
              style: TextStyle(fontSize: 10, color: theme.hintColor),
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

class _LineVisual extends StatelessWidget {
  final LatLng pin;
  final LatLng boat;
  final LatLng pos;

  const _LineVisual({required this.pin, required this.boat, required this.pos});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Positie t.o.v. lijn', style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          CustomPaint(
            size: const Size(double.infinity, 60),
            painter: _LinePainter(
              pin: pin,
              boat: boat,
              position: pos,
              pinColor: AppColors.accentGreen,
              boatColor: AppColors.accentBlue,
              posColor: AppColors.accentAmber,
            ),
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
    final minLng = [pin.lng, boat.lng, position.lng].reduce((a, b) => a < b ? a : b);
    final maxLng = [pin.lng, boat.lng, position.lng].reduce((a, b) => a > b ? a : b);
    final lngRange = (maxLng - minLng).abs() < 0.0001 ? 0.001 : (maxLng - minLng);

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
    canvas.drawCircle(Offset(posX, midY * 0.4), 7,
        Paint()
          ..color = posColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
