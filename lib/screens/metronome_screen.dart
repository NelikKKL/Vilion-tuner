import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metronome_service.dart';
import '../widgets/beat_indicator.dart';
import '../widgets/bpm_dial.dart';

class MetronomeScreen extends StatelessWidget {
  const MetronomeScreen({super.key});

  // Явный фон кнопок — работает и в светлой и в тёмной теме
  static Color _btnBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    return isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.09), surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.07), surface);
  }

  @override
  Widget build(BuildContext context) {
    final metro = context.watch<MetronomeService>();
    final colorScheme = Theme.of(context).colorScheme;
    final btnBg = _btnBg(context);
    final btnFg = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Beat indicators — горизонтальный скролл если не влезает ──
            SizedBox(
              height: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    metro.beatsPerMeasure.clamp(1, 16),
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
            ),

            const SizedBox(height: 16),

            // ── Sound picker button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _MetroButton(
                    width: 80,
                    height: 46,
                    bg: btnBg,
                    onTap: () => _showSoundPicker(context, metro),
                    child: Icon(Icons.volume_up_outlined, color: btnFg, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── BPM Dial ───────────────────────────────────────────────────
            Expanded(
              child: BpmDial(
                bpm: metro.bpm,
                tempoName: metro.tempoName,
                onChanged: metro.setBpm,
                colorScheme: colorScheme,
              ),
            ),

            // ── Bottom: time sig | play | note value ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time signature
                  _MetroButton(
                    width: 88,
                    height: 54,
                    bg: btnBg,
                    onTap: () => _showTimeSignaturePicker(context, metro),
                    child: Text(
                      metro.timeSignature,
                      style: TextStyle(
                        color: btnFg,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // Play / Stop
                  _MetroButton(
                    width: 130,
                    height: 54,
                    bg: metro.isPlaying ? colorScheme.primary : btnBg,
                    onTap: metro.togglePlay,
                    child: Icon(
                      metro.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: metro.isPlaying ? colorScheme.onPrimary : btnFg,
                      size: 30,
                    ),
                  ),

                  // Note value
                  _MetroButton(
                    width: 88,
                    height: 54,
                    bg: btnBg,
                    onTap: () => _showNoteValuePicker(context, metro),
                    child: _NoteValueIcon(value: metro.noteValue, color: btnFg),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSignaturePicker(BuildContext context, MetronomeService metro) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.05), cs.surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.03), cs.surface);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _TimeSignaturePicker(metro: metro),
    );
  }

  void _showSoundPicker(BuildContext context, MetronomeService metro) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.05), cs.surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.03), cs.surface);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Consumer<MetronomeService>(
          builder: (context, metro, _) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Metronome Sound',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ...MetronomeSound.values.map((s) {
                  final selected = metro.sound == s;
                  return ListTile(
                    leading: Icon(Icons.music_note,
                        color: selected ? cs.primary : cs.onSurface.withOpacity(0.5)),
                    title: Text(s.label,
                        style: TextStyle(
                            color: selected ? cs.primary : cs.onSurface,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                    trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
                    onTap: () {
                      metro.setSound(s);
                      Navigator.of(ctx).pop();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoteValuePicker(BuildContext context, MetronomeService metro) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.05), cs.surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.03), cs.surface);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Consumer<MetronomeService>(
          builder: (context, metro, _) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Note Value',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ...NoteValue.values.map((v) {
                  final selected = metro.noteValue == v;
                  return ListTile(
                    leading: _NoteValueIcon(
                      value: v,
                      color: selected ? cs.primary : cs.onSurface.withOpacity(0.5),
                      size: 28,
                    ),
                    title: Text(v.label,
                        style: TextStyle(
                            color: selected ? cs.primary : cs.onSurface,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                    subtitle: Text(v.description,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.45), fontSize: 12)),
                    trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
                    onTap: () {
                      metro.setNoteValue(v);
                      Navigator.of(ctx).pop();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Универсальная кнопка метронома ─────────────────────────────────────────
class _MetroButton extends StatelessWidget {
  final double width;
  final double height;
  final Color bg;
  final VoidCallback onTap;
  final Widget child;

  const _MetroButton({
    required this.width,
    required this.height,
    required this.bg,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Иконка длительности ноты ───────────────────────────────────────────────
class _NoteValueIcon extends StatelessWidget {
  final NoteValue value;
  final Color color;
  final double size;

  const _NoteValueIcon({
    required this.value,
    required this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NoteIconPainter(value: value, color: color),
    );
  }
}

class _NoteIconPainter extends CustomPainter {
  final NoteValue value;
  final Color color;
  const _NoteIconPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;

    final cx = size.width * 0.38;
    final cy = size.height * 0.72;
    final headW = size.width * 0.42;
    final headH = size.height * 0.28;

    switch (value) {
      case NoteValue.whole:
        // Целая — пустой овал
        canvas.drawOval(Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.6),
            width: headW * 1.1,
            height: headH), strokePaint);
        break;

      case NoteValue.half:
        // Половинная — пустая головка + штиль
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH),
            strokePaint);
        canvas.drawLine(
            Offset(cx + headW / 2 - strokePaint.strokeWidth / 2, cy),
            Offset(cx + headW / 2 - strokePaint.strokeWidth / 2, cy - size.height * 0.55),
            strokePaint);
        break;

      case NoteValue.quarter:
        // Четвертная — заполненная головка + штиль
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH), paint);
        canvas.drawLine(
            Offset(cx + headW / 2 - 1, cy),
            Offset(cx + headW / 2 - 1, cy - size.height * 0.55),
            strokePaint);
        break;

      case NoteValue.eighth:
        // Восьмая — заполненная + штиль + флажок
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH), paint);
        final stemX = cx + headW / 2 - 1;
        final stemTop = cy - size.height * 0.55;
        canvas.drawLine(Offset(stemX, cy), Offset(stemX, stemTop), strokePaint);
        // Флажок
        final path = Path()
          ..moveTo(stemX, stemTop)
          ..cubicTo(
              stemX + size.width * 0.35, stemTop + size.height * 0.08,
              stemX + size.width * 0.3, stemTop + size.height * 0.2,
              stemX, stemTop + size.height * 0.28);
        canvas.drawPath(path, strokePaint..style = PaintingStyle.stroke);
        break;

      case NoteValue.sixteenth:
        // Шестнадцатая — заполненная + два флажка
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH), paint);
        final stemX2 = cx + headW / 2 - 1;
        final stemTop2 = cy - size.height * 0.55;
        canvas.drawLine(Offset(stemX2, cy), Offset(stemX2, stemTop2), strokePaint);
        for (int f = 0; f < 2; f++) {
          final yOff = f * size.height * 0.16;
          final path = Path()
            ..moveTo(stemX2, stemTop2 + yOff)
            ..cubicTo(
                stemX2 + size.width * 0.35, stemTop2 + yOff + size.height * 0.08,
                stemX2 + size.width * 0.3, stemTop2 + yOff + size.height * 0.18,
                stemX2, stemTop2 + yOff + size.height * 0.24);
          canvas.drawPath(path, strokePaint..style = PaintingStyle.stroke);
        }
        break;

      case NoteValue.thirtySecond:
        // 32-я — три флажка
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH), paint);
        final stemX3 = cx + headW / 2 - 1;
        final stemTop3 = cy - size.height * 0.62;
        canvas.drawLine(Offset(stemX3, cy), Offset(stemX3, stemTop3), strokePaint);
        for (int f = 0; f < 3; f++) {
          final yOff = f * size.height * 0.14;
          final path = Path()
            ..moveTo(stemX3, stemTop3 + yOff)
            ..cubicTo(
                stemX3 + size.width * 0.35, stemTop3 + yOff + size.height * 0.07,
                stemX3 + size.width * 0.3, stemTop3 + yOff + size.height * 0.16,
                stemX3, stemTop3 + yOff + size.height * 0.22);
          canvas.drawPath(path, strokePaint..style = PaintingStyle.stroke);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_NoteIconPainter old) => old.value != value || old.color != color;
}

