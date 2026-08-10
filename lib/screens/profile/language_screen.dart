import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/auth_service.dart';

/// Note: this stores the preference for real (Supabase), but the app
/// itself is currently English-only — no actual translated strings
/// exist yet. This screen honestly reflects that: it saves the
/// choice, doesn't pretend to change the UI language.
class LanguageScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LanguageScreen({super.key, required this.onBack});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

const _kLanguages = [
  ('en', 'English'),
  ('hi', 'हिन्दी (Hindi)'),
  ('ur', 'اردو (Urdu)'),
  ('ar', 'العربية (Arabic)'),
];

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'en';
  bool _loading = true;
  bool _saving = false;
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
        _selected = (profile['language'] as String?) ?? 'en';
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

  Future<void> _select(String code) async {
    setState(() {
      _selected = code;
      _saving = true;
    });
    try {
      await AuthService.instance.updateLanguage(code);
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
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
                      Text('Language', style: AppText.heading(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your preference is saved. Full translations are coming in a future update — the app is English-only for now.',
                    style: AppText.caption(size: 12),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                    ),
                  ..._kLanguages.map((lang) {
                    final active = _selected == lang.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: _saving ? null : () => _select(lang.$1),
                        borderColor: active ? AppColors.primaryPurple : null,
                        child: Row(
                          children: [
                            Expanded(child: Text(lang.$2, style: AppText.body(size: 14, weight: FontWeight.w600))),
                            if (active) const Icon(Icons.check_circle_rounded, color: AppColors.primaryPurple, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
