import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/bottom_nav_bar.dart';

class GameInfo {
  final String name;
  final String currency;
  final IconData icon;
  const GameInfo(this.name, this.currency, this.icon);
}

const kGames = [
  GameInfo('Free Fire', 'Diamonds', Icons.local_fire_department_rounded),
  GameInfo('PUBG Mobile', 'UC', Icons.military_tech_rounded),
  GameInfo('Mobile Legends', 'Diamonds', Icons.shield_rounded),
  GameInfo('Call of Duty Mobile', 'CP', Icons.gps_fixed_rounded),
  GameInfo('Roblox', 'Robux', Icons.widgets_rounded),
  GameInfo('Brawl Stars', 'Gems', Icons.diamond_rounded),
];

/// Screen 3 — Home Dashboard
class HomeDashboardScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final VoidCallback onSelectGameTapped;
  final VoidCallback onNotificationsTapped;
  final VoidCallback onMiniGamesTapped;
  final VoidCallback onDailyBonusTapped;
  final VoidCallback onMissionsTapped;
  final VoidCallback onLeaderboardTapped;

  const HomeDashboardScreen({
    super.key,
    required this.onNavTap,
    required this.onSelectGameTapped,
    required this.onNotificationsTapped,
    required this.onMiniGamesTapped,
    required this.onDailyBonusTapped,
    required this.onMissionsTapped,
    required this.onLeaderboardTapped,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                            Text('Hi, Player123', style: AppText.body(size: 15, weight: FontWeight.w700)),
                            Text('Level 12', style: AppText.caption(size: 12)),
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

                  GlassCard(
                    onTap: widget.onNotificationsTapped,
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
                                  Text('260', style: AppText.heading(size: 26)),
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
                      Expanded(child: _StatTile(label: 'Ads Watched Today', value: '42')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatTile(label: 'Total Ads', value: '812')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Progress", style: AppText.body(size: 14, weight: FontWeight.w600)),
                      Text('42/60 Ads', style: AppText.caption(color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const GlowingProgressBar(value: 42 / 60),
                  const SizedBox(height: 6),
                  Text('18 Ads more to next reward (26 💎)', style: AppText.caption(size: 12)),
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
                        onTap: widget.onSelectGameTapped,
                        child: Text('View All', style: AppText.caption(color: AppColors.primaryPurple)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...kGames.take(3).map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          onTap: widget.onSelectGameTapped,
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
