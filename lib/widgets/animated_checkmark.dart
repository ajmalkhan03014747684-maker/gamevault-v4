import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// A checkmark that draws itself stroke-by-stroke instead of just
/// appearing â€” plays once when it first mounts. Not from the
/// reference app (its "claimed" state was static text); added because
/// a checkmark actually being drawn reads as a much more satisfying
/// "done" moment than text popping in.
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCheckmark({super.key, this.size = 20, this.color = AppColors.successGreen});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.normal)..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            progress: Curves.easeOut.transform(_controller.value),
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.75)
      ..lineTo(size.width * 0.85, size.height * 0.25);

    final metrics = path.computeMetrics().toList();
    final drawPath = Path();
    for (final metric in metrics) {
      drawPath.addPath(metric.extractPath(0, metric.length * progress), Offset.zero);
    }
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) => oldDelegate.progress != progress;
}
