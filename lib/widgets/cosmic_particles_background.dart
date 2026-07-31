import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft floating/glowing dots drifting slowly behind content — the same
/// "popping particle" feel as the cosmic backgrounds in the reference
/// mockups. Cheap to run (small fixed particle count, simple linear
/// motion), safe to layer behind any screen's content.
class CosmicParticlesBackground extends StatefulWidget {
  final int particleCount;
  final Widget? child;

  const CosmicParticlesBackground({
    super.key,
    this.particleCount = 18,
    this.child,
  });

  @override
  State<CosmicParticlesBackground> createState() => _CosmicParticlesBackgroundState();
}

class _Particle {
  double x, y, radius, speed, opacity;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class _CosmicParticlesBackgroundState extends State<CosmicParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    final colors = [
      AppColors.primaryPurple,
      AppColors.secondaryOrange,
      AppColors.text,
    ];
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 1.0 + rand.nextDouble() * 2.5,
        speed: 0.02 + rand.nextDouble() * 0.06,
        opacity: 0.15 + rand.nextDouble() * 0.35,
        color: colors[rand.nextInt(colors.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - t * p.speed) % 1.0;
      final dx = p.x + (sin((t * 2 * pi) + p.x * 10) * 0.01);
      final offset = Offset(dx * size.width, dy * size.height);

      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(offset, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
