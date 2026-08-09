import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 12 — Withdraw
/// Fetches real balance and submits real requests via GameDataService.
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
  final _uidController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _submitting = false;
  bool _loadingBalance = true;
  double _balance = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final b = await GameDataService.instance.getBalance(widget.game.name);
      if (!mounted) return;
      setState(() {
        _balance = b;
        _loadingBalance = false;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loadingBalance = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_uidController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your game UID and in-game username.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await GameDataService.instance.submitWithdrawRequest(
        gameId: widget.game.name,
        amount: _balance,
        gameUid: _uidController.text.trim(),
        gameUsername: _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onSubmitted();
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    _usernameController.dispose();
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
            _loadingBalance
                ? const SizedBox(height: 20, child: LinearProgressIndicator())
                : Text('Your Balance: ${_balance.toStringAsFixed(2)} ${widget.game.currency}', style: AppText.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 18),
            CyberTextField(
              hint: 'Enter ${widget.game.name} UID',
              icon: Icons.badge_outlined,
              controller: _uidController,
            ),
            const SizedBox(height: 14),
            CyberTextField(
              hint: 'Enter your in-game username',
              icon: Icons.person_outline_rounded,
              controller: _usernameController,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
            ],
            const SizedBox(height: 22),
            GradientButton(
              label: 'SUBMIT REQUEST',
              loading: _submitting,
              onPressed: _balance > 0 ? _submit : null,
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
