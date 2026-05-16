import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tuner_service.dart';

class ChromaticScreen extends StatelessWidget {
  const ChromaticScreen({super.key});

  static const List<String> allNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F',
    'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerService>();
    final colorScheme = Theme.of(context).colorScheme;

    final detectedNote = tuner.currentNote?.noteName ?? '';
    // Extract just the note name without octave
    final detectedBase = detectedNote.length >= 1
        ? detectedNote.replaceAll(RegExp(r'\d'), '')
        : '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Chromatic Tuner',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All 12 semitones',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Detected frequency display
              if (tuner.isListening) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        detectedNote.isEmpty ? '—' : detectedNote,
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tuner.currentFrequency > 0
                            ? '${tuner.currentFrequency.toStringAsFixed(1)} Hz'
                            : 'Listening...',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Note grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: allNotes.length,
                  itemBuilder: (context, i) {
                    final note = allNotes[i];
                    final isDetected = detectedBase == note;
                    final isSharp = note.contains('#');

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isDetected
                            ? colorScheme.primary
                            : isSharp
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: isDetected
                            ? null
                            : Border.all(
                                color: colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDetected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