// ── Time signature picker ──────────────────────────────────────────────────
class _TimeSignaturePicker extends StatelessWidget {
  final MetronomeService metro;
  const _TimeSignaturePicker({required this.metro});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Time Signature',
              style: TextStyle(
                  color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                value: metro.beatsPerMeasure,
                min: 1, max: 16,
                onChanged: metro.setBeatsPerMeasure,
                colorScheme: cs,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('/', style: TextStyle(fontSize: 32, color: cs.onSurface)),
              ),
              _NumberPicker(
                value: metro.beatUnit,
                min: 2, max: 16, step: 2,
                onChanged: metro.setBeatUnit,
                colorScheme: cs,
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
    for (int i = min; i <= max; i += step) values.add(i);

    return SizedBox(
      width: 64,
      height: 200,
      child: ListWheelScrollView(
        itemExtent: 50,
        onSelectedItemChanged: (i) => onChanged(values[i]),
        controller: FixedExtentScrollController(initialItem: values.indexOf(value)),
        physics: const FixedExtentScrollPhysics(),
        children: values.map((v) => Center(
          child: Text('$v',
              style: TextStyle(
                  fontSize: v == value ? 28 : 22,
                  color: v == value
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.35),
                  fontWeight: v == value ? FontWeight.bold : FontWeight.normal)),
        )).toList(),
      ),
    );
  }
}
