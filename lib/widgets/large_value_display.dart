// lib/widgets/large_value_display.dart
import 'package:flutter/material.dart';

/// Displays a large value with an optional unit and label below.
/// Used in data panels with 1–4 fields.
///
/// [unitOnTop] — when true, the unit sits as a small superscript at the
/// top-right of the value (used for compass degrees). When false (default),
/// the unit aligns to the alphabetic baseline of the value.
class LargeValueDisplay extends StatelessWidget {
  final String value;
  final String? unit;
  final String label;
  final double fontSize;
  final Color? valueColor;
  final bool unitOnTop;

  const LargeValueDisplay({
    super.key,
    required this.value,
    this.unit,
    required this.label,
    this.fontSize = 48,
    this.valueColor,
    this.unitOnTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = valueColor ?? theme.textTheme.displayLarge?.color;

    final valueRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          unitOnTop ? CrossAxisAlignment.start : CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.0,
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 4),
          Text(
            unit!,
            style: TextStyle(
              fontSize: fontSize * 0.35,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: valueRow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
