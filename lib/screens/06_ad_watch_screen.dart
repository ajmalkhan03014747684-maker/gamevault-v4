import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Screen 6 — Ad Watch Screen
class AdWatchScreen extends StatefulWidget {
  final int currentAds;
  final int requiredAds;
  final VoidCallback onAdComplete;

  const AdWatchScreen({
    super.key,
    required this.currentAds,
    required this.requiredAds,
    required this.onAdComplete,
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

  @override
  void initState() {
    super.initState();
    // Simulated ad playback delay. Replace with real HMS Ads Kit callback
    // once credentials are provided.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onAdComplete();
    });
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
