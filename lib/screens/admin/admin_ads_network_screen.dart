import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/ads_network_config_service.dart';

class AdminAdsNetworkScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminAdsNetworkScreen({super.key, required this.onBack});

  @override
  State<AdminAdsNetworkScreen> createState() => _AdminAdsNetworkScreenState();
}

class _AdminAdsNetworkScreenState extends State<AdminAdsNetworkScreen> {
  final _admobAppIdCtrl = TextEditingController();
  final _admobAdUnitCtrl = TextEditingController();
  bool _admobEnabled = true;

  final _applovinKeyCtrl = TextEditingController();
  final _applovinAdUnitCtrl = TextEditingController();
  bool _applovinEnabled = false;

  bool _loading = true;
  bool _savingAdmob = false;
  bool _savingApplovin = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _admobAppIdCtrl.dispose();
    _admobAdUnitCtrl.dispose();
    _applovinKeyCtrl.dispose();
    _applovinAdUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final configs = await AdsNetworkConfigService.instance.loadConfigs();
    final admob = configs['admob'];
    final applovin = configs['applovin'];
    if (admob != null) {
      _admobAppIdCtrl.text = admob.appId;
      _admobAdUnitCtrl.text = admob.adUnitId;
      _admobEnabled = admob.isEnabled;
    }
    if (applovin != null) {
      _applovinKeyCtrl.text = applovin.appId;
      _applovinAdUnitCtrl.text = applovin.adUnitId;
      _applovinEnabled = applovin.isEnabled;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveAdmob() async {
    setState(() {
      _savingAdmob = true;
      _message = null;
    });
    try {
      await AdsNetworkConfigService.instance.saveConfig(
        networkName: 'admob',
        appId: _admobAppIdCtrl.text.trim(),
        adUnitId: _admobAdUnitCtrl.text.trim(),
        isEnabled: _admobEnabled,
      );
      if (!mounted) return;
      setState(() => _message = 'AdMob settings saved.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Failed to save AdMob settings.');
    } finally {
      if (mounted) setState(() => _savingAdmob = false);
    }
  }

  Future<void> _saveApplovin() async {
    setState(() {
      _savingApplovin = true;
      _message = null;
    });
    try {
      await AdsNetworkConfigService.instance.saveConfig(
        networkName: 'applovin',
        appId: _applovinKeyCtrl.text.trim(),
        adUnitId: _applovinAdUnitCtrl.text.trim(),
        isEnabled: _applovinEnabled,
      );
      if (!mounted) return;
      setState(() => _message = 'AppLovin settings saved.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Failed to save AppLovin settings.');
    } finally {
      if (mounted) setState(() => _savingApplovin = false);
    }
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
                  Text('Ad Networks', style: AppText.heading(size: 18)),
                ],
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_message!, style: AppText.caption(size: 12, color: AppColors.successGreen)),
                      ),
                    Text(
                      'AdMob is always tried first. If it has no ad available, AppLovin is tried next automatically — no other setup needed beyond entering the IDs below.',
                      style: AppText.caption(size: 12),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('AdMob', style: AppText.body(size: 16, weight: FontWeight.w700)),
                              const Spacer(),
                              Switch(
                                value: _admobEnabled,
                                onChanged: (v) => setState(() => _admobEnabled = v),
                                activeColor: AppColors.primaryPurple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _labeledField('Enter Your AdMob App Id', _admobAppIdCtrl),
                          const SizedBox(height: 10),
                          _labeledField('Enter Your AdMob Rewarded Ad Id', _admobAdUnitCtrl),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _savingAdmob ? null : _saveAdmob,
                              child: _savingAdmob
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save AdMob Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('AppLovin', style: AppText.body(size: 16, weight: FontWeight.w700)),
                              const Spacer(),
                              Switch(
                                value: _applovinEnabled,
                                onChanged: (v) => setState(() => _applovinEnabled = v),
                                activeColor: AppColors.primaryPurple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _labeledField('Enter Your AppLovin SDK Key', _applovinKeyCtrl),
                          const SizedBox(height: 10),
                          _labeledField('Enter Your AppLovin Rewarded Ad Id', _applovinAdUnitCtrl),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _savingApplovin ? null : _saveApplovin,
                              child: _savingApplovin
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save AppLovin Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Changes take effect the next time the app is opened (ad settings are loaded once at startup).',
                      style: AppText.caption(size: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption(size: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: AppText.body(size: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
