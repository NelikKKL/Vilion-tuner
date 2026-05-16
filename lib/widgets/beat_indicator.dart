import 'package:flutter/material.dart';

class BeatIndicator extends StatelessWidget {
  final int beatIndex;
  final int currentBeat;
  final bool isPlaying;
  final bool isAccent;
  final ColorScheme colorScheme;

  const BeatIndicator({
    super.key,
    required this.beatIndex,
    required this.currentBeat,
    required this.isPlaying,
    required this.isAccent,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isPlaying && currentBeat == beatIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? (isAccent ? colorScheme.primary : colorScheme.secondary)
            : colorScheme.surfaceContainerHighest,
      ),
      // Inner fill indicator
      child: isAccent
          ? null
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? colorScheme.onSecondary.withOpacity(0.3)
                      : colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
            ),
    );
  }
}
