import 'package:flutter/material.dart';

class ViolinScrollWidget extends StatelessWidget {
  const ViolinScrollWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scrollColor = isDark
        ? const Color(0xFFA0522D)
        : const Color(0xFFCD853F);
    final darkBrown = isDark
        ? const Color(0xFF6B2F0A)
        : const Color(0xFF8B4513);

    return SizedBox(
      width: 200,
      height: 280,
      child: CustomPaint(
        painter: _ViolinScrollPainter(
          scrollColor: scrollColor,
          darkColor: darkBrown,
        ),
      ),
    );
  }
}

class _ViolinScrollPainter extends CustomPainter {
  final Color scrollColor;
  final Color darkColor;

  _ViolinScrollPainter({required this.scrollColor, required this.darkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = scrollColor
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    // Neck / fingerboard
    final neckPath = Path();
    neckPath.moveTo(cx - 18, size.height);
    neckPath.lineTo(cx + 18, size.height);
    neckPath.lineTo(cx + 14, size.height * 0.4);
    neckPath.lineTo(cx - 14, size.height * 0.4);
    neckPath.close();
    canvas.drawPath(neckPath, paint);

    // Fingerboard (dark overlay)
    final fpPath = Path();
    fpPath.moveTo(cx - 10, size.height);
    fpPath.lineTo(cx + 10, size.height);
    fpPath.lineTo(cx + 8, size.height * 0.4);
    fpPath.lineTo(cx - 8, size.height * 0.4);
    fpPath.close();
    canvas.drawPath(fpPath, darkPaint);

    // Strings
    final stringPaint = Paint()
      ..color = darkColor.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue;
      canvas.drawLine(
        Offset(cx + i * 3.5, size.height * 0.42),
        Offset(cx + i * 3.5, size.height),
        stringPaint,
      );
    }

    // Pegbox
    final pegboxPath = Path();
    pegboxPath.moveTo(cx - 14, size.height * 0.4);
    pegboxPath.lineTo(cx + 14, size.height * 0.4);
    pegboxPath.lineTo(cx + 12, size.height * 0.15);
    pegboxPath.lineTo(cx - 12, size.height * 0.15);
    pegboxPath.close();
    canvas.drawPath(pegboxPath, paint);

    // Scroll (curled top)
    final scrollRect = Rect.fromCenter(
      center: Offset(cx, size.height * 0.1),
      width: 28,
      height: 28,
    );
    canvas.drawOval(scrollRect, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.1),
        width: 18,
        height: 18,
      ),
      darkPaint,
    );

    // Tuning pegs (4 pegs, 2 on each side)
    final pegPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Left pegs
    _drawPeg(canvas, Offset(cx - 14, size.height * 0.25), pegPaint);
    _drawPeg(canvas, Offset(cx - 14, size.height * 0.33), pegPaint);
    // Right pegs
    _drawPeg(canvas, Offset(cx + 14, size.height * 0.22), pegPaint);
    _drawPeg(canvas, Offset(cx + 14, size.height * 0.30), pegPaint);
  }

  void _drawPeg(Canvas canvas, Offset center, Paint paint) {
    // Peg body
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 16, height: 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
