import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 12 â€” Withdraw (reached from Wallet)
///
/// FIX: previously let the user withdraw any amount up to their raw
/// balance with no cycle awareness, and used the wrong id-vs-name key.
/// Now uses the exact same eligibility system as Game Details'
/// "Request Payout" â€” same locked message if no cycle is complete
/// yet, same suggested/max amount, same full cycle reset on submit â€”
/// so Wallet and Game Details behave identically, matching the
/// reference app where both entry points share one flow.
class WithdrawScreen extends StatefulWidget {
  final GameInfo game;
  final VoidCallback onSubmitted;

  const WithdrawScreen({
    super.key,
    required this.game,
    required this.onSubmitted,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _usernameController = TextEditingController();
  final _uidController = TextEditingController();
  final _noteController = TextEditingController();

  Map<String, dynamic>? _eligibility;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  bool get _eligible => _eligibility?['eligible'] == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final eligibility = await GameDataService.instance.getWithdrawEligibility(widget.game.id);
      if (!mounted) return;
      final maxEligible = (eligibility['balance'] as double?) ?? 0;
      _amountController.text = maxEligible > 0 ? maxEligible.toStringAsFixed(2) : '';
      setState(() {
        _eligibility = eligibility;
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

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await GameDataService.instance.submitCycleWithdraw(
        gameId: widget.game.id,
        amount: amount,
        gameUsername: _usernameController.text,
        gameUid: _uidController.text,
        note: _noteController.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _usernameController.dispose();
    _uidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_eligibility?['balance'] as double?) ?? 0;
    final totalAds = (_eligibility?['total_ads_watched'] as int?) ?? 0;
    final cyclesDone = (_eligibility?['cycles_done'] as int?) ?? 0;
    final totalCycles = (_eligibility?['total_cycles'] as int?) ?? 0;
    final adsPerCycle = (_eligibility?['ads_per_cycle'] as int?) ?? 0;
    final hasConfig = _eligibility?['has_config'] == true;

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
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
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
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(
                'Balance: ${balance.toStringAsFixed(2)} ${widget.game.currency} Â· Ads: $totalAds',
                style: AppText.body(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),

              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Withdrawal requested! Your cycle has restarted from #1 â€” watch ads again to earn more.',
                    style: AppText.body(size: 13, color: AppColors.successGreen),
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(label: 'DONE', onPressed: widget.onSubmitted),
              ] else if (!_eligible) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withOpacity(0.08),
                    border: Border.all(color: AppColors.dangerRed.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hasConfig
                        ? 'ðŸ”’ Watch ${adsPerCycle - totalAds} more ads to complete your first cycle and become eligible to withdraw.'
                        : 'ðŸ”’ No withdraw rate configured for this game yet.',
                    style: AppText.body(size: 13, color: AppColors.dangerRed),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.08),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Eligible to withdraw Â· Completed $cyclesDone of $totalCycles cycles',
                    style: AppText.caption(size: 12, color: AppColors.successGreen),
                  ),
                ),
                const SizedBox(height: 14),
                CyberTextField(hint: 'Amount to withdraw', icon: Icons.diamond_outlined, controller: _amountController),
                const SizedBox(height: 12),
                CyberTextField(hint: 'Enter ${widget.game.name} username', icon: Icons.person_outline_rounded, controller: _usernameController),
                const SizedBox(height: 12),
                CyberTextField(hint: 'Enter ${widget.game.name} UID', icon: Icons.badge_outlined, controller: _uidController),
                const SizedBox(height: 12),
                CyberTextField(hint: 'Note (optional)', icon: Icons.edit_note_rounded, controller: _noteController),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                ],
                const SizedBox(height: 10),
                Text(
                  'Admin will manually process and send currency to your game account. After withdrawal your ad cycle resets to #1.',
                  style: AppText.caption(size: 11),
                ),
                const SizedBox(height: 20),
                GradientButton(label: 'SUBMIT REQUEST', loading: _submitting, onPressed: _submit),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
