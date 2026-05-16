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
      // Wrap around
      if (diff > pi) diff -= 2 * pi;
      if (diff < -pi) diff += 2 * pi;

      // Convert angle change to BPM change
      final bpmDelta = (diff * 30 / pi).round();
      if (bpmDelta != 0) {
        widget.onChanged((widget.bpm + bpmDelta).clamp(20, 300));
      }
    }
    _lastAngle = angle;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dialSize = min(size.width, size.height) * 0.75;

        return GestureDetector(
          onPanStart: (d) {
            _lastAngle = _getAngle(d.localPosition, size);
          },
          onPanUpdate: (d) => _handlePanUpdate(d, size),
          onPanEnd: (_) => _lastAngle = null,
          child: Center(
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.colorScheme.surfaceContainerHighest,
                    ),
                  ),

                  // Indicator dot on the ring
                  _DialDot(
                    bpm: widget.bpm,
                    dialSize: dialSize,
                    colorScheme: widget.colorScheme,
                  ),

                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.tempoName,
                        style: TextStyle(
                          color: widget.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.bpm}',
                        style: TextStyle(
                          color: widget.colorScheme.onSurface,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'BPM',
                        style: TextStyle(
                          color: widget.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialDot extends StatelessWidget {
  final int bpm;
  final double dialSize;
  final ColorScheme colorScheme;

  const _DialDot({
    required this.bpm,
    required this.dialSize,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    // Map BPM 20-300 to angle 0-2pi
    final t = (bpm - 20) / (300 - 20);
    final angle = t * 2 * pi - pi / 2;
    final radius = dialSize / 2 - 12;
    final dx = cos(angle) * radius;
    final dy = sin(angle) * radius;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
