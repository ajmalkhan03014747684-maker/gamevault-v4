import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/connection_status_dot.dart';
import '../services/auth_service.dart';
import '../services/game_data_service.dart';

/// Screen 10 â€” Profile
/// Real username, real stats, real admin role check.
///
/// FIX: "Total Earned" removed â€” it summed balances across every
/// game's currency into one number, which was never meaningful once
/// games have different currencies (see Wallet for the real
/// per-currency breakdown).
class ProfileScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;
  final VoidCallback onAdminTapped;
  final VoidCallback onEditProfileTapped;
  final VoidCallback onSecurityTapped;
  final VoidCallback onNotificationsTapped;
  final VoidCallback onLanguageTapped;

  const ProfileScreen({
    super.key,
    required this.onNavTap,
    required this.onAdminTapped,
    required this.onEditProfileTapped,
    required this.onSecurityTapped,
    required this.onNotificationsTapped,
    required this.onLanguageTapped,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdmin = false;
  bool _loading = true;
  String _username = 'Player';
  int _totalAds = 0;
  String _memberSince = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final role = await AuthService.instance.getCurrentUserRole();
      final profile = await AuthService.instance.getProfile();
      final totalAds = await GameDataService.instance.getTotalAdsWatched();

      String memberSince = '';
      final createdAtStr = AuthService.instance.currentUser?.createdAt;
      if (createdAtStr != null) {
        final date = DateTime.tryParse(createdAtStr);
        if (date != null) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          memberSince = '${months[date.month - 1]} ${date.year}';
        }
      }

      if (!mounted) return;
      setState(() {
        _isAdmin = role == 'admin';
        _username = (profile['username'] as String?) ?? 'Player';
        _totalAds = totalAds;
        _memberSince = memberSince;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
                          _loading
                              ? const SizedBox(width: 100, height: 20, child: LinearProgressIndicator())
                              : Text(_username, style: AppText.heading(size: 20)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _StatCol(label: 'Total Ads', value: '$_totalAds')),
                        Expanded(child: _StatCol(label: 'Member Since', value: _memberSince.isNotEmpty ? _memberSince : 'â€”')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _MenuRow(icon: Icons.edit_rounded, label: 'Edit Profile', onTap: widget.onEditProfileTapped),
                    _MenuRow(icon: Icons.security_rounded, label: 'Security', onTap: widget.onSecurityTapped),
                    _MenuRow(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: widget.onNotificationsTapped),
                    _MenuRow(icon: Icons.language_rounded, label: 'Language', onTap: widget.onLanguageTapped),
                    if (_isAdmin) ...[
                      const SizedBox(height: 8),
                      _MenuRow(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Panel',
                        onTap: widget.onAdminTapped,
                        highlight: true,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(child: const ConnectionStatusDot()),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentIndex: 4, onTap: widget.onNavTap),
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
  final bool highlight;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: onTap,
        borderColor: highlight ? AppColors.primaryPurple : null,
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
