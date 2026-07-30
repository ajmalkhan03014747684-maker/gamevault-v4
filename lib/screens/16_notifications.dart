import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class NotificationInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String time;
  const NotificationInfo(this.icon, this.color, this.title, this.description, this.time);
}

const kNotifications = [
  NotificationInfo(Icons.star_rounded, AppColors.gold, 'Your withdraw request has been approved.', '', '2m ago'),
  NotificationInfo(Icons.card_giftcard_rounded, AppColors.primaryPurple, 'Daily bonus is ready to claim!', '', '1h ago'),
  NotificationInfo(Icons.emoji_events_rounded, AppColors.secondaryOrange, 'Mission completed!', 'You earned 10 Diamonds', '2h ago'),
  NotificationInfo(Icons.favorite_rounded, AppColors.dangerRed, 'New event is live!', 'Join now and win rewards.', '5h ago'),
];

/// Screen 16 — Notifications
class NotificationsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const NotificationsScreen({super.key, required this.onBack});

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
                  GestureDetector(onTap: onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                  const SizedBox(width: 14),
                  Text('Notifications', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kNotifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final n = kNotifications[i];
                  return GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: n.color.withOpacity(0.18),
                          ),
                          child: Icon(n.icon, color: n.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: AppText.body(size: 14, weight: FontWeight.w700)),
                              if (n.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(n.description, style: AppText.caption(size: 12)),
                              ],
                            ],
                          ),
                        ),
                        Text(n.time, style: AppText.caption(size: 11)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GradientButton(label: 'VIEW ALL', onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
