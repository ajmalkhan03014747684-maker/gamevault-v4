import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// A number that animates from its old value to a new one whenever it
/// changes (instead of jumping), optionally with a continuous pulsing
/// glow behind it.
///
/// - Count-up: added on top of the reference app (it always rendered
///   numbers as static text).
/// - Glow: mirrors the reference's .balance-amount / @keyframes
///   countGlow â€” a soft gold shadow that breathes every 3s.
class AnimatedStatNumber extends StatefulWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  final bool glow;
  final Color glowColor;

  const AnimatedStatNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.glow = false,
    this.glowColor = AppColors.gold,
  });

  @override
  State<AnimatedStatNumber> createState() => _AnimatedStatNumberState();
}

class _AnimatedStatNumberState extends State<AnimatedStatNumber> with SingleTickerProviderStateMixin {
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    if (widget.glow) {
      _glowController = AnimationController(vsync: this, duration: AppMotion.glowCycle)..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStatNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glow && _glowController == null) {
      _glowController = AnimationController(vsync: this, duration: AppMotion.glowCycle)..repeat(reverse: true);
    } else if (!widget.glow && _glowController != null) {
      _glowController!.dispose();
      _glowController = null;
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppText.heading(size: 24);

    Widget numberText(double animatedValue, double glowStrength) {
      final text = widget.decimals > 0
          ? animatedValue.toStringAsFixed(widget.decimals)
          : animatedValue.round().toString();
      return Text(
        text,
        style: style.copyWith(
          shadows: widget.glow
              ? [
                  Shadow(color: widget.glowColor.withOpacity(0.25 + 0.35 * glowStrength), blurRadius: 12 + 14 * glowStrength),
                ]
              : null,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: widget.value, end: widget.value),
      duration: AppMotion.slow,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        if (!widget.glow) return numberText(animatedValue, 0);
        return AnimatedBuilder(
          animation: _glowController!,
          builder: (context, _) => numberText(animatedValue, _glowController!.value),
        );
      },
    );
  }
}
