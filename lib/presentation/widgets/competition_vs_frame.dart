import 'package:flutter/material.dart';

import '../theme/competition_vs_frame.dart';
import '../../core/config/app_strings.dart';

/// Colored side of a match card.
///
/// Both sides are the same rounded panel; home also has a ground bar.
/// Position (left/right) distinguishes the sides, and the color is an
/// additional signal.
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
      label: home ? tr('ホーム側') : tr('アウェイ側'),
      child: CustomPaint(
        key: Key(home ? 'vs-frame-home-paint' : 'vs-frame-away-paint'),
        painter: CompetitionVsFramePainter(side: side, color: color),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 2, 4, home ? 8 : 2),
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
    final path = _framePath(size);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    if (side == CompetitionVsSideKind.home) _paintGround(canvas, size);
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

  /// Both sides share one rounded panel.
  Path _framePath(Size size) {
    final rect = (Offset.zero & size).deflate(1.5);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
  }

  @override
  bool shouldRepaint(covariant CompetitionVsFramePainter oldDelegate) =>
      oldDelegate.side != side || oldDelegate.color != color;
}
