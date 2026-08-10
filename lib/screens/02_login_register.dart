import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../services/auth_service.dart';

/// Screen 2 — Login / Register
/// Now wired to real Supabase Auth via AuthService instead of a
/// simulated delay. Register mode also creates a matching
/// user_profiles row.
class LoginRegisterScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginRegisterScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool _isLoginTab = true;
  bool _loading = false;
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  Future<void> _handleSubmit() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = _isLoginTab
        ? await AuthService.instance.signIn(email: email, password: password)
        : await AuthService.instance.signUp(
            email: email,
            password: password,
            username: _usernameController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      widget.onLoginSuccess();
    } else {
      setState(() => _errorMessage = result.errorMessage ?? 'Something went wrong.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
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
                Text(_isLoginTab ? 'Welcome Back!' : 'Create Account',
                    textAlign: TextAlign.center,
                    style: AppText.heading(size: 24)),
                const SizedBox(height: 6),
                Text(_isLoginTab ? 'Login to continue' : 'Join GameVault today',
                    textAlign: TextAlign.center,
                    style: AppText.caption(size: 14)),
                const SizedBox(height: 28),

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

                if (!_isLoginTab) ...[
                  CyberTextField(
                    hint: 'Username',
                    icon: Icons.badge_outlined,
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 14),
                ],

                CyberTextField(
                  hint: 'Email',
                  icon: Icons.person_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                CyberTextField(
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  controller: _passwordController,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!,
                      style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                ],

                const SizedBox(height: 10),
                if (_isLoginTab)
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
                  label: _isLoginTab ? 'LOGIN' : 'CREATE ACCOUNT',
                  loading: _loading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 20),

                OutlineButton(
                  label: 'Continue as Guest',
                  onPressed: () async {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    final result = await AuthService.instance.signInAsGuest();
                    if (!mounted) return;
                    setState(() => _loading = false);
                    if (result.success) {
                      widget.onLoginSuccess();
                    } else {
                      setState(() => _errorMessage = result.errorMessage ?? 'Could not start guest session.');
                    }
                  },
                ),
                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLoginTab = !_isLoginTab),
                    child: RichText(
                      text: TextSpan(
                        style: AppText.caption(size: 13),
                        children: [
                          TextSpan(text: _isLoginTab ? 'New here? ' : 'Already have an account? '),
                          TextSpan(
                            text: _isLoginTab ? 'Create Account' : 'Login',
                            style: AppText.caption(
                                size: 13, color: AppColors.primaryPurple),
                          ),
                        ],
                      ),
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
      onTap: () => setState(() {
        _isLoginTab = isLogin;
        _errorMessage = null;
      }),
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


