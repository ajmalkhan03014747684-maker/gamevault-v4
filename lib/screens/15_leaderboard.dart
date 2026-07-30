import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final bool isCurrentUser;
  const LeaderboardEntry(this.rank, this.username, this.score, {this.isCurrentUser = false});
}

const kLeaderboard = [
  LeaderboardEntry(1, 'ProGamer', 2450),
  LeaderboardEntry(2, 'LegendYT', 1890),
  LeaderboardEntry(3, 'HunterX', 1230),
  LeaderboardEntry(4, 'Player123', 980, isCurrentUser: true),
  LeaderboardEntry(5, 'ShadowBoy', 760),
];

/// Screen 15 — Leaderboard
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _tab = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                  const SizedBox(width: 14),
                  Text('Leaderboard', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.button)),
                child: Row(
                  children: ['Weekly', 'Monthly', 'All Time'].map((t) {
                    final active = t == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primaryPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.button - 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(t,
                              style: AppText.body(
                                  size: 12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kLeaderboard.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final e = kLeaderboard[i];
                  return GlassCard(
                    borderColor: e.isCurrentUser ? AppColors.primaryPurple : null,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '#${e.rank}',
                            style: AppText.body(
                              size: 14,
                              weight: FontWeight.w800,
                              color: e.rank == 1
                                  ? AppColors.gold
                                  : e.rank == 2
                                      ? const Color(0xFFC0C0C0)
                                      : e.rank == 3
                                          ? const Color(0xFFCD7F32)
                                          : AppColors.muted,
                            ),
                          ),
                        ),
                        CircleAvatar(radius: 16, backgroundColor: AppColors.surface2, child: const Icon(Icons.person, size: 18, color: AppColors.muted)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.username, style: AppText.body(size: 14, weight: FontWeight.w600))),
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text('${e.score}', style: AppText.body(size: 14, weight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Your Rank: #4 (Top 5%)', style: AppText.caption(size: 13)),
                  const SizedBox(height: 12),
                  GradientButton(label: 'VIEW ALL', onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
