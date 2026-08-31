import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/cooldown_badge.dart';

class MiniGameInfo {
  final String name;
  final IconData icon;
  final Color color;
  const MiniGameInfo(this.name, this.icon, this.color);
}

const kMiniGames = [
  MiniGameInfo('Fast Runner', Icons.directions_run_rounded, AppColors.primaryPurple),
  MiniGameInfo('Hue Shift', Icons.palette_rounded, AppColors.successGreen),
  MiniGameInfo('Memory Match', Icons.grid_view_rounded, AppColors.secondaryOrange),
  MiniGameInfo('Bubble Pop', Icons.bubble_chart_rounded, AppColors.gold),
  MiniGameInfo('Target Toss', Icons.gps_fixed_rounded, AppColors.dangerRed),
  MiniGameInfo('Space Dodge', Icons.rocket_launch_rounded, AppColors.primaryPurple),
];

/// Screen 9 â€” Mini Games Hub
/// IMPORTANT: none of these games grant currency, ad progress, or
/// withdrawal eligibility. Entertainment only, fully isolated from the
/// reward economy â€” do not wire any of these into balance/progress state.
class MiniGamesHubScreen extends StatelessWidget {
  final VoidCallback onBack;

  const MiniGamesHubScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mini Games', style: AppText.heading(size: 20)),
                        Text('(Entertainment Only)', style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                  const CooldownBadge(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Play & Enjoy (No Rewards)', style: AppText.caption(size: 13)),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kMiniGames.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, i) {
                  final g = kMiniGames[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      if (i == 0) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FastRunnerGame()),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            title: Text('Coming Soon', style: AppText.body(size: 16, weight: FontWeight.w700)),
                            content: Text('${g.name} isn\'t ready yet â€” check back soon!',
                                style: AppText.caption()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK', style: AppText.body(color: AppColors.primaryPurple)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(g.icon, size: 40, color: g.color),
                        const SizedBox(height: 12),
                        Text(g.name, style: AppText.body(size: 13, weight: FontWeight.w600), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple playable reaction-tap runner. No currency/reward wiring â€”
/// entertainment only, per the Mini Games isolation requirement.
class FastRunnerGame extends StatefulWidget {
  const FastRunnerGame({super.key});

  @override
  State<FastRunnerGame> createState() => _FastRunnerGameState();
}

class _FastRunnerGameState extends State<FastRunnerGame> {
  int _score = 0;
  double _targetX = 0.5;
  final _rand = Random();

  void _tapTarget() {
    setState(() {
      _score += 1;
      _targetX = _rand.nextDouble() * 0.8 + 0.1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Fast Runner', style: AppText.body(size: 16, weight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text('Score: $_score', style: AppText.heading(size: 22)),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            alignment: Alignment(_targetX * 2 - 1, 0),
            child: GestureDetector(
              onTap: _tapTarget,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primaryButton,
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryPurple.withOpacity(0.5), blurRadius: 20),
                  ],
                ),
                child: const Icon(Icons.directions_run_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Text(
              'Tap the runner as fast as you can! (Entertainment only â€” no rewards)',
              textAlign: TextAlign.center,
              style: AppText.caption(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
