import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/admin_service.dart';
import '../../services/ads_config.dart';

class AdminSettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminSettingsScreen({super.key, required this.onBack});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _limitController = TextEditingController();
  int _currentLimit = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final limit = await AdminService.instance.getDailyAdLimit();
      if (!mounted) return;
      setState(() {
        _currentLimit = limit;
        _limitController.text = limit.toString();
        _loading = false;
      });
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final value = int.tryParse(_limitController.text) ?? 0;
    setState(() => _saving = true);
    try {
      await AdminService.instance.setDailyAdLimit(value);
      if (!mounted) return;
      setState(() {
        _currentLimit = value;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                  const SizedBox(width: 14),
                  Text('App Settings', style: AppText.heading(size: 18)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                          ),

                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DAILY REWARDED ADS LIMIT', style: AppText.caption(size: 11)),
                              const SizedBox(height: 10),
                              Text(
                                'Max rewarded ads a user can watch per day. Resets at midnight. Set 0 for unlimited.',
                                style: AppText.caption(size: 12),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _limitController,
                                      keyboardType: TextInputType.number,
                                      style: AppText.body(size: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Max Ads Per Day',
                                        labelStyle: AppText.caption(),
                                        hintText: 'e.g. 20 (0 = unlimited)',
                                        filled: true,
                                        fillColor: AppColors.surface2,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                                    child: _saving
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('Save'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _currentLimit == 0
                                    ? 'Currently: Unlimited'
                                    : 'Currently: $_currentLimit ads/day',
                                style: AppText.caption(size: 12, color: AppColors.primaryPurple),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('Ad IDs (Reference)', style: AppText.body(size: 14, weight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Configured in code (lib/services/ads_config.dart) — not editable here, since these are compiled into the app itself.',
                          style: AppText.caption(size: 11),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _configRow('Using Real Ads', AdsConfig.useRealAds ? 'Yes' : 'No (simulated)'),
                              _configRow('App ID', AdsConfig.appId),
                              _configRow('Rewarded Ad Unit ID', AdsConfig.rewardedAdUnitId),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: AppText.caption(size: 12))),
          Expanded(child: Text(value, style: AppText.body(size: 12, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}
