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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Явные цвета, видимые на любом фоне
    final inactiveBg = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.10), colorScheme.surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.08), colorScheme.surface);

    final activeBg = isAccent ? colorScheme.primary : colorScheme.secondary;
    final iconColor = isActive
        ? (isAccent ? colorScheme.onPrimary : colorScheme.onSecondary)
        : (isDark ? Colors.white.withOpacity(0.35) : Colors.black.withOpacity(0.30));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isActive ? activeBg : inactiveBg,
      ),
      child: Center(
        child: isAccent
            ? Icon(Icons.music_note, size: 20, color: iconColor)
            : Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: iconColor,
                ),
              ),
      ),
    );
  }
}
