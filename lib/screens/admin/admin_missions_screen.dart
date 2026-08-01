import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/admin_service.dart';

class AdminMissionsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminMissionsScreen({super.key, required this.onBack});

  @override
  State<AdminMissionsScreen> createState() => _AdminMissionsScreenState();
}

class _AdminMissionsScreenState extends State<AdminMissionsScreen> {
  List<Map<String, dynamic>> _missions = [];
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
      final data = await AdminService.instance.getMissions();
      if (!mounted) return;
      setState(() {
        _missions = data;
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

  Future<void> _createMission() async {
    final titleController = TextEditingController();
    final goalController = TextEditingController();
    final rewardController = TextEditingController();
    String period = 'daily';

    final created = await showDialog<bool>(
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
                  Text('New Mission', style: AppText.body(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _dialogField(titleController, 'Title (e.g. Watch 5 ads today)'),
                  const SizedBox(height: 10),
                  Row(
                    children: ['daily', 'weekly', 'monthly'].map((p) {
                      final active = period == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => period = p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primaryPurple : AppColors.surface2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(p, style: AppText.caption(size: 11, color: active ? Colors.white : AppColors.muted)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _dialogField(goalController, 'Goal count (e.g. 5)', numeric: true),
                  const SizedBox(height: 10),
                  _dialogField(rewardController, 'Reward amount (e.g. 0.05)', numeric: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: AppText.body(color: AppColors.muted)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                          child: const Text('Create'),
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

    if (created != true) return;
    final goalCount = int.tryParse(goalController.text) ?? 1;
    final reward = double.tryParse(rewardController.text) ?? 0.0;
    if (titleController.text.trim().isEmpty) return;

    try {
      await AdminService.instance.createMission(
        title: titleController.text.trim(),
        period: period,
        goalCount: goalCount,
        rewardAmount: reward,
      );
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _dialogField(TextEditingController controller, String hint, {bool numeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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

  Future<void> _toggle(String id, bool current) async {
    try {
      await AdminService.instance.setMissionActive(id, !current);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(String id) async {
    try {
      await AdminService.instance.deleteMission(id);
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
                  Expanded(child: Text('Missions', style: AppText.heading(size: 20))),
                  GestureDetector(
                    onTap: _createMission,
                    child: const Icon(Icons.add_circle_rounded, color: AppColors.primaryPurple, size: 26),
                  ),
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
                  : _missions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No missions yet', style: AppText.caption()),
                              const SizedBox(height: 12),
                              GradientButton(label: 'Create First Mission', onPressed: _createMission),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _missions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final m = _missions[i];
                              final id = m['id'] as String;
                              final title = (m['title'] as String?) ?? '';
                              final period = (m['period'] as String?) ?? 'daily';
                              final goal = m['goal_count'] ?? 0;
                              final reward = (m['reward_amount'] as num?)?.toDouble() ?? 0.0;
                              final active = (m['is_active'] as bool?) ?? true;

                              return GlassCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text('$period • goal: $goal • reward: ${reward.toStringAsFixed(2)}', style: AppText.caption(size: 11)),
                                        ],
                                      ),
                                    ),
                                    Switch(value: active, onChanged: (_) => _toggle(id, active), activeColor: AppColors.primaryPurple),
                                    GestureDetector(
                                      onTap: () => _delete(id),
                                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed, size: 20),
                                    ),
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
