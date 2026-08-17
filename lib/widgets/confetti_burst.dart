import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Confetti burst radiating outward from the center â€” reserved
/// specifically for the CYCLE-COMPLETE moment (real currency earned),
/// so it reads as a bigger deal than the every-ad coin rain. Not part
/// of the reference app; added because this app's core "big win"
/// moment (finishing a cycle) didn't have anything distinct from a
/// normal ad watch.
class ConfettiBurst extends StatefulWidget {
  final VoidCallback? onComplete;
  final int count;

  const ConfettiBurst({super.key, this.onComplete, this.count = 24});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiPiece {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;
  _ConfettiPiece(this.angle, this.distance, this.size, this.color, this.spin);
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  static const _colors = [
    AppColors.gold,
    AppColors.primaryPurple,
    AppColors.successGreen,
    AppColors.secondaryOrange,
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _pieces = List.generate(widget.count, (_) {
      return _ConfettiPiece(
        rng.nextDouble() * 2 * pi,
        60 + rng.nextDouble() * 90,
        5 + rng.nextDouble() * 5,
        _colors[rng.nextInt(_colors.length)],
        (rng.nextDouble() - 0.5) * 6,
      );
    });
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward().whenComplete(() => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_controller.value);
            final opacity = (1 - _controller.value).clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              children: _pieces.map((p) {
                final dx = cos(p.angle) * p.distance * t;
                final dy = sin(p.angle) * p.distance * t - (30 * t); // slight upward arc
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: p.spin * _controller.value * 2 * pi,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: p.size,
                        height: p.size * 2,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
