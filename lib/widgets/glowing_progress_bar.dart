import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// The glowing purple progress bars used on Home Dashboard ("Today's
/// Progress"), Game Details ("Your Progress"), and Cooldown screen.
///
/// Fill width eases into place over 800ms with a slight overshoot â€”
/// mirrors the reference app's .progress-fill exactly
/// (transition:width .8s cubic-bezier(.34,1.2,.64,1)).
class GlowingProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double height;
  final Gradient gradient;

  const GlowingProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient = AppGradients.primaryButton,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.surface2,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: AppMotion.smooth,
            builder: (context, animatedValue, _) {
              return FractionallySizedBox(
                widthFactor: animatedValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(height),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
