import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onPayoutsTapped;
  final VoidCallback onGamesTapped;
  final VoidCallback onCheckinScheduleTapped;
  final VoidCallback onMissionsTapped;
  final VoidCallback onAntiBotTapped;
  final VoidCallback onUsersTapped;
  final VoidCallback onSettingsTapped;
  final VoidCallback onDangerZoneTapped;
  final VoidCallback onThresholdsTapped;
  final VoidCallback onReferralConfigsTapped;
  final VoidCallback onWithdrawReqTapped;

  const AdminDashboardScreen({
    super.key,
    required this.onExit,
    required this.onPayoutsTapped,
    required this.onGamesTapped,
    required this.onCheckinScheduleTapped,
    required this.onMissionsTapped,
    required this.onAntiBotTapped,
    required this.onUsersTapped,
    required this.onSettingsTapped,
    required this.onDangerZoneTapped,
    required this.onThresholdsTapped,
    required this.onReferralConfigsTapped,
    required this.onWithdrawReqTapped,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats? _stats;
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
      final stats = await AdminService.instance.getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  GestureDetector(onTap: widget.onExit, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                  const SizedBox(width: 14),
                  Text('Admin Panel', style: AppText.heading(size: 20)),
                ],
              ),
              const SizedBox(height: 20),

              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                )
              else if (_stats != null) ...[
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Total Users', value: '${_stats!.totalUsers}', icon: Icons.group_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Ads Watched', value: '${_stats!.totalAdsWatched}', icon: Icons.play_circle_outline_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Pending Payouts', value: '${_stats!.pendingPayouts}', icon: Icons.pending_actions_rounded, highlight: _stats!.pendingPayouts > 0)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Total Paid Out', value: _stats!.totalPaidOut.toStringAsFixed(2), icon: Icons.paid_rounded)),
                  ],
                ),
              ],

              const SizedBox(height: 28),
              Text('Manage', style: AppText.body(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              _AdminMenuRow(
                icon: Icons.request_page_rounded,
                label: 'Payout Requests',
                badge: _stats != null && _stats!.pendingPayouts > 0 ? '${_stats!.pendingPayouts}' : null,
                onTap: widget.onPayoutsTapped,
              ),
              _AdminMenuRow(icon: Icons.sports_esports_rounded, label: 'Manage Games', onTap: widget.onGamesTapped),
              _AdminMenuRow(icon: Icons.trending_up_rounded, label: 'Ad Thresholds', onTap: widget.onThresholdsTapped),
              _AdminMenuRow(icon: Icons.card_giftcard_rounded, label: 'Daily Check-in Schedule', onTap: widget.onCheckinScheduleTapped),
              _AdminMenuRow(icon: Icons.flag_rounded, label: 'Missions', onTap: widget.onMissionsTapped),
              _AdminMenuRow(icon: Icons.group_add_rounded, label: 'Referral Configs', onTap: widget.onReferralConfigsTapped),
              _AdminMenuRow(icon: Icons.account_balance_wallet_rounded, label: 'Withdraw Requirements', onTap: widget.onWithdrawReqTapped),
              _AdminMenuRow(icon: Icons.shield_rounded, label: 'Anti-Bot / Flagged Users', onTap: widget.onAntiBotTapped),
              _AdminMenuRow(icon: Icons.person_off_rounded, label: 'Manage Users / Ban', onTap: widget.onUsersTapped),
              _AdminMenuRow(icon: Icons.settings_rounded, label: 'App Settings', onTap: widget.onSettingsTapped),
              const SizedBox(height: 8),
              _AdminMenuRow(
                icon: Icons.delete_forever_rounded,
                label: 'Danger Zone',
                onTap: widget.onDangerZoneTapped,
                isDanger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _StatCard({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: highlight ? AppColors.secondaryOrange : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: highlight ? AppColors.secondaryOrange : AppColors.primaryPurple, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppText.heading(size: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(size: 11)),
        ],
      ),
    );
  }
}

class _AdminMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool comingSoon;
  final bool isDanger;

  const _AdminMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.comingSoon = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDanger
        ? AppColors.dangerRed
        : (comingSoon ? AppColors.muted : AppColors.primaryPurple);
    final textColor = isDanger
        ? AppColors.dangerRed
        : (comingSoon ? AppColors.muted : AppColors.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: comingSoon ? null : onTap,
        borderColor: isDanger ? AppColors.dangerRed.withOpacity(0.4) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body(size: 14, weight: FontWeight.w600, color: textColor))),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.secondaryOrange, borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: Text(badge!, style: AppText.caption(size: 11, color: Colors.white)),
              ),
              const SizedBox(width: 8),
            ],
            if (comingSoon)
              Text('Soon', style: AppText.caption(size: 11))
            else
              Icon(Icons.chevron_right_rounded, color: isDanger ? AppColors.dangerRed : AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
