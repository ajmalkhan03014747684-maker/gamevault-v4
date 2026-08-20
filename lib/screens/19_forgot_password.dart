import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../services/auth_service.dart';

/// Forgot Password â€” step 1 of 2. Sends a reset link to the user's
/// email; the link opens this app directly (see main.dart's
/// onAuthStateChange listener) and lands on ResetPasswordScreen.
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordScreen({super.key, required this.onBack});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
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
    _emailController.dispose();
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.primaryButton,
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryPurple.withOpacity(0.5), blurRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Forgot Password?', textAlign: TextAlign.center, style: AppText.heading(size: 24)),
                const SizedBox(height: 6),
                Text(
                  _sent
                      ? 'Check your email for a reset link.'
                      : "Enter your email and we'll send you a reset link.",
                  textAlign: TextAlign.center,
                  style: AppText.caption(size: 14),
                ),
                const SizedBox(height: 28),

                if (_sent) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.1),
                      border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Reset link sent to ${_emailController.text.trim()}. Open it on this device to set a new password.',
                      style: AppText.body(size: 13, color: AppColors.successGreen),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlineButton(label: 'Back to Login', onPressed: widget.onBack),
                ] else ...[
                  CyberTextField(
                    hint: 'Email',
                    icon: Icons.person_outline_rounded,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(label: 'SEND RESET LINK', loading: _loading, onPressed: _submit),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
