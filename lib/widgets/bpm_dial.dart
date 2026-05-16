import 'dart:math';
import 'package:flutter/material.dart';

class BpmDial extends StatefulWidget {
  final int bpm;
  final String tempoName;
  final ValueChanged<int> onChanged;
  final ColorScheme colorScheme;

  const BpmDial({
    super.key,
    required this.bpm,
    required this.tempoName,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  State<BpmDial> createState() => _BpmDialState();
}

class _BpmDialState extends State<BpmDial> {
  double? _lastAngle;

  double _getAngle(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = position - center;
    return atan2(delta.dy, delta.dx);
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final angle = _getAngle(details.localPosition, size);
    if (_lastAngle != null) {
      double diff = angle - _lastAngle!;
      if (diff > pi) diff -= 2 * pi;
      if (diff < -pi) diff += 2 * pi;
      final bpmDelta = (diff * 30 / pi).round();
      if (bpmDelta != 0) {
        widget.onChanged((widget.bpm + bpmDelta).clamp(20, 300));
      }
    }
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Явные цвета для диска — работают и в светлой, и в тёмной теме
    final ringColor = isDark
        ? Color.alphaBlend(Colors.white.withOpacity(0.09), widget.colorScheme.surface)
        : Color.alphaBlend(Colors.black.withOpacity(0.07), widget.colorScheme.surface);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dialSize = min(size.width, size.height) * 0.78;

        return GestureDetector(
          onPanStart: (d) => _lastAngle = _getAngle(d.localPosition, size),
          onPanUpdate: (d) => _handlePanUpdate(d, size),
          onPanEnd: (_) => _lastAngle = null,
          child: Center(
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: CustomPaint(
                painter: _DialPainter(
                  bpm: widget.bpm,
                  ringColor: ringColor,
                  dotColor: widget.colorScheme.primary,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tempoName,
                        style: TextStyle(
                          color: widget.colorScheme.onSurface.withOpacity(0.55),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.bpm}',
                        style: TextStyle(
                          color: widget.colorScheme.onSurface,
                          fontSize: 62,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'BPM',
                        style: TextStyle(
                          color: widget.colorScheme.onSurface.withOpacity(0.45),
                          fontSize: 14,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final int bpm;
  final Color ringColor;
  final Color dotColor;

  _DialPainter({
    required this.bpm,
    required this.ringColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Filled circle background
    final bgPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Dot position on ring edge
    final t = (bpm - 20) / (300 - 20);
    final angle = t * 2 * pi - pi / 2;
    final dotRadius = radius - 14;
    final dotX = center.dx + cos(angle) * dotRadius;
    final dotY = center.dy + sin(angle) * dotRadius;

    // Dot glow
    final glowPaint = Paint()
      ..color = dotColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(dotX, dotY), 12, glowPaint);

    // Dot
    final dotPaint = Paint()..color = dotColor;
    canvas.drawCircle(Offset(dotX, dotY), 9, dotPaint);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bpm != bpm || old.ringColor != ringColor || old.dotColor != dotColor;
}
