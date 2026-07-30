import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/gradient_button.dart';
import '03_home_dashboard.dart';

/// Screen 5 — Game Details
class GameDetailsScreen extends StatelessWidget {
  final GameInfo game;
  final VoidCallback onBack;
  final VoidCallback onWatchAd;
  final int adsWatched;
  final int adsRequired;
  final int rewardAmount;

  const GameDetailsScreen({
    super.key,
    required this.game,
    required this.onBack,
    required this.onWatchAd,
    this.adsWatched = 42,
    this.adsRequired = 60,
    this.rewardAmount = 26,
  });

  @override
  Widget build(BuildContext context) {
    final adsLeft = adsRequired - adsWatched;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                ),
                const Spacer(),
                const Icon(Icons.menu_rounded, color: AppColors.text),
                const SizedBox(width: 16),
                const Icon(Icons.notifications_none_rounded, color: AppColors.text),
              ],
            ),
            const SizedBox(height: 16),
            Text(game.name, style: AppText.heading(size: 26)),
            Text(game.currency, style: AppText.caption(size: 14)),
            const SizedBox(height: 16),

            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.35),
                    AppColors.surface,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(game.icon, size: 56, color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Progress', style: AppText.body(size: 14, weight: FontWeight.w600)),
                Text('$adsWatched/$adsRequired Ads', style: AppText.caption(color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 8),
            GlowingProgressBar(value: adsWatched / adsRequired),
            const SizedBox(height: 6),
            Text('$adsLeft Ads more to get $rewardAmount ${game.currency}', style: AppText.caption(size: 12)),
            const SizedBox(height: 22),

            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$rewardAmount ${game.currency}', style: AppText.body(size: 16, weight: FontWeight.w700)),
                        Text('After $adsRequired Ads', style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            GradientButton(
              label: 'WATCH REWARDED AD',
              gradient: AppGradients.rewardButton,
              icon: Icons.play_arrow_rounded,
              onPressed: onWatchAd,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Watch ad and get +1 Progress', style: AppText.caption(size: 12)),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text('Withdraw Rates', style: AppText.body(size: 14, weight: FontWeight.w600)),
                  const Spacer(),
                  Text('View rates for this game', style: AppText.caption(size: 12)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
