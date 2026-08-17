import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/cooldown_badge.dart';
import '../widgets/animated_stat_number.dart';
import '../widgets/stagger_fade_in.dart';
import '../services/game_data_service.dart';
import '../services/auth_service.dart';

/// Represents a game loaded live from Supabase.
///
/// FIX: previously had no `id` field at all â€” every screen downstream
/// (Game Details, Ad Watch, Withdraw) was using `name` as a stand-in
/// for the database game_id. Since that column is a uuid, every
/// threshold/balance/withdraw lookup for that game was silently
/// failing. `id` is now the real source of truth everywhere.
class GameInfo {
  final String id;
  final String name;
  final String currency;
  final IconData icon;
  const GameInfo({required this.id, required this.name, required this.currency, required this.icon});

  factory GameInfo.fromRow(Map<String, dynamic> row) {
    return GameInfo(
      id: (row['id'] ?? '').toString(),
      name: (row['name'] as String?) ?? 'Unknown Game',
      currency: (row['currency_name'] as String?) ?? 'Currency',
      icon: _iconForGame((row['name'] as String?) ?? ''),
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

const kFallbackGames = <GameInfo>[];

/// Screen 3 â€” Home Dashboard
class HomeDashboardScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final VoidCallback onSelectGameTapped;
  final VoidCallback onNotificationsTapped;
  final VoidCallback onMiniGamesTapped;
  final VoidCallback onMissionsTapped;
  final VoidCallback onLeaderboardTapped;
  final void Function(GameInfo game) onGameRowTapped;

  const HomeDashboardScreen({
    super.key,
    required this.onNavTap,
    required this.onSelectGameTapped,
    required this.onNotificationsTapped,
    required this.onMiniGamesTapped,
    required this.onMissionsTapped,
    required this.onLeaderboardTapped,
    required this.onGameRowTapped,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  List<GameInfo> _games = [];
  int _adsToday = 0;
  int _totalAds = 0;
  String _username = 'Player';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Each data source is fetched independently so a failure in one
  /// can never wipe out data that already loaded successfully from
  /// another.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final errors = <String>[];

    List<GameInfo> games = _games;
    try {
      final gameRows = await GameDataService.instance.getActiveGames();
      games = gameRows.map((r) => GameInfo.fromRow(r)).toList();
    } on GameDataException catch (e) {
      errors.add(e.message);
    }

    int adsToday = _adsToday;
    try {
      adsToday = await GameDataService.instance.getAdsWatchedToday();
    } on GameDataException catch (e) {
      errors.add(e.message);
    }

    int totalAds = _totalAds;
    try {
      totalAds = await GameDataService.instance.getTotalAdsWatched();
    } on GameDataException catch (e) {
      errors.add(e.message);
    }

    String username = _username;
    try {
      final profile = await AuthService.instance.getProfile();
      final fromProfile = (profile['username'] as String?)?.trim();
      if (fromProfile != null && fromProfile.isNotEmpty) username = fromProfile;
    } catch (_) {
      // Keep whatever we already had rather than surfacing a raw
      // exception for a non-critical greeting.
    }

    if (!mounted) return;
    setState(() {
      _games = games.isNotEmpty ? games : kFallbackGames;
      _adsToday = adsToday;
      _totalAds = totalAds;
      _username = username;
      _error = errors.isNotEmpty ? 'Some data could not load. Pull to refresh.' : null;
      _loading = false;
    });
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
                      children: [
                        Text('Game Vault', style: AppText.heading(size: 18)),
                        const Spacer(),
                        const CooldownBadge(),
                        const SizedBox(width: 10),
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
                              Text('Hi, $_username', style: AppText.body(size: 15, weight: FontWeight.w700)),
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

                    // FIX: Total Balance card removed (a single sum
                    // across different games' currencies never meant
                    // anything real â€” see Wallet for the real
                    // per-currency breakdown). Ads Watched Today now
                    // takes the full-width card spot instead.
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ads Watched Today', style: AppText.caption()),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold, size: 26),
                                    const SizedBox(width: 8),
                                    _loading
                                        ? const SizedBox(width: 60, height: 24, child: LinearProgressIndicator())
                                        : AnimatedStatNumber(value: _adsToday.toDouble(), style: AppText.heading(size: 32)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Ads Watched', style: AppText.caption()),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.ondemand_video_rounded, color: AppColors.gold, size: 26),
                                    const SizedBox(width: 8),
                                    _loading
                                        ? const SizedBox(width: 60, height: 24, child: LinearProgressIndicator())
                                        : AnimatedStatNumber(
                                            value: _totalAds.toDouble(),
                                            style: AppText.heading(size: 32),
                                            glow: true,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
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
                          onTap: widget.onSelectGameTapped,
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
                    else if (_games.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No active games yet.', style: AppText.caption())),
                      )
                    else
                      ..._games.take(3).toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final g = entry.value;
                        return StaggerFadeIn(
                          index: i,
                          child: Padding(
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
                          ),
                        );
                      }),
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
