import 'package:flutter/material.dart';

import '../theme/competition_vs_frame.dart';

/// Colored side of a match card.
///
/// Home is a rounded panel with a ground bar. Away is a panel whose outer
/// edge comes to a point, with a chevron mark. Position (left/right) and
/// these shapes distinguish the sides; the color is an additional signal.
/// The frame does not draw a letter, crest, or flag.
class CompetitionVsSide extends StatelessWidget {
  const CompetitionVsSide({
    super.key,
    required this.side,
    required this.color,
    required this.child,
  });

  final CompetitionVsSideKind side;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final home = side == CompetitionVsSideKind.home;
    return Semantics(
      key: Key(home ? 'vs-frame-home' : 'vs-frame-away'),
      container: true,
      label: home ? 'ホーム側' : 'アウェイ側',
      child: CustomPaint(
        key: Key(home ? 'vs-frame-home-paint' : 'vs-frame-away-paint'),
        painter: CompetitionVsFramePainter(side: side, color: color),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 2, home ? 4 : 14, home ? 8 : 2),
          child: child,
        ),
      ),
    );
  }
}

class CompetitionVsFramePainter extends CustomPainter {
  const CompetitionVsFramePainter({required this.side, required this.color});

  final CompetitionVsSideKind side;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = competitionVsFrameFill(color);
    final stroke = Paint()
      ..color = competitionVsFrameInk(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final path = side == CompetitionVsSideKind.home
        ? _homePath(size)
        : _awayPath(size);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    if (side == CompetitionVsSideKind.home) {
      _paintGround(canvas, size);
    } else {
      _paintChevron(canvas, size);
    }
  }

  void _paintGround(Canvas canvas, Size size) {
    final ground = Paint()..color = competitionVsFrameInk(color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, size.height - 7, size.width - 28, 3),
        const Radius.circular(2),
      ),
      ground,
    );
  }

  void _paintChevron(Canvas canvas, Size size) {
    final mark = Paint()
      ..color = competitionVsFrameInk(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final x = size.width - 12;
    final y = size.height / 2;
    canvas.drawPath(
      Path()
        ..moveTo(x - 7, y - 8)
        ..lineTo(x, y)
        ..lineTo(x - 7, y + 8),
      mark,
    );
  }

  Path _homePath(Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
  }

  /// Outer edge comes to a point. That outline is not the home rectangle.
  Path _awayPath(Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    final tip = rect.right;
    final notch = tip - 12;
    return Path()
      ..moveTo(rect.left + 14, rect.top)
      ..lineTo(notch, rect.top)
      ..lineTo(tip, rect.center.dy)
      ..lineTo(notch, rect.bottom)
      ..lineTo(rect.left + 14, rect.bottom)
      ..quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - 14)
      ..lineTo(rect.left, rect.top + 14)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + 14, rect.top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CompetitionVsFramePainter oldDelegate) =>
      oldDelegate.side != side || oldDelegate.color != color;
}
