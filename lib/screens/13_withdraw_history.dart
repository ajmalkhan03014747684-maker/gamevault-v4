import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum WithdrawStatus { pending, approved, rejected }

class WithdrawEntry {
  final int amount;
  final String currencyLabel;
  final String uid;
  final String date;
  final WithdrawStatus status;
  const WithdrawEntry(this.amount, this.currencyLabel, this.uid, this.date, this.status);
}

const kWithdrawHistory = [
  WithdrawEntry(260, 'Diamonds', '1234567890', '20 May 2024', WithdrawStatus.approved),
  WithdrawEntry(260, 'Diamonds', '1234567890', '18 May 2024', WithdrawStatus.pending),
  WithdrawEntry(260, 'Diamonds', '1234567890', '15 May 2024', WithdrawStatus.rejected),
];

/// Screen 13 — Withdraw History
class WithdrawHistoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WithdrawHistoryScreen({super.key, required this.onBack});

  @override
  State<WithdrawHistoryScreen> createState() => _WithdrawHistoryScreenState();
}

class _WithdrawHistoryScreenState extends State<WithdrawHistoryScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = kWithdrawHistory.where((e) {
      if (_filter == 'All') return true;
      return e.status.name.toLowerCase() == _filter.toLowerCase();
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  return GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.amount} ${e.currencyLabel}', style: AppText.body(size: 14, weight: FontWeight.w700)),
                              Text('UID: ${e.uid}', style: AppText.caption(size: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadge(status: e.status),
                            const SizedBox(height: 4),
                            Text(e.date, style: AppText.caption(size: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WithdrawStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case WithdrawStatus.approved:
        color = AppColors.successGreen;
        label = 'Approved';
        break;
      case WithdrawStatus.pending:
        color = AppColors.gold;
        label = 'Pending';
        break;
      case WithdrawStatus.rejected:
        color = AppColors.dangerRed;
        label = 'Rejected';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label, style: AppText.caption(size: 10, color: color)),
    );
  }
}
