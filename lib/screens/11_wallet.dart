import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/gradient_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/cooldown_badge.dart';
import '../widgets/animated_stat_number.dart';
import '../widgets/stagger_fade_in.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 11 â€” Wallet
///
/// FIX: previously showed one "Total Balance" card summing balances
/// across every game â€” meaningless once games have different
/// currencies (CP for Call of Duty, Diamonds for Free Fire, etc. are
/// not the same unit and shouldn't be added together). Now shows one
/// card per active game with that game's own currency total, each
/// with its own Withdraw action.
class WalletScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final VoidCallback onHistoryTapped;
  final void Function(GameInfo game) onWithdrawTapped;

  const WalletScreen({
    super.key,
    required this.onNavTap,
    required this.onHistoryTapped,
    required this.onWithdrawTapped,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<Map<String, dynamic>> _balances = [];
  int _adsToday = 0;
  int _totalAds = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balances = await GameDataService.instance.getAllGameBalances();
      final adsToday = await GameDataService.instance.getAdsWatchedToday();
      final totalAds = await GameDataService.instance.getTotalAdsWatched();
      if (!mounted) return;
      setState(() {
        _balances = balances;
        _adsToday = adsToday;
        _totalAds = totalAds;
        _loading = false;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Wallet', style: AppText.heading(size: 22)),
                        Row(
                          children: [
                            const CooldownBadge(),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: widget.onHistoryTapped,
                              child: Text('History', style: AppText.caption(color: AppColors.primaryPurple)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    if (_error != null) ...[
                      Text(_error!, style: AppText.caption(size: 11, color: AppColors.dangerRed)),
                      const SizedBox(height: 10),
                    ],

                    Text('Your Currencies', style: AppText.body(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_balances.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No active games yet.', style: AppText.caption())),
                      )
                    else
                      ..._balances.asMap().entries.map((entry) {
                        final i = entry.key;
                        final b = entry.value;
                        final name = (b['name'] as String?) ?? 'Game';
                        final currency = (b['currency_name'] as String?) ?? 'Currency';
                        final balance = (b['balance'] as num?)?.toDouble() ?? 0;
                        final game = GameInfo(
                          id: (b['id'] ?? '').toString(),
                          name: name,
                          currency: currency,
                          icon: GameInfo.fromRow({'name': name}).icon,
                        );
                        return StaggerFadeIn(
                          index: i,
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(game.icon, color: AppColors.primaryPurple),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          Text('Total $currency Earned', style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    AnimatedStatNumber(value: balance, decimals: 2, style: AppText.heading(size: 20)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: balance > 0 ? () => widget.onWithdrawTapped(game) : null,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primaryPurple),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                                    ),
                                    child: Text('Withdraw $currency', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.primaryPurple)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        );
                      }),

                    const SizedBox(height: 12),
                    Text('Earning Summary', style: AppText.body(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _row('Ads Watched Today', '$_adsToday'),
                    _row('Total Ads Watched', '$_totalAds'),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentIndex: 2, onTap: widget.onNavTap),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body(size: 14)),
            Text(value, style: AppText.body(size: 14, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
