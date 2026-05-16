import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metronome_service.dart';
import '../widgets/beat_indicator.dart';
import '../widgets/bpm_dial.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metro = context.watch<MetronomeService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Beat indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  metro.beatsPerMeasure.clamp(1, 6),
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: BeatIndicator(
                      beatIndex: i + 1,
                      currentBeat: metro.currentBeat,
                      isPlaying: metro.isPlaying,
                      isAccent: i == 0,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Volume (sound picker) button — only volume icon, no TAP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _RoundButton(
                    icon: Icons.volume_up_outlined,
                    onTap: () => _showSoundPicker(context, metro),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // BPM Dial
            Expanded(
              child: BpmDial(
                bpm: metro.bpm,
                tempoName: metro.tempoName,
                onChanged: metro.setBpm,
                colorScheme: colorScheme,
              ),
            ),

            // Bottom controls: time signature | play | note value
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time signature
                  _BottomButton(
                    label: metro.timeSignature,
                    onTap: () => _showTimeSignaturePicker(context, metro),
                    colorScheme: colorScheme,
                    fontSize: 18,
                  ),

                  // Play/Stop button
                  GestureDetector(
                    onTap: metro.togglePlay,
                    child: Container(
                      width: 120,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        metro.isPlaying ? Icons.stop : Icons.play_arrow,
                        color: colorScheme.onSurface,
                        size: 28,
                      ),
                    ),
                  ),

                  // Note value
                  _BottomButton(
                    icon: _noteIcon(metro.noteValue),
                    onTap: () => _cycleNoteValue(metro),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _noteIcon(NoteValue value) {
    switch (value) {
      case NoteValue.whole:
        return Icons.radio_button_unchecked;
      case NoteValue.half:
        return Icons.radio_button_unchecked;
      case NoteValue.quarter:
        return Icons.music_note;
      case NoteValue.eighth:
        return Icons.music_note;
    }
  }

  void _cycleNoteValue(MetronomeService metro) {
    final values = NoteValue.values;
    final current = values.indexOf(metro.noteValue);
    metro.setNoteValue(values[(current + 1) % values.length]);
  }

  void _showTimeSignaturePicker(
      BuildContext context, MetronomeService metro) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _TimeSignaturePicker(metro: metro),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  void _showSoundPicker(BuildContext context, MetronomeService metro) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Consumer<MetronomeService>(
          builder: (context, metro, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Metronome Sound',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...MetronomeSound.values.map((s) {
                    final selected = metro.sound == s;
                    return ListTile(
                      leading: Icon(
                        Icons.music_note,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        s.label,
                        style: TextStyle(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        metro.setSound(s);
                        Navigator.of(ctx).pop();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RoundButton({
    this.icon,
    this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: colorScheme.onSurface)
              : Text(
                  label!,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final double fontSize;

  const _BottomButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.colorScheme,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: colorScheme.onSurface)
              : Text(
                  label!,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TimeSignaturePicker extends StatelessWidget {
  final MetronomeService metro;

  const _TimeSignaturePicker({required this.metro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Time signature',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                value: metro.beatsPerMeasure,
                min: 1,
                max: 12,
                onChanged: (v) {
                  metro.setBeatsPerMeasure(v);
                },
                colorScheme: colorScheme,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 32,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _NumberPicker(
                value: metro.beatUnit,
                min: 2,
                max: 16,
                step: 2,
                onChanged: metro.setBeatUnit,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final ColorScheme colorScheme;

  const _NumberPicker({
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final values = <int>[];
    for (int i = min; i <= max; i += step) {
      values.add(i);
    }

    return SizedBox(
      width: 64,
      height: 200,
      child: ListWheelScrollView(
        itemExtent: 50,
        onSelectedItemChanged: (i) => onChanged(values[i]),
        controller: FixedExtentScrollController(
          initialItem: values.indexOf(value),
        ),
        physics: const FixedExtentScrollPhysics(),
        children: values
            .map((v) => Center(
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontSize: v == value ? 28 : 22,
                      color: v == value
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: v == value
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
