import 'package:flutter/material.dart';

/// Stadium bowl drawn in code. Material icon fonts are not available in the
/// widget-test screenshots, where those glyphs become empty squares.
class StadiumCueMark extends StatelessWidget {
  const StadiumCueMark({super.key, required this.color, this.size = 28});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('stadium-cue-icon'),
      child: CustomPaint(
        size: Size.square(size),
        painter: _StadiumCuePainter(color),
      ),
    );
  }
}

/// Rail car drawn in code. A side view with windows and wheels, not an
/// airplane and not a font glyph.
class TransitCueMark extends StatelessWidget {
  const TransitCueMark({
    super.key,
    required this.color,
    required this.cutout,
    this.size = 28,
  });

  final Color color;
  final Color cutout;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('transit-cue-icon'),
      child: CustomPaint(
        size: Size.square(size),
        painter: _TransitCuePainter(ink: color, cutout: cutout),
      ),
    );
  }
}

/// Map pin drawn in code, used beside the venue name.
class VenuePinMark extends StatelessWidget {
  const VenuePinMark({
    super.key,
    required this.color,
    required this.hole,
    this.size = 16,
  });

  final Color color;
  final Color hole;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('venue-pin-mark'),
      child: CustomPaint(
        size: Size.square(size),
        painter: _VenuePinPainter(color: color, hole: hole),
      ),
    );
  }
}

class _StadiumCuePainter extends CustomPainter {
  const _StadiumCuePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.20, w * 0.96, h * 0.60),
      Radius.circular(h * 0.30),
    );
    final field = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.32, w * 0.60, h * 0.36),
      Radius.circular(h * 0.16),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(outer)
        ..addRRect(field),
      Paint()..color = color,
    );
    canvas.drawLine(
      Offset(w * 0.26, h * 0.50),
      Offset(w * 0.74, h * 0.50),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StadiumCuePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TransitCuePainter extends CustomPainter {
  const _TransitCuePainter({required this.ink, required this.cutout});

  final Color ink;
  final Color cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inkPaint = Paint()..color = ink;
    final cutPaint = Paint()..color = cutout;
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.34, h * 0.22),
      Offset(w * 0.66, h * 0.22),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.22),
      Offset(w * 0.50, h * 0.34),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.32, w * 0.92, h * 0.38),
        Radius.circular(w * 0.12),
      ),
      inkPaint,
    );
    for (final left in [0.14, 0.52]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * left, h * 0.40, w * 0.28, h * 0.16),
          Radius.circular(w * 0.04),
        ),
        cutPaint,
      );
    }
    for (final center in [0.28, 0.72]) {
      final wheel = Offset(w * center, h * 0.78);
      canvas.drawCircle(wheel, w * 0.10, inkPaint);
      canvas.drawCircle(wheel, w * 0.04, cutPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TransitCuePainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.cutout != cutout;
}

class _VenuePinPainter extends CustomPainter {
  const _VenuePinPainter({required this.color, required this.hole});

  final Color color;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pin = Path()
      ..moveTo(w * 0.50, h * 0.98)
      ..cubicTo(w * 0.02, h * 0.55, w * 0.12, h * 0.02, w * 0.50, h * 0.02)
      ..cubicTo(w * 0.88, h * 0.02, w * 0.98, h * 0.55, w * 0.50, h * 0.98)
      ..close();
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.36),
      w * 0.14,
      Paint()..color = hole,
    );
  }

  @override
  bool shouldRepaint(covariant _VenuePinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.hole != hole;
}
