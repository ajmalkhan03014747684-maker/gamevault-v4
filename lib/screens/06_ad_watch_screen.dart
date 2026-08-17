import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';

/// Screen 6 â€” Ad Watch Screen
///
/// FIX: now calls recordAdWatch, which auto-credits the cycle reward
/// the moment this ad completes a full cycle (matching the reference
/// app) â€” no separate manual claim step. The result tells us whether
/// this ad completed a cycle so the reward screen can show the real
/// amount earned instead of a generic "+1 progress".
class AdWatchScreen extends StatefulWidget {
  final int currentAds;
  final int requiredAds;
  final String gameId;
  final double rewardAmount;
  final void Function(bool cycleCompleted, double earned) onAdComplete;
  final VoidCallback onAdFailed;

  const AdWatchScreen({
    super.key,
    required this.currentAds,
    required this.requiredAds,
    required this.gameId,
    required this.rewardAmount,
    required this.onAdComplete,
    required this.onAdFailed,
  });

  @override
  State<AdWatchScreen> createState() => _AdWatchScreenState();
}

class _AdWatchScreenState extends State<AdWatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _playAd();
  }

  Future<void> _playAd() async {
    final result = await AdsService.instance.showRewardedAd();
    if (!mounted) return;

    if (result != AdResult.completed) {
      widget.onAdFailed();
      return;
    }

    try {
      final info = await GameDataService.instance.recordAdWatch(gameId: widget.gameId);
      if (!mounted) return;
      final cycleCompleted = info['cycle_completed'] == true;
      final earned = (info['earned'] as num?)?.toDouble() ?? 0;
      // Bigger haptic for the real-currency moment, lighter for a
      // normal progress tick.
      cycleCompleted ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
      widget.onAdComplete(cycleCompleted, earned);
    } on GameDataException catch (e) {
      if (!mounted) return;
      // Ad played, but logging failed (e.g. RLS/schema issue) â€” show
      // the real error instead of silently pretending it worked.
      setState(() => _errorMessage = e.message);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_rounded, color: AppColors.text),
                    const Spacer(),
                    const Icon(Icons.notifications_none_rounded, color: AppColors.text),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Watch Rewarded Ad', style: AppText.heading(size: 22)),
                const SizedBox(height: 4),
                Text('Watch full ad to get reward', style: AppText.caption()),
                const Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primaryButton,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.55),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Reward +1 Progress',
                    style: AppText.body(size: 16, weight: FontWeight.w700, color: AppColors.successGreen)),
                const SizedBox(height: 8),
                Text('Your Progress: ${widget.currentAds}/${widget.requiredAds} Ads', style: AppText.caption()),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onAdFailed,
                    child: Text('Go back', style: AppText.body(color: AppColors.primaryPurple)),
                  ),
                ],
                const Spacer(),
                Text('Ad will start automatically', style: AppText.caption(size: 12)),
                const SizedBox(height: 4),
                Text('Please don\'t close the ad', style: AppText.caption(size: 12)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
