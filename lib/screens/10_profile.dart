import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/connection_status_dot.dart';

/// Screen 10 — Profile
class ProfileScreen extends StatelessWidget {
  final void Function(int navIndex) onNavTap;

  const ProfileScreen({super.key, required this.onNavTap});

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
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryButton,
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryPurple.withOpacity(0.4), blurRadius: 20),
                            ],
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 42),
                        ),
                        const SizedBox(height: 14),
                        Text('Player123', style: AppText.heading(size: 20)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text('Level 12', style: AppText.caption(size: 12, color: AppColors.primaryPurple)),
                        ),
                        const SizedBox(height: 6),
                        Text('UID: 1234567890', style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatCol(label: 'Total Ads', value: '812')),
                      Expanded(child: _StatCol(label: 'Total Earned', value: '520 💎')),
                      Expanded(child: _StatCol(label: 'Member Since', value: 'May 2024')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _MenuRow(icon: Icons.edit_rounded, label: 'Edit Profile', onTap: () {}),
                  _MenuRow(icon: Icons.security_rounded, label: 'Security', onTap: () {}),
                  _MenuRow(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {}),
                  _MenuRow(icon: Icons.language_rounded, label: 'Language', trailing: 'English', onTap: () {}),
                  const SizedBox(height: 20),
                  Center(child: const ConnectionStatusDot()),
                ],
              ),
            ),
            BottomNavBar(currentIndex: 4, onTap: onNavTap),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  const _StatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.body(size: 14, weight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: AppText.caption(size: 11), textAlign: TextAlign.center),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuRow({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body(size: 14, weight: FontWeight.w600))),
            if (trailing != null) ...[
              Text(trailing!, style: AppText.caption(size: 13)),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
