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

    // Явные цвета — не зависят от surfaceContainerHighest, который может быть прозрачным
    final inactiveColor = Color.alphaBlend(
      Colors.white.withOpacity(0.08),
      colorScheme.surface,
    );
    final accentActive = colorScheme.primary;
    final normalActive = colorScheme.secondary != colorScheme.surface
        ? colorScheme.secondary
        : colorScheme.primary.withOpacity(0.7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive
            ? (isAccent ? accentActive : normalActive)
            : inactiveColor,
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: isAccent
          ? Center(
              child: Icon(
                Icons.music_note,
                size: 20,
                color: isActive
                    ? colorScheme.onPrimary
                    : Colors.white.withOpacity(0.4),
              ),
            )
          : Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
            ),
    );
  }
}
