import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '03_home_dashboard.dart';

/// Screen 12 — Withdraw
class WithdrawScreen extends StatefulWidget {
  final GameInfo game;
  final int balance;
  final VoidCallback onSubmitted;

  const WithdrawScreen({
    super.key,
    required this.game,
    required this.balance,
    required this.onSubmitted,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _uidController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_uidController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    // TODO: wire to real payout_requests insert once Supabase is connected.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _submitting = false);
    widget.onSubmitted();
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Withdraw Currency', style: AppText.heading(size: 22)),
            const SizedBox(height: 20),
            Text('Selected Game', style: AppText.caption()),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.game.icon, color: AppColors.primaryPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.game.name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                        Text(widget.game.currency, style: AppText.caption(size: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Your Balance: ${widget.balance} ${widget.game.currency}', style: AppText.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text('Withdraw Amount', style: AppText.caption()),
            const SizedBox(height: 6),
            Text('${widget.balance} 💎 = 1 Withdraw', style: AppText.body(size: 14)),
            const SizedBox(height: 18),
            CyberTextField(
              hint: 'Enter ${widget.game.name} UID',
              icon: Icons.badge_outlined,
              controller: _uidController,
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: 'SUBMIT REQUEST',
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Note: Withdraw requests are reviewed by admin.',
                style: AppText.caption(size: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
