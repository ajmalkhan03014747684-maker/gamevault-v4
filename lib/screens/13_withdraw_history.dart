import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/game_data_service.dart';

/// Screen 13 — Withdraw History
/// Real requests via GameDataService instead of hardcoded examples.
class WithdrawHistoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WithdrawHistoryScreen({super.key, required this.onBack});

  @override
  State<WithdrawHistoryScreen> createState() => _WithdrawHistoryScreenState();
}

class _WithdrawHistoryScreenState extends State<WithdrawHistoryScreen> {
  String _filter = 'All';
  List<Map<String, dynamic>> _history = [];
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
      final data = await GameDataService.instance.getWithdrawHistory();
      if (!mounted) return;
      setState(() {
        _history = data;
        _loading = false;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _history.where((e) {
      if (_filter == 'All') return true;
      return (e['status'] as String?)?.toLowerCase() == _filter.toLowerCase();
    }).toList();

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
                  Text('Withdraw History', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['All', 'Pending', 'Approved', 'Rejected'].map((f) {
                  final active = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primaryPurple : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        alignment: Alignment.center,
                        child: Text(f,
                            style: AppText.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.muted)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Text('No withdraw requests yet', style: AppText.caption()),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final e = filtered[i];
                              final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                              final status = (e['status'] as String?) ?? 'pending';
                              final uid = (e['game_uid'] as String?) ?? '—';
                              final date = (e['created_at'] as String?)?.split('T').first ?? '';

                              return GlassCard(
                                child: Row(
                                  children: [
                                    const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(amount.toStringAsFixed(2), style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          Text('UID: $uid', style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _StatusBadge(status: status),
                                        const SizedBox(height: 4),
                                        Text(date, style: AppText.caption(size: 11)),
                                      ],
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.successGreen;
        break;
      case 'rejected':
        color = AppColors.dangerRed;
        break;
      default:
        color = AppColors.gold;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        status.isEmpty ? status : status[0].toUpperCase() + status.substring(1),
        style: AppText.caption(size: 10, color: color),
      ),
    );
  }
}
