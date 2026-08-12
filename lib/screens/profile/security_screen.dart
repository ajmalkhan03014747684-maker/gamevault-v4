import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cyber_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../services/auth_service.dart';

class SecurityScreen extends StatefulWidget {
  final VoidCallback onBack;
  const SecurityScreen({super.key, required this.onBack});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _changePassword() async {
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AuthService.instance.updatePassword(newPass);
      if (!mounted) return;
      setState(() => _saving = false);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated!', style: AppText.body(color: Colors.white))),
      );
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
            Row(
              children: [
                GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                const SizedBox(width: 14),
                Text('Security', style: AppText.heading(size: 20)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Change Password', style: AppText.body(size: 15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Choose a new password for your account', style: AppText.caption()),
            const SizedBox(height: 18),
            CyberTextField(hint: 'New password', icon: Icons.lock_outline_rounded, obscureText: true, controller: _newPasswordController),
            const SizedBox(height: 14),
            CyberTextField(hint: 'Confirm new password', icon: Icons.lock_outline_rounded, obscureText: true, controller: _confirmPasswordController),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
            ],
            const SizedBox(height: 20),
            GradientButton(label: 'UPDATE PASSWORD', loading: _saving, onPressed: _changePassword),
          ],
        ),
      ),
    );
  }
}
