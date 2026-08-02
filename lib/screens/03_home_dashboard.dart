import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/game_data_service.dart';
import '../services/auth_service.dart';

/// Represents a game, either loaded live from Supabase (via fromRow)
/// or as a temporary fallback while data is loading.
class GameInfo {
  final String name;
  final String currency;
  final IconData icon;
  const GameInfo(this.name, this.currency, this.icon);

  factory GameInfo.fromRow(Map<String, dynamic> row) {
    return GameInfo(
      (row['name'] as String?) ?? 'Unknown Game',
      (row['currency_name'] as String?) ?? 'Currency',
      _iconForGame((row['name'] as String?) ?? ''),
    );
  }

  static IconData _iconForGame(String name) {
    final n = name.toLowerCase();
    if (n.contains('free fire')) return Icons.local_fire_department_rounded;
    if (n.contains('pubg')) return Icons.military_tech_rounded;
    if (n.contains('mobile legends')) return Icons.shield_rounded;
    if (n.contains('call of duty') || n.contains('cod')) return Icons.gps_fixed_rounded;
    if (n.contains('roblox')) return Icons.widgets_rounded;
    if (n.contains('brawl stars')) return Icons.diamond_rounded;
    return Icons.sports_esports_rounded;
  }
}

/// Fallback shown only while the real list is loading, or if the
/// games table is genuinely empty — never used as a substitute for
/// real data once it's available.
const kFallbackGames = [
  GameInfo('Free Fire', 'Diamonds', Icons.local_fire_department_rounded),
];

/// Screen 3 — Home Dashboard
/// Now pulls the real active games list, real total balance, and real
/// ads-watched-today count from Supabase — this is what makes Admin
/// Panel's "Manage Games" toggle actually affect what users see.
class HomeDashboardScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final void Function(List<GameInfo> games) onSelectGameTapped;
  final VoidCallback onNotificationsTapped;
  final VoidCallback onMiniGamesTapped;
  final VoidCallback onDailyBonusTapped;
  final VoidCallback onMissionsTapped;
  final VoidCallback onLeaderboardTapped;
  final void Function(GameInfo game) onGameRowTapped;

  const HomeDashboardScreen({
    super.key,
    required this.onNavTap,
    required this.onSelectGameTapped,
    required this.onNotificationsTapped,
    required this.onMiniGamesTapped,
    required this.onDailyBonusTapped,
    required this.onMissionsTapped,
    required this.onLeaderboardTapped,
    required this.onGameRowTapped,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  List<GameInfo> _games = [];
  double _totalBalance = 0;
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
      final gameRows = await GameDataService.instance.getActiveGames();
      final games = gameRows.map((r) => GameInfo.fromRow(r)).toList();
      final balance = await GameDataService.instance.getTotalBalance();
      final adsToday = await GameDataService.instance.getAdsWatchedToday();
      final totalAds = await GameDataService.instance.getTotalAdsWatched();

      if (!mounted) return;
      setState(() {
        _games = games.isNotEmpty ? games : kFallbackGames;
        _totalBalance = balance;
        _adsToday = adsToday;
        _totalAds = totalAds;
        _loading = false;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _games = kFallbackGames;
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.instance.currentUser?.email?.split('@').first ?? 'Player';
    const dailyGoal = 60;
    final progress = (_adsToday / dailyGoal).clamp(0.0, 1.0);
    final adsLeft = (dailyGoal - _adsToday).clamp(0, dailyGoal);

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
                    Row(
                      children: [
                        const Icon(Icons.menu_rounded, color: AppColors.text),
                        const Spacer(),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.surface2,
                          child: const Icon(Icons.person, color: AppColors.muted),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, $username', style: AppText.body(size: 15, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNotificationsTapped,
                          child: const Icon(Icons.notifications_none_rounded, color: AppColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                      ),

                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Balance', style: AppText.caption()),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 22),
                                    const SizedBox(width: 6),
                                    _loading
                                        ? const SizedBox(width: 60, height: 20, child: LinearProgressIndicator())
                                        : Text(_totalBalance.toStringAsFixed(2), style: AppText.heading(size: 26)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'Ads Watched Today', value: '$_adsToday')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(label: 'Total Ads', value: '$_totalAds')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Today's Progress", style: AppText.body(size: 14, weight: FontWeight.w600)),
                        Text('$_adsToday/$dailyGoal Ads', style: AppText.caption(color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GlowingProgressBar(value: progress),
                    const SizedBox(height: 6),
                    Text('$adsLeft Ads more to next reward', style: AppText.caption(size: 12)),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _IconAction(icon: Icons.card_giftcard_rounded, label: 'Daily Bonus', onTap: widget.onDailyBonusTapped),
                        _IconAction(icon: Icons.flag_rounded, label: 'Missions', onTap: widget.onMissionsTapped),
                        _IconAction(icon: Icons.videogame_asset_rounded, label: 'Mini Games', onTap: widget.onMiniGamesTapped),
                        _IconAction(icon: Icons.leaderboard_rounded, label: 'Leaderboard', onTap: widget.onLeaderboardTapped),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Games', style: AppText.body(size: 16, weight: FontWeight.w700)),
                        GestureDetector(
                          onTap: () => widget.onSelectGameTapped(_games),
                          child: Text('View All', style: AppText.caption(color: AppColors.primaryPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ..._games.take(3).map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              onTap: () => widget.onGameRowTapped(g),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(g.icon, color: AppColors.primaryPurple),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(g.name, style: AppText.body(size: 14, weight: FontWeight.w600)),
                                        Text(g.currency, style: AppText.caption(size: 12)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                ],
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentIndex: 0, onTap: widget.onNavTap),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.heading(size: 20)),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption(size: 12)),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppText.caption(size: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
