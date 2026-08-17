import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A consistent "nothing here yet" treatment â€” an icon in a soft glow
/// circle, a title, and an optional subtitle, fading + scaling in
/// gently instead of a screen just showing plain gray text.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.25)),
                  ),
                  child: Icon(widget.icon, color: AppColors.primaryPurple.withOpacity(0.7), size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.text),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: AppText.caption(size: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
