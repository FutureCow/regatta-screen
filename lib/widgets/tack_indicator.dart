// lib/widgets/tack_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tack_provider.dart';
import '../theme/app_colors.dart';

class TackIndicator extends ConsumerWidget {
  const TackIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tack = ref.watch(tackStateProvider);
    final theme = Theme.of(context);
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 5 blocks on the left (port/bakboord), drawn right-to-left
        ...List.generate(5, (i) {
          final blockIndex = 4 - i;
          final active = blockIndex < tack.blocksLeft;
          return _Block(active: active, theme: theme, landscape: landscape);
        }),
        SizedBox(width: landscape ? 10 : 6),
        // Center dot
        Container(
          width: landscape ? 20 : 14,
          height: landscape ? 20 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tack.isSettling
                ? AppColors.accentAmber.withValues(alpha: 0.5)
                : theme.textTheme.bodyLarge?.color ?? Colors.white,
          ),
        ),
        SizedBox(width: landscape ? 10 : 6),
        // 5 blocks on the right (starboard/stuurboord)
        ...List.generate(5, (i) {
          final active = i < tack.blocksRight;
          return _Block(active: active, theme: theme, landscape: landscape);
        }),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final bool active;
  final ThemeData theme;
  final bool landscape;
  const _Block(
      {required this.active, required this.theme, required this.landscape});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: landscape ? 32 : 18,
      height: landscape ? 16 : 10,
      margin: EdgeInsets.symmetric(horizontal: landscape ? 3 : 2),
      decoration: BoxDecoration(
        color: active ? AppColors.accentAmber : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.accentAmber : theme.dividerColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
