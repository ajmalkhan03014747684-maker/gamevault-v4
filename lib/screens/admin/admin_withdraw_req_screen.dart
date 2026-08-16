import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';
import '../../services/game_data_service.dart';

/// Real Withdraw Rate Config CRUD, matching the original app exactly:
/// admin sets ONE base rate per game (ads required â†’ currency given,
/// up to a target ceiling), and the app auto-calculates every
/// multiple of it (e.g. 60 ads=13, 120=26, 180=39...).
class AdminWithdrawReqScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminWithdrawReqScreen({super.key, required this.onBack});

  @override
  State<AdminWithdrawReqScreen> createState() => _AdminWithdrawReqScreenState();
}

class _AdminWithdrawReqScreenState extends State<AdminWithdrawReqScreen> {
  List<Map<String, dynamic>> _rates = [];
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
      final rates = await AdminService.instance.getWithdrawRequirements();
      final games = await AdminService.instance.getGames();
      if (!mounted) return;
      setState(() {
        _rates = rates;
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

  Future<void> _openModal({Map<String, dynamic>? existing}) async {
    if (_games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add a game first', style: AppText.body(color: Colors.white))),
      );
      return;
    }
    String? selectedGameId = existing?['game_id'] as String? ?? _games.first['id'] as String;
    final adsController = TextEditingController(text: existing?['ads_required']?.toString() ?? '');
    final givenController = TextEditingController(text: existing?['currency_given']?.toString() ?? '');
    final targetController = TextEditingController(text: existing?['target_currency']?.toString() ?? '');
    bool isActive = (existing?['is_active'] as bool?) ?? true;
    String? errorText;

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
                  Text(existing != null ? 'Edit Withdraw Rate' : 'Add Withdraw Rate', style: AppText.body(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'This is also the ad-watch cycle: every N ads, currency is credited automatically. After a payout, the cycle resets to #1.',
                    style: AppText.caption(size: 11),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedGameId,
                    dropdownColor: AppColors.surface2,
                    style: AppText.body(size: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: _games.map((g) => DropdownMenuItem(value: g['id'] as String, child: Text((g['name'] as String?) ?? ''))).toList(),
                    onChanged: (v) => setDialogState(() => selectedGameId = v),
                  ),
                  const SizedBox(height: 10),
                  _numField(adsController, 'Base Ads Per Cycle (e.g. 1)', onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 10),
                  _numField(givenController, 'Currency Per Cycle (e.g. 13)', onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 10),
                  _numField(targetController, 'Target â€” Max Currency (e.g. 1000)', onChanged: () => setDialogState(() {})),
                  if (adsController.text.isNotEmpty && givenController.text.isNotEmpty && targetController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(10),
                        child: Builder(builder: (context) {
                          final ads = int.tryParse(adsController.text) ?? 0;
                          final given = double.tryParse(givenController.text) ?? 0;
                          final target = double.tryParse(targetController.text) ?? 0;
                          if (ads <= 0 || given <= 0 || target <= 0) return const SizedBox.shrink();
                          final schedule = GameDataService.instance.calcSchedule(ads, given, target);
                          if (schedule.isEmpty) return const SizedBox.shrink();
                          final totalAdsNeeded = schedule.last['ads'];
                          return Text(
                            'Every $ads ad${ads == 1 ? '' : 's'} â†’ earn ${given.toStringAsFixed(2)}. '
                            'Total cycles: ${schedule.length} Â· Total ads needed: $totalAdsNeeded. '
                            'After payout, cycle resets to #1.',
                            style: AppText.caption(size: 11),
                          );
                        }),
                      ),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: AppText.caption(size: 11, color: AppColors.dangerRed)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(value: isActive, onChanged: (v) => setDialogState(() => isActive = v), activeColor: AppColors.primaryPurple),
                      Text('Active', style: AppText.body(size: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppText.body(color: AppColors.muted)))),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final ads = int.tryParse(adsController.text);
                            final given = double.tryParse(givenController.text);
                            final target = double.tryParse(targetController.text);
                            if (ads == null || given == null || target == null) {
                              setDialogState(() => errorText = 'All fields are required.');
                              return;
                            }
                            if (given >= target) {
                              setDialogState(() => errorText = 'Target must be greater than currency per cycle.');
                              return;
                            }
                            Navigator.pop(context, true);
                          },
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

    try {
      await AdminService.instance.saveWithdrawRequirement(
        id: existing?['id'] as String?,
        gameId: selectedGameId!,
        adsRequired: int.parse(adsController.text),
        currencyGiven: double.parse(givenController.text),
        targetCurrency: double.parse(targetController.text),
        isActive: isActive,
      );
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _numField(TextEditingController controller, String hint, {VoidCallback? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppText.body(size: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.caption(size: 12),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await AdminService.instance.deleteWithdrawRequirement(id);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _gameName(String? gameId) {
    final match = _games.where((g) => g['id'] == gameId).toList();
    return match.isNotEmpty ? (match.first['name'] as String? ?? 'â€”') : 'â€”';
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
                  Expanded(child: Text('Withdraw Rate Config', style: AppText.heading(size: 16))),
                  GestureDetector(onTap: () => _openModal(), child: const Icon(Icons.add_circle_rounded, color: AppColors.primaryPurple, size: 26)),
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
                  : _rates.isEmpty
                      ? Center(child: Text('No withdraw rates set yet', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _rates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = _rates[i];
                              final id = r['id'] as String;
                              final gameId = r['game_id'] as String?;
                              final ads = r['ads_required'];
                              final given = (r['currency_given'] as num?)?.toDouble() ?? 0;
                              final target = (r['target_currency'] as num?)?.toDouble() ?? 0;
                              final active = (r['is_active'] as bool?) ?? true;

                              return GlassCard(
                                onTap: () => _openModal(existing: r),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_gameName(gameId), style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          Text(
                                            'Every $ads ads = ${given.toStringAsFixed(2)} Â· target ${target.toStringAsFixed(2)} Â· ${active ? "Active" : "Inactive"}',
                                            style: AppText.caption(size: 11),
                                          ),
                                        ],
                                      ),
                                    ),
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
