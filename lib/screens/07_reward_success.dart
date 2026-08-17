import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/coin_rain.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/animated_stat_number.dart';

/// Screen 7 â€” Reward Success
///
/// Rebuilt around the reference app's .reward-popup: the card scales
/// in with an elastic overshoot (rewardPop), the earned amount glows
/// continuously (countGlow), and it scales back out on exit
/// (rewardHide) before handing off to onContinue. Coin rain plays on
/// every reward; a confetti burst plays additionally when a cycle
/// completed, so that (bigger, real-currency) moment reads as more of
/// a big deal than a normal ad-watch tick.
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

class _RewardSuccessScreenState extends State<RewardSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  bool _exiting = false;
  bool _showCoinRain = true;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(vsync: this, duration: AppMotion.rewardPop)..forward();

    if (widget.cycleCompleted) {
      // Slight delay so the confetti lands just after the popup has
      // finished bouncing in, rather than fighting it visually.
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _showConfetti = true);
      });
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _popController.reverse();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (_showCoinRain)
              Positioned.fill(
                child: CoinRain(
                  icon: widget.cycleCompleted ? Icons.diamond_rounded : Icons.play_circle_fill_rounded,
                  onComplete: () {
                    if (mounted) setState(() => _showCoinRain = false);
                  },
                ),
              ),
            if (_showConfetti)
              Positioned.fill(
                child: ConfettiBurst(
                  onComplete: () {
                    if (mounted) setState(() => _showConfetti = false);
                  },
                ),
              ),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _popController, curve: AppMotion.springy),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: GlassCard(
                    borderColor: AppColors.gold.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: widget.cycleCompleted ? AppGradients.rewardButton : AppGradients.successGlow,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.cycleCompleted ? AppColors.secondaryOrange : AppColors.successGreen).withOpacity(0.5),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.cycleCompleted ? Icons.emoji_events_rounded : Icons.check_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          widget.cycleCompleted ? 'Cycle Complete!' : 'Reward Received!',
                          style: AppText.heading(size: 22),
                        ),
                        const SizedBox(height: 10),
                        if (widget.cycleCompleted)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('+', style: TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w900)),
                              AnimatedStatNumber(
                                value: widget.earned,
                                decimals: 2,
                                glow: true,
                                style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 6),
                              Text(widget.currency, style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.gold)),
                            ],
                          )
                        else
                          Text('+1 Progress', style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.successGreen)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            'Your Progress: ${widget.newAds}/${widget.requiredAds} Ads',
                            style: AppText.body(size: 13, weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(label: 'CONTINUE', onPressed: _handleContinue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
