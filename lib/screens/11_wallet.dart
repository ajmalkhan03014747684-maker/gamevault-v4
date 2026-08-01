import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 11 — Wallet
/// Pulls real balance and ad counts from Supabase via GameDataService.
class WalletScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final VoidCallback onHistoryTapped;
  final VoidCallback onWithdrawTapped;

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
  bool _historyTab = true;
  double _balance = 0.0;
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
      // Sums across the user's known games — adjust the game list
      // source once you have a real "my games" table if this should
      // be scoped differently.
      double total = 0;
      for (final g in kGames) {
        total += await GameDataService.instance.getBalance(g.name);
      }
      final adsToday = await GameDataService.instance.getAdsWatchedToday();
      final totalAds = await GameDataService.instance.getTotalAdsWatched();
      if (!mounted) return;
      setState(() {
        _balance = total;
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
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('My Wallet', style: AppText.heading(size: 22)),
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 40),
                          const SizedBox(height: 10),
                          _loading
                              ? const SizedBox(
                                  height: 32,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : Text(_balance.toStringAsFixed(2), style: AppText.heading(size: 32)),
                          const SizedBox(height: 4),
                          Text('Total Balance', style: AppText.caption()),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: AppText.caption(size: 11, color: AppColors.dangerRed)),
                    ],
                    const SizedBox(height: 14),
                    GradientButton(
                      label: 'WITHDRAW',
                      icon: Icons.arrow_downward_rounded,
                      onPressed: widget.onWithdrawTapped,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _historyTab = true);
                                widget.onHistoryTapped();
                              },
                              child: _tab('History', _historyTab),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _historyTab = false),
                              child: _tab('Transactions', !_historyTab),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Earning Summary', style: AppText.body(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _row('Ads Watched Today', '$_adsToday'),
                    _row('Total Ads Watched', '$_totalAds'),
                    _row('Current Balance', _balance.toStringAsFixed(2)),
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

  Widget _tab(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button - 2),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: AppText.body(size: 13, weight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
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
