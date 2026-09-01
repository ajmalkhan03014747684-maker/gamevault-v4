import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminDangerZoneScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminDangerZoneScreen({super.key, required this.onBack});

  @override
  State<AdminDangerZoneScreen> createState() => _AdminDangerZoneScreenState();
}

class _AdminDangerZoneScreenState extends State<AdminDangerZoneScreen> {
  bool _busy = false;

  Future<void> _confirmAndRun(String title, String description, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 32),
              const SizedBox(height: 10),
              Text(title, style: AppText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(description, style: AppText.caption(size: 13)),
              const SizedBox(height: 6),
              Text('This cannot be undone.', style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: AppText.body(color: AppColors.muted)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
                      child: const Text('Yes, do it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Done.')),
      );
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                  Text('Danger Zone', style: AppText.heading(size: 18, color: AppColors.dangerRed)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    borderColor: AppColors.dangerRed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Permanently deletes data — cannot be undone.',
                          style: AppText.caption(size: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ad IDs and Supabase config are never touched.',
                          style: AppText.caption(size: 11),
                        ),
                        const SizedBox(height: 16),
                        _dangerButton(
                          '🗑️ Clear Ad Watches',
                          'Resets everyone\'s ad-watch progress to zero.',
                          () => AdminService.instance.clearAllAdWatches(),
                        ),
                        _dangerButton(
                          '🗑️ Clear User Balances',
                          'Zeros out every user\'s currency balance in every game.',
                          () => AdminService.instance.clearAllBalances(),
                        ),
                        _dangerButton(
                          '🗑️ Clear Payout Requests',
                          'Deletes all withdrawal requests, all statuses.',
                          () => AdminService.instance.clearAllPayouts(),
                        ),
                        _dangerButton(
                          '🗑️ Clear Referrals',
                          'Deletes all referral records.',
                          () => AdminService.instance.clearAllReferrals(),
                        ),
                        
                          
                          
                      
                
                        const SizedBox(height: 8),
                        Container(height: 1, color: AppColors.dangerRed.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () => _confirmAndRun(
                                      'FULL APP RESET',
                                      'Deletes games, ad watches, balances, referrals, and payouts for every user.',
                                      () => AdminService.instance.fullAppReset(),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC0392B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _busy
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('FULL APP RESET — Start From Scratch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keeps: Ad IDs config, Supabase project, admin login',
                          textAlign: TextAlign.center,
                          style: AppText.caption(size: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dangerButton(String title, String description, Future<void> Function() action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _busy ? null : () => _confirmAndRun(title, description, action),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.dangerRed),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppText.caption(size: 13, color: AppColors.dangerRed)),
          ),
        ),
      ),
    );
  }
}
