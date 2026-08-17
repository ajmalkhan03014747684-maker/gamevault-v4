import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/cosmic_particles_background.dart';

/// Screen 1 â€” Splash Screen
/// Matches: dark cosmic background, glowing purple game controller icon,
/// "GAMEVAULT" wordmark (GAME in white, VAULT in purple), tagline,
/// bottom loading bar that fills to 100% then navigates on.
///
/// The icon now pulses continuously (subtle breathing scale) and sits
/// in front of a slowly rotating gradient halo â€” mirrors the reference
/// app's pulseIcon / orbRotate keyframes.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _rotateController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _logoOpacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _startLoading();
  }

  Future<void> _startLoading() async {
    // Animate the bottom bar from 0 -> 100 over ~2.2s, then hand off.
    const totalDuration = Duration(milliseconds: 2200);
    const steps = 100;
    final stepDelay = totalDuration ~/ steps;

    for (var i = 0; i <= steps; i++) {
      if (!mounted) return;
      await Future.delayed(stepDelay);
      setState(() => _loadingProgress = i / steps);
    }

    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CosmicParticlesBackground(
        child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: _GlowingControllerIcon(
                      pulse: _pulseController,
                      rotate: _rotateController,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'GAME',
                          style: AppText.heading(size: 34, color: Colors.white),
                        ),
                        TextSpan(
                          text: 'VAULT',
                          style: AppText.heading(
                            size: 34,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: Text(
                    'EARN GAME CURRENCY',
                    style: AppText.caption(size: 13, color: AppColors.muted)
                        .copyWith(letterSpacing: 3),
                  ),
                ),
                const Spacer(flex: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Loading...', style: AppText.caption()),
                    Text(
                      '${(_loadingProgress * 100).round()}%',
                      style: AppText.caption(color: AppColors.text),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GlowingProgressBar(value: _loadingProgress, height: 6),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _GlowingControllerIcon extends StatelessWidget {
  final Animation<double> pulse;
  final Animation<double> rotate;

  const _GlowingControllerIcon({required this.pulse, required this.rotate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating gradient halo â€” a soft ring that slowly spins
          // behind the icon, mirrors the reference's orbRotate.
          AnimatedBuilder(
            animation: rotate,
            builder: (context, child) {
              return Transform.rotate(
                angle: rotate.value * 2 * 3.14159,
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.0),
                    AppColors.primaryPurple.withOpacity(0.5),
                    AppColors.secondaryOrange.withOpacity(0.35),
                    AppColors.primaryPurple.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Pulsing icon â€” breathes gently in place, mirrors
          // pulseIcon.
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final scale = 1.0 + (pulse.value * 0.06);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.35),
                    AppColors.primaryPurple.withOpacity(0.0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primaryButton,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
