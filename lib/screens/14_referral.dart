import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/bottom_nav_bar.dart';

/// Screen 14 — Referral
class ReferralScreen extends StatelessWidget {
  final void Function(int navIndex) onNavTap;
  final String referralCode;

  const ReferralScreen({
    super.key,
    required this.onNavTap,
    this.referralCode = 'GAMEVAULT123',
  });

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
                  Text('Refer & Earn', style: AppText.heading(size: 22)),
                  const SizedBox(height: 6),
                  Text('Invite friends and earn bonus!', style: AppText.caption()),
                  const SizedBox(height: 22),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Referral Code', style: AppText.caption()),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                referralCode,
                                style: AppText.heading(size: 20, color: AppColors.primaryPurple),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied!', style: AppText.body(color: Colors.white))),
                                );
                              },
                              child: const Icon(Icons.copy_rounded, color: AppColors.muted, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(label: 'SHARE NOW', icon: Icons.share_rounded, onPressed: () {}),
                  const SizedBox(height: 24),
                  Text('Referral Stats', style: AppText.body(size: 15, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Total Referrals', value: '12')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Total Earned', value: '240 💎')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Commission Rate', style: AppText.body(size: 14)),
                        Text('10% of friend earnings', style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BottomNavBar(currentIndex: 3, onTap: onNavTap),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.heading(size: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption(size: 12)),
        ],
      ),
    );
  }
}
