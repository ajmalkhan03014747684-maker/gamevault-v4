import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '03_home_dashboard.dart';

/// Screen 4 — Select Game
class SelectGameScreen extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(GameInfo game) onGameSelected;
  final String activeGameName;

  const SelectGameScreen({
    super.key,
    required this.onBack,
    required this.onGameSelected,
    this.activeGameName = 'Free Fire',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Select Game', style: AppText.heading(size: 24)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose a game to earn rewards', style: AppText.caption()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kGames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final g = kGames[i];
                  final isActive = g.name == activeGameName;
                  return GlassCard(
                    onTap: () => onGameSelected(g),
                    padding: const EdgeInsets.all(14),
                    borderColor: isActive ? AppColors.primaryPurple : null,
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(g.icon, color: AppColors.primaryPurple),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(g.name, style: AppText.body(size: 15, weight: FontWeight.w700)),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPurple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(AppRadius.chip),
                                      ),
                                      child: Text('Active',
                                          style: AppText.caption(size: 10, color: AppColors.primaryPurple)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(g.currency, style: AppText.caption(size: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
