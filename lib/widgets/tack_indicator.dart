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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 5 blocks on the left (port/bakboord), drawn right-to-left
        ...List.generate(5, (i) {
          final blockIndex = 4 - i; // rightmost left-block is index 0
          final active = blockIndex < tack.blocksLeft;
          return _Block(active: active, theme: theme);
        }),
        const SizedBox(width: 6),
        // Center dot
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tack.isSettling
                ? AppColors.accentAmber.withValues(alpha: 0.5)
                : theme.textTheme.bodyLarge?.color ?? Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        // 5 blocks on the right (starboard/stuurboord)
        ...List.generate(5, (i) {
          final active = i < tack.blocksRight;
          return _Block(active: active, theme: theme);
        }),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final bool active;
  final ThemeData theme;
  const _Block({required this.active, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
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
