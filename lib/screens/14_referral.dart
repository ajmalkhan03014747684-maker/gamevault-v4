import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/game_data_service.dart';

/// Screen 14 â€” Referral
/// Real referral code (generated once per user, stored in Supabase),
/// real stats, and a real native share sheet.
class ReferralScreen extends StatefulWidget {
  final void Function(int navIndex) onNavTap;

  const ReferralScreen({super.key, required this.onNavTap});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String _code = '';
  int _totalReferrals = 0;
  double _totalEarned = 0;
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
      final code = await GameDataService.instance.getMyReferralCode();
      final stats = await GameDataService.instance.getReferralStats();
      if (!mounted) return;
      setState(() {
        _code = code;
        _totalReferrals = (stats['total_referrals'] as int?) ?? 0;
        _totalEarned = (stats['total_earned'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } on GameDataException catch (e) {
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
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Refer & Earn', style: AppText.heading(size: 22)),
                    const SizedBox(height: 6),
                    Text('Invite friends and earn bonus!', style: AppText.caption()),
                    const SizedBox(height: 22),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                      ),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Referral Code', style: AppText.caption()),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _loading
                                    ? const LinearProgressIndicator()
                                    : Text(
                                        _code.isNotEmpty ? _code : 'â€”',
                                        style: AppText.heading(size: 20, color: AppColors.primaryPurple),
                                      ),
                              ),
                              if (!_loading && _code.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _code));
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
                    GradientButton(
                      label: 'SHARE NOW',
                      icon: Icons.share_rounded,
                      onPressed: _code.isEmpty
                          ? null
                          : () {
                              Share.share(
                                'Join GameVault and earn real game currency! Use my code $_code when you sign up.',
                              );
                            },
                    ),
                    const SizedBox(height: 24),
                    Text('Referral Stats', style: AppText.body(size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Total Referrals', value: '$_totalReferrals')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Total Earned', value: '${_totalEarned.toStringAsFixed(2)} ðŸ’Ž')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentIndex: 3, onTap: widget.onNavTap),
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
