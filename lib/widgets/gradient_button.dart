import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The rounded gradient buttons seen everywhere: LOGIN, WATCH REWARDED AD,
/// CONTINUE, SUBMIT REQUEST, SHARE NOW, etc. Includes a subtle press
/// scale-down animation and an optional glow.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final bool loading;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = AppGradients.primaryButton,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _controller.forward(),
      onTapUp: disabled ? null : (_) => _controller.reverse(),
      onTapCancel: disabled ? null : () => _controller.reverse(),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: disabled
                ? LinearGradient(colors: [
                    AppColors.surface2,
                    AppColors.surface2,
                  ])
                : widget.gradient,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: (widget.gradient.colors.first).withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppText.body(
                        size: 16,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary / outline style button, used for "Go to Home" and similar
/// lower-emphasis actions that sit under a primary GradientButton.
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.glassBorder, width: 1),
          backgroundColor: AppColors.surface2.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 16,
            color: AppColors.text,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
