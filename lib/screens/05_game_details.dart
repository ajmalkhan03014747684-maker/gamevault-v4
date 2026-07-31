import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/ad_disclosure_dialog.dart';
import '../services/ads_service.dart';
import '03_home_dashboard.dart';

/// Screen 5 — Game Details
/// Now wired to AdsService with full Huawei ad-compliance flow:
/// no-ad-available state, pre-ad disclosure dialog, and a tap
/// debounce/lock so the button can't be double-tapped into firing
/// two ad requests.
class GameDetailsScreen extends StatefulWidget {
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
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  bool _checkingAd = true;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    setState(() => _checkingAd = true);
    await AdsService.instance.preloadRewardedAd();
    if (!mounted) return;
    setState(() => _checkingAd = false);
  }

  Future<void> _onWatchAdTapped() async {
    if (_requestInFlight || !AdsService.instance.isAdReady) return;
    setState(() => _requestInFlight = true);

    final confirmed = await showAdDisclosureDialog(
      context,
      rewardText: '${widget.rewardAmount} ${widget.game.currency}',
    );

    if (!confirmed) {
      setState(() => _requestInFlight = false);
      // Ad slot was locked by preloadRewardedAd's state change on
      // showRewardedAd only, so a cancelled disclosure just needs a
      // fresh preload for next time.
      await _loadAd();
      return;
    }

    if (!mounted) return;
    setState(() => _requestInFlight = false);
    widget.onWatchAd(); // hands off to the Ad Watch screen, which calls
                         // AdsService.showRewardedAd() itself
  }

  @override
  Widget build(BuildContext context) {
    final adsLeft = widget.adsRequired - widget.adsWatched;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                ),
                const Spacer(),
                const Icon(Icons.menu_rounded, color: AppColors.text),
                const SizedBox(width: 16),
                const Icon(Icons.notifications_none_rounded, color: AppColors.text),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.game.name, style: AppText.heading(size: 26)),
            Text(widget.game.currency, style: AppText.caption(size: 14)),
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
              child: Icon(widget.game.icon, size: 56, color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Progress', style: AppText.body(size: 14, weight: FontWeight.w600)),
                Text('${widget.adsWatched}/${widget.adsRequired} Ads', style: AppText.caption(color: AppColors.text)),
              ],
            ),
            const SizedBox(height: 8),
            GlowingProgressBar(value: widget.adsWatched / widget.adsRequired),
            const SizedBox(height: 6),
            Text('$adsLeft Ads more to get ${widget.rewardAmount} ${widget.game.currency}', style: AppText.caption(size: 12)),
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
                        Text('${widget.rewardAmount} ${widget.game.currency}', style: AppText.body(size: 16, weight: FontWeight.w700)),
                        Text('After ${widget.adsRequired} Ads', style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_checkingAd)
              const SizedBox(
                height: 52,
                child: Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            else if (!AdsService.instance.isAdReady)
              const NoAdAvailableNotice()
            else
              GradientButton(
                label: 'WATCH REWARDED AD',
                gradient: AppGradients.rewardButton,
                icon: Icons.play_arrow_rounded,
                loading: _requestInFlight,
                onPressed: _onWatchAdTapped,
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
