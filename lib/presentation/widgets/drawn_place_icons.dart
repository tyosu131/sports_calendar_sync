import 'dart:math' as math;

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

/// Airplane drawn in code for the away (travel) side. Not a font glyph,
/// so it stays visible when the icon font is missing.
class TransitCueMark extends StatelessWidget {
  const TransitCueMark({
    super.key,
    required this.color,
    required this.cutout,
    this.size = 28,
  });

  final Color color;

  /// Kept for API compatibility with the previous rail-car mark.
  final Color cutout;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('transit-cue-icon'),
      child: CustomPaint(
        size: Size.square(size),
        painter: _AirplaneCuePainter(ink: color),
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

/// Top view of an airliner pointing up-right, like a departure sign.
class _AirplaneCuePainter extends CustomPainter {
  const _AirplaneCuePainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(math.pi / 4);
    canvas.translate(-w / 2, -h / 2);

    final plane = Path()
      // Nose
      ..moveTo(w * 0.50, h * 0.04)
      ..quadraticBezierTo(w * 0.57, h * 0.10, w * 0.57, h * 0.22)
      // Right wing
      ..lineTo(w * 0.57, h * 0.38)
      ..lineTo(w * 0.94, h * 0.58)
      ..lineTo(w * 0.94, h * 0.66)
      ..lineTo(w * 0.57, h * 0.56)
      // Right tail
      ..lineTo(w * 0.56, h * 0.80)
      ..lineTo(w * 0.70, h * 0.90)
      ..lineTo(w * 0.70, h * 0.96)
      ..lineTo(w * 0.50, h * 0.91)
      // Left tail
      ..lineTo(w * 0.30, h * 0.96)
      ..lineTo(w * 0.30, h * 0.90)
      ..lineTo(w * 0.44, h * 0.80)
      // Left wing
      ..lineTo(w * 0.43, h * 0.56)
      ..lineTo(w * 0.06, h * 0.66)
      ..lineTo(w * 0.06, h * 0.58)
      ..lineTo(w * 0.43, h * 0.38)
      ..lineTo(w * 0.43, h * 0.22)
      ..quadraticBezierTo(w * 0.43, h * 0.10, w * 0.50, h * 0.04)
      ..close();
    canvas.drawPath(plane, Paint()..color = ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AirplaneCuePainter oldDelegate) =>
      oldDelegate.ink != ink;
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
