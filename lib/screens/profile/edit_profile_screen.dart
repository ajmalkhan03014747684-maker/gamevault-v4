import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cyber_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  const EditProfileScreen({super.key, required this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AuthService.instance.getProfile();
      if (!mounted) return;
      setState(() {
        _usernameController.text = (profile['username'] as String?) ?? '';
        _email = (profile['email'] as String?) ?? AuthService.instance.currentUser?.email ?? '';
        _loading = false;
      });
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Username can\'t be empty.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.instance.updateUsername(_usernameController.text.trim());
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated!', style: AppText.body(color: Colors.white))),
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
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                      const SizedBox(width: 14),
                      Text('Edit Profile', style: AppText.heading(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primaryButton,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Avatar customization coming soon', style: AppText.caption(size: 11)),
                  ),
                  const SizedBox(height: 28),
                  Text('Username', style: AppText.caption()),
                  const SizedBox(height: 8),
                  CyberTextField(hint: 'Username', icon: Icons.badge_outlined, controller: _usernameController),
                  const SizedBox(height: 18),
                  Text('Email', style: AppText.caption()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(_email, style: AppText.body(size: 14, color: AppColors.muted))),
                        Text('Locked', style: AppText.caption(size: 11)),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(label: 'SAVE CHANGES', loading: _saving, onPressed: _save),
                ],
              ),
      ),
    );
  }
}
