// lib/models/tack_state.dart

class TackState {
  final double? baseline; // heading at last settle
  final int blocksLeft;   // deviation to port (bakboord)
  final int blocksRight;  // deviation to starboard (stuurboord)
  final bool isSettling;  // tack detected, waiting to settle

  const TackState({
    this.baseline,
    this.blocksLeft = 0,
    this.blocksRight = 0,
    this.isSettling = false,
  });

  factory TackState.initial() => const TackState();

  static const _unset = Object();

  TackState copyWith({
    Object? baseline = _unset,
    int? blocksLeft,
    int? blocksRight,
    bool? isSettling,
  }) =>
      TackState(
        baseline: baseline == _unset ? this.baseline : baseline as double?,
        blocksLeft: blocksLeft ?? this.blocksLeft,
        blocksRight: blocksRight ?? this.blocksRight,
        isSettling: isSettling ?? this.isSettling,
      );
}
