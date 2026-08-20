import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../services/auth_service.dart';

/// Reset Password â€” step 2 of 2. RootFlow routes here automatically
/// the instant the app detects it was opened via a Supabase password
/// recovery deep link (AuthChangeEvent.passwordRecovery). No email or
/// old password needed â€” the recovery link itself is the proof of
/// identity, same as any standard "forgot password" flow.
class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;

  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _submit() async {
    final pw = _passwordController.text;
    final confirm = _confirmController.text;
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pw != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.updatePassword(pw);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _done = true;
      });
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenGlow),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _done ? AppGradients.successGlow : AppGradients.primaryButton,
                      boxShadow: [
                        BoxShadow(
                          color: (_done ? AppColors.successGreen : AppColors.primaryPurple).withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(_done ? Icons.check_rounded : Icons.lock_open_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_done ? 'Password Updated!' : 'Set New Password',
                    textAlign: TextAlign.center, style: AppText.heading(size: 24)),
                const SizedBox(height: 6),
                Text(
                  _done ? 'You can now log in with your new password.' : 'Choose a new password for your account.',
                  textAlign: TextAlign.center,
                  style: AppText.caption(size: 14),
                ),
                const SizedBox(height: 28),

                if (_done) ...[
                  GradientButton(label: 'CONTINUE', onPressed: widget.onDone),
                ] else ...[
                  CyberTextField(
                    hint: 'New Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 14),
                  CyberTextField(
                    hint: 'Confirm New Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    controller: _confirmController,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(label: 'UPDATE PASSWORD', loading: _loading, onPressed: _submit),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
