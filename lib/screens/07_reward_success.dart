import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

/// Screen 7 — Reward Success
///
/// FIX: now shows the real amount credited (if this ad completed a
/// cycle) instead of an always-generic "+1 Progress" message.
class RewardSuccessScreen extends StatefulWidget {
  final int newAds;
  final int requiredAds;
  final bool cycleCompleted;
  final double earned;
  final String currency;
  final VoidCallback onContinue;

  const RewardSuccessScreen({
    super.key,
    required this.newAds,
    required this.requiredAds,
    required this.onContinue,
    this.cycleCompleted = false,
    this.earned = 0,
    this.currency = '',
  });

  @override
  State<RewardSuccessScreen> createState() => _RewardSuccessScreenState();
}

class _RewardSuccessScreenState extends State<RewardSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.successGlow,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen.withOpacity(0.55),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 28),
              Text(widget.cycleCompleted ? 'Cycle Complete!' : 'Reward Received!', style: AppText.heading(size: 24)),
              const SizedBox(height: 6),
              Text(
                widget.cycleCompleted
                    ? '+${widget.earned.toStringAsFixed(2)} ${widget.currency}'
                    : '+1 Progress',
                style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.successGreen),
              ),
              const Spacer(flex: 2),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Your Progress: ', style: AppText.caption(size: 13)),
                    Text('${widget.newAds}/${widget.requiredAds} Ads',
                        style: AppText.body(size: 14, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              GradientButton(label: 'CONTINUE', onPressed: widget.onContinue),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
