import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/ad_disclosure_dialog.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 5 — Game Details
/// Now loads REAL per-game progress and the REAL next ad_thresholds
/// tier from Supabase — this is what makes Admin Panel's "Ad
/// Thresholds" screen actually control what users see, instead of
/// this screen showing hardcoded 60/26 regardless of admin config.
class GameDetailsScreen extends StatefulWidget {
  final GameInfo game;
  final String gameId;
  final VoidCallback onBack;
  final void Function(int currentAds, int adsRequired, double rewardAmount) onWatchAd;

  const GameDetailsScreen({
    super.key,
    required this.game,
    required this.gameId,
    required this.onBack,
    required this.onWatchAd,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  bool _checkingAd = true;
  bool _requestInFlight = false;
  bool _dailyLimitReached = false;
  bool _loadingProgress = true;
  String? _error;

  int _currentAds = 0;
  int _adsRequired = 60;
  double _rewardAmount = 0;
  bool _hasRealThreshold = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadAd();
  }

  Future<void> _loadProgress() async {
    setState(() => _loadingProgress = true);
    try {
      final currentAds = await GameDataService.instance.getAdsWatchedForGame(widget.gameId);
      final threshold = await GameDataService.instance.getNextThreshold(widget.gameId, currentAds);

      if (!mounted) return;
      setState(() {
        _currentAds = currentAds;
        if (threshold != null) {
          _adsRequired = (threshold['ads_required'] as num?)?.toInt() ?? 60;
          _rewardAmount = (threshold['currency_reward'] as num?)?.toDouble() ?? 0;
          _hasRealThreshold = true;
        } else {
          // No admin-configured thresholds for this game yet — fall
          // back to a sane default rather than showing 0/0.
          _adsRequired = 60;
          _rewardAmount = 0;
          _hasRealThreshold = false;
        }
        _loadingProgress = false;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingProgress = false;
      });
    }
  }

  Future<void> _loadAd() async {
    setState(() => _checkingAd = true);

    final limitReached = await GameDataService.instance.hasReachedDailyLimit();
    if (limitReached) {
      if (!mounted) return;
      setState(() {
        _dailyLimitReached = true;
        _checkingAd = false;
      });
      return;
    }

    await AdsService.instance.preloadRewardedAd();
    if (!mounted) return;
    setState(() {
      _dailyLimitReached = false;
      _checkingAd = false;
    });
  }

  Future<void> _onWatchAdTapped() async {
    if (_requestInFlight || !AdsService.instance.isAdReady) return;
    setState(() => _requestInFlight = true);

    final confirmed = await showAdDisclosureDialog(
      context,
      rewardText: '${_rewardAmount.toStringAsFixed(2)} ${widget.game.currency}',
    );

    if (!confirmed) {
      setState(() => _requestInFlight = false);
      await _loadAd();
      return;
    }

    if (!mounted) return;
    setState(() => _requestInFlight = false);
    widget.onWatchAd(_currentAds, _adsRequired, _rewardAmount);
  }

  @override
  Widget build(BuildContext context) {
    final adsLeft = (_adsRequired - _currentAds).clamp(0, _adsRequired);
    final progress = _adsRequired > 0 ? (_currentAds / _adsRequired).clamp(0.0, 1.0) : 0.0;

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

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),

            if (_loadingProgress)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Progress', style: AppText.body(size: 14, weight: FontWeight.w600)),
                  Text('$_currentAds/$_adsRequired Ads', style: AppText.caption(color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 8),
              GlowingProgressBar(value: progress),
              const SizedBox(height: 6),
              if (!_hasRealThreshold)
                Text('No reward tiers configured for this game yet', style: AppText.caption(size: 12, color: AppColors.secondaryOrange))
              else
                Text('$adsLeft Ads more to get ${_rewardAmount.toStringAsFixed(2)} ${widget.game.currency}', style: AppText.caption(size: 12)),
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
                          Text('${_rewardAmount.toStringAsFixed(2)} ${widget.game.currency}', style: AppText.body(size: 16, weight: FontWeight.w700)),
                          Text('After $_adsRequired Ads', style: AppText.caption(size: 12)),
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
              else if (_dailyLimitReached)
                Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface2.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.secondaryOrange.withOpacity(0.4)),
                  ),
                  child: Text(
                    'Daily ad limit reached — come back tomorrow',
                    style: AppText.caption(size: 13, color: AppColors.secondaryOrange),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (!_hasRealThreshold)
                const NoAdAvailableNotice()
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
            ],
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () => _showWithdrawRates(context),
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

  Future<void> _showWithdrawRates(BuildContext context) async {
    List<Map<String, dynamic>> rates = [];
    String? error;
    try {
      rates = await GameDataService.instance.getWithdrawRates(widget.gameId);
    } on GameDataException catch (e) {
      error = e.message;
    }
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Withdraw Rates — ${widget.game.name}', style: AppText.body(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (error != null)
              Text(error, style: AppText.caption(size: 12, color: AppColors.dangerRed))
            else if (rates.isEmpty)
              Text('No withdraw rates configured for this game yet.', style: AppText.caption())
            else
              ...rates.map((r) {
                final ads = r['ads_required'] ?? 0;
                final given = (r['currency_given'] as num?)?.toDouble() ?? 0;
                final target = (r['target_currency'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Every $ads ads → ${given.toStringAsFixed(2)} ${widget.game.currency} (target: ${target.toStringAsFixed(2)})',
                    style: AppText.body(size: 13),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
