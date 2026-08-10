import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const NotificationSettingsScreen({super.key, required this.onBack});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _loading = true;
  String? _error;

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
        _pushEnabled = (profile['push_notifications_enabled'] as bool?) ?? true;
        _emailEnabled = (profile['email_notifications_enabled'] as bool?) ?? true;
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
    try {
      await AuthService.instance.updateNotificationPrefs(pushEnabled: _pushEnabled, emailEnabled: _emailEnabled);
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
                      Text('Notifications', style: AppText.heading(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                    ),
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Push Notifications', style: AppText.body(size: 14, weight: FontWeight.w700)),
                              Text('Reward alerts, daily bonus reminders', style: AppText.caption(size: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pushEnabled,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (v) {
                            setState(() => _pushEnabled = v);
                            _save();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email Notifications', style: AppText.body(size: 14, weight: FontWeight.w700)),
                              Text('Withdrawal status, account updates', style: AppText.caption(size: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _emailEnabled,
                          activeColor: AppColors.primaryPurple,
                          onChanged: (v) {
                            setState(() => _emailEnabled = v);
                            _save();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: this saves your preference. Actual push/email delivery requires additional setup (a push notification service and email provider) not yet wired in.',
                    style: AppText.caption(size: 11),
                  ),
                ],
              ),
      ),
    );
  }
}
