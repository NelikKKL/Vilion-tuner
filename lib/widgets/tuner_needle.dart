import 'package:flutter/material.dart';
import '../services/tuner_service.dart';

class TunerNeedle extends StatelessWidget {
  final double position; // -1.0 to 1.0
  final NoteResult? noteResult;
  final ColorScheme colorScheme;

  const TunerNeedle({
    super.key,
    required this.position,
    required this.noteResult,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isInTune = noteResult?.isInTune ?? false;
    final noteText = noteResult?.noteName ?? '';
    final centsText = noteResult != null
        ? '${noteResult!.centsDiff >= 0 ? '+' : ''}${noteResult!.centsDiff.toStringAsFixed(0)}¢'
        : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final centerX = w / 2;
        final needleLength = h * 0.7;

        return Stack(
          children: [
            // Flat/sharp labels
            Positioned(
              left: 24,
              bottom: h * 0.15,
              child: Text(
                '♭',
                style: TextStyle(
                  fontSize: 22,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: h * 0.15,
              child: Text(
                '♯',
                style: TextStyle(
                  fontSize: 22,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),

            // Center line
            Positioned(
              top: h * 0.1,
              left: centerX - 0.5,
              child: Container(
                width: 1,
                height: needleLength,
                color: colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),

            // Tick marks
            ...List.generate(9, (i) {
              final pct = (i - 4) / 4.0; // -1 to +1
              final x = centerX + pct * (w * 0.4);
              final isCenter = i == 4;
              return Positioned(
                top: h * 0.1 + needleLength - 16,
                left: x - 1,
                child: Container(
                  width: 2,
                  height: isCenter ? 24 : 12,
                  color: isCenter
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withOpacity(0.5),
                ),
              );
            }),

            // Animated needle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: h * 0.05,
              left: centerX + position * (w * 0.38) - 1,
              child: Container(
                width: 2,
                height: needleLength * 0.9,
                color: isInTune ? Colors.green : colorScheme.primary,
              ),
            ),

            // Needle head (pin)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: h * 0.04,
              left: centerX + position * (w * 0.38) - 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInTune ? Colors.green : colorScheme.onSurface,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),

            // Note name display (center)
            Positioned(
              top: h * 0.55,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (noteText.isNotEmpty) ...[
                    Text(
                      noteText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isInTune
                            ? Colors.green
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      centsText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
