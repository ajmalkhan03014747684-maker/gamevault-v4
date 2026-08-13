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
  List<String> _currencyOptions = [];
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
      final currencies = await AdminService.instance.getCurrencyOptions();
      if (!mounted) return;
      setState(() {
        _schedule = data;
        _currencyOptions = currencies;
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

    // Fall back to the day's current value even if it's not in the
    // live options list (e.g. a currency that's since been renamed),
    // so the dropdown never silently drops the existing selection.
    final currentCurrency = (day['currency_id'] as String?) ?? '';
    final options = List<String>.from(_currencyOptions);
    if (currentCurrency.isNotEmpty && !options.contains(currentCurrency)) {
      options.add(currentCurrency);
    }
    String? selectedCurrency = currentCurrency.isNotEmpty
        ? currentCurrency
        : (options.isNotEmpty ? options.first : null);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                const SizedBox(height: 10),
                Text('Currency', style: AppText.caption(size: 12)),
                const SizedBox(height: 6),
                if (options.isEmpty)
                  Text('No currencies found â€” add a game first.', style: AppText.caption(size: 12, color: AppColors.dangerRed))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCurrency,
                        isExpanded: true,
                        dropdownColor: AppColors.surface2,
                        style: AppText.body(size: 14),
                        items: options
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedCurrency = v),
                      ),
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
                        onPressed: selectedCurrency == null
                            ? null
                            : () {
                                final parsed = double.tryParse(controller.text);
                                if (parsed == null) return;
                                Navigator.pop(context, {
                                  'reward': parsed,
                                  'currency': selectedCurrency,
                                });
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
    );

    if (result == null) return;

    setState(() => _saving.add(dayNumber));
    try {
      await AdminService.instance.updateCheckinDay(
        dayNumber,
        result['reward'] as double,
        result['currency'] as String,
      );
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
              child: Text('Tap any day to change its reward amount and currency', style: AppText.caption(size: 12)),
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
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, i) {
                          final day = _schedule[i];
                          final dayNumber = day['day_number'] as int;
                          final reward = (day['reward_amount'] as num?)?.toDouble() ?? 0.0;
                          final currency = (day['currency_id'] as String?) ?? '';
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
                                      if (currency.isNotEmpty)
                                        Text(currency, style: AppText.caption(size: 10)),
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
