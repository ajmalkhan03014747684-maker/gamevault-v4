import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminThresholdsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminThresholdsScreen({super.key, required this.onBack});

  @override
  State<AdminThresholdsScreen> createState() => _AdminThresholdsScreenState();
}

class _AdminThresholdsScreenState extends State<AdminThresholdsScreen> {
  List<Map<String, dynamic>> _thresholds = [];
  List<Map<String, dynamic>> _games = [];
  bool _loading = true;
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
      final thresholds = await AdminService.instance.getThresholds();
      final games = await AdminService.instance.getGames();
      if (!mounted) return;
      setState(() {
        _thresholds = thresholds;
        _games = games;
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

  String _gameName(String? gameId) {
    final g = _games.firstWhere((g) => g['id'].toString() == gameId, orElse: () => {});
    return (g['name'] as String?) ?? 'Unknown Game';
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    if (_games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add a game first!', style: AppText.body(color: Colors.white))),
      );
      return;
    }

    String? selectedGameId = existing?['game_id']?.toString() ?? _games.first['id'].toString();
    final adsController = TextEditingController(text: existing?['ads_required']?.toString() ?? '');
    final rewardController = TextEditingController(text: existing?['currency_reward']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? 'Add Threshold' : 'Edit Threshold', style: AppText.body(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedGameId,
                    dropdownColor: AppColors.surface2,
                    style: AppText.body(size: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _games
                        .map((g) => DropdownMenuItem(value: g['id'].toString(), child: Text(g['name'] as String? ?? '')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedGameId = v),
                  ),
                  const SizedBox(height: 10),
                  _field(adsController, 'Ads required (e.g. 60)'),
                  const SizedBox(height: 10),
                  _field(rewardController, 'Currency reward (e.g. 26)'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppText.body(color: AppColors.muted)))),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true || selectedGameId == null) return;
    final ads = int.tryParse(adsController.text) ?? 0;
    final reward = double.tryParse(rewardController.text) ?? 0;

    try {
      if (existing == null) {
        await AdminService.instance.createThreshold(gameId: selectedGameId!, adsRequired: ads, currencyReward: reward);
      } else {
        await AdminService.instance.updateThreshold(existing['id'] as String, adsRequired: ads, currencyReward: reward);
      }
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppText.body(size: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.caption(),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await AdminService.instance.deleteThreshold(id);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggle(String id, bool current) async {
    try {
      await AdminService.instance.setThresholdActive(id, !current);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
                  Expanded(child: Text('Ad Thresholds', style: AppText.heading(size: 18))),
                  GestureDetector(onTap: () => _openForm(), child: const Icon(Icons.add_circle_rounded, color: AppColors.primaryPurple, size: 26)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _thresholds.isEmpty
                      ? Center(child: Text('No thresholds set yet', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _thresholds.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final t = _thresholds[i];
                              final id = t['id'] as String;
                              final ads = t['ads_required'] ?? 0;
                              final reward = (t['currency_reward'] as num?)?.toDouble() ?? 0;
                              final active = (t['is_active'] as bool?) ?? true;

                              return GlassCard(
                                onTap: () => _openForm(existing: t),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_gameName(t['game_id']?.toString()), style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text('Watch $ads ads → earn ${reward.toStringAsFixed(2)}', style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    Switch(value: active, onChanged: (_) => _toggle(id, active), activeColor: AppColors.primaryPurple),
                                    GestureDetector(onTap: () => _delete(id), child: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed, size: 20)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
