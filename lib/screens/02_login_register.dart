import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';

/// Screen 2 — Login / Register
class LoginRegisterScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginRegisterScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool _isLoginTab = true;
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    // TODO: wire real Supabase auth here.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onLoginSuccess();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenGlow),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      gradient: AppGradients.primaryButton,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_esports_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Welcome Back!',
                    textAlign: TextAlign.center,
                    style: AppText.heading(size: 24)),
                const SizedBox(height: 6),
                Text('Login to continue',
                    textAlign: TextAlign.center,
                    style: AppText.caption(size: 14)),
                const SizedBox(height: 28),

                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTab('LOGIN', true)),
                      Expanded(child: _buildTab('REGISTER', false)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CyberTextField(
                  hint: 'Email or Username',
                  icon: Icons.person_outline_rounded,
                  controller: _emailController,
                ),
                const SizedBox(height: 14),
                CyberTextField(
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text('Forgot Password?',
                        style: AppText.caption(
                            size: 13, color: AppColors.primaryPurple)),
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'LOGIN',
                  loading: _loading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.glassBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with',
                          style: AppText.caption(size: 12)),
                    ),
                    Expanded(child: Divider(color: AppColors.glassBorder)),
                  ],
                ),
                const SizedBox(height: 20),

                _SocialButton(
                  label: 'Continue with Google',
                  bg: Colors.white,
                  fg: Colors.black87,
                  icon: Icons.g_mobiledata_rounded,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                OutlineButton(label: 'Continue as Guest', onPressed: () {}),
                const SizedBox(height: 24),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppText.caption(size: 13),
                      children: [
                        const TextSpan(text: 'New here? '),
                        TextSpan(
                          text: 'Create Account',
                          style: AppText.caption(
                              size: 13, color: AppColors.primaryPurple),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isLogin) {
    final active = _isLoginTab == isLogin;
    return GestureDetector(
      onTap: () => setState(() => _isLoginTab = isLogin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w700,
            color: active ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: fg),
        label: Text(label,
            style: AppText.body(size: 15, color: fg, weight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}
