import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single shimmering placeholder block â€” mirrors the reference
/// app's .skeleton / @keyframes shimmerAnim: a lighter gradient band
/// sweeps left-to-right across a dark surface, on a 1.5s loop.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 10,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

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
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surface2,
            child: FractionallySizedBox(
              widthFactor: 3,
              alignment: Alignment(-1 + _controller.value * 4, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.surface2,
                      AppColors.surface2.withOpacity(0.4),
                      AppColors.surface2,
                    ],
                    stops: const [0.35, 0.5, 0.65],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A ready-made shimmering placeholder shaped like a typical list row
/// (icon + two lines of text) â€” drop this in wherever a screen is
/// loading a list of games/missions/rows, instead of a bare spinner.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const ShimmerBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 120, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 70, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Several shimmer rows stacked â€” the common case of "show N
/// placeholder rows while a list loads".
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ShimmerListTile()),
    );
  }
}
