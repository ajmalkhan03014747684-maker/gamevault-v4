import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminCheckinScheduleScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminCheckinScheduleScreen({super.key, required this.onBack});

  @override
  State<AdminCheckinScheduleScreen> createState() => _AdminCheckinScheduleScreenState();
}

class _AdminCheckinScheduleScreenState extends State<AdminCheckinScheduleScreen> {
  List<Map<String, dynamic>> _schedule = [];
  bool _loading = true;
  String? _error;
  final Set<int> _saving = {};

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
      final data = await AdminService.instance.getCheckinSchedule();
      if (!mounted) return;
      setState(() {
        _schedule = data;
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

  Future<void> _editDay(Map<String, dynamic> day) async {
    final dayNumber = day['day_number'] as int;
    final controller = TextEditingController(
      text: (day['reward_amount'] as num?)?.toStringAsFixed(2) ?? '0.00',
    );

    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day $dayNumber Reward', style: AppText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppText.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 0.02',
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: AppText.body(color: AppColors.muted)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final parsed = double.tryParse(controller.text);
                        Navigator.pop(context, parsed);
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
    );

    if (newValue == null) return;

    setState(() => _saving.add(dayNumber));
    try {
      await AdminService.instance.updateCheckinDay(dayNumber, newValue);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving.remove(dayNumber));
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                  const SizedBox(width: 14),
                  Text('Check-In Schedule', style: AppText.heading(size: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tap any day to change its reward amount', style: AppText.caption(size: 12)),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _schedule.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemBuilder: (context, i) {
                          final day = _schedule[i];
                          final dayNumber = day['day_number'] as int;
                          final reward = (day['reward_amount'] as num?)?.toDouble() ?? 0.0;
                          final saving = _saving.contains(dayNumber);

                          return GlassCard(
                            onTap: saving ? null : () => _editDay(day),
                            padding: const EdgeInsets.all(8),
                            child: saving
                                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Day $dayNumber', style: AppText.caption(size: 11)),
                                      const SizedBox(height: 4),
                                      Text(reward.toStringAsFixed(2), style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.gold)),
                                      const Icon(Icons.edit_rounded, size: 12, color: AppColors.muted),
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
