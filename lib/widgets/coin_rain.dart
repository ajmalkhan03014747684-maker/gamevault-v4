import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// A short burst of falling coins/diamonds â€” mirrors the reference
/// app's .coin-rain / @keyframes coinFall exactly: each particle
/// falls ~200px, rotates 720deg, shrinks to nothing, and fades out,
/// over 0.9s. Self-disposing: drop it into a Stack, it plays once and
/// calls [onComplete] when done.
class CoinRain extends StatefulWidget {
  final VoidCallback? onComplete;
  final int count;
  final IconData icon;

  const CoinRain({
    super.key,
    this.onComplete,
    this.count = 10,
    this.icon = Icons.diamond_rounded,
  });

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _ParticleSpec {
  final double startXFraction; // 0..1 across the width
  final double delayFraction; // 0..1 of the total duration
  final double sizeFactor;
  _ParticleSpec(this.startXFraction, this.delayFraction, this.sizeFactor);
}

class _CoinRainState extends State<CoinRain> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ParticleSpec> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(
      widget.count,
      (_) => _ParticleSpec(rng.nextDouble(), rng.nextDouble() * 0.3, 0.8 + rng.nextDouble() * 0.6),
    );
    _controller = AnimationController(vsync: this, duration: AppMotion.coinFall)
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: _particles.map((p) {
                  // Each particle has its own small delay/duration
                  // window within the shared controller, matching how
                  // multiple coin-rain elements fire slightly apart.
                  final local = ((_controller.value - p.delayFraction) / (1 - p.delayFraction)).clamp(0.0, 1.0);
                  final eased = Curves.easeIn.transform(local);
                  final dy = eased * 200 * p.sizeFactor;
                  final rotation = eased * 720 * pi / 180;
                  final scale = (1 - eased).clamp(0.0, 1.0);
                  final opacity = (1 - eased).clamp(0.0, 1.0);

                  return Positioned(
                    left: p.startXFraction * constraints.maxWidth - 14,
                    top: 20 + dy,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: scale,
                          child: Icon(widget.icon, color: AppColors.gold, size: 26 * p.sizeFactor),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
