import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/admin_service.dart';

/// Admin â€” Payout Requests
///
/// FIX: previously only loaded PENDING requests and showed just an
/// amount + game id. Now shows the full history (pending, approved,
/// rejected) with the actual username, game name, currency, and â€” for
/// rejected ones â€” the reason the admin gave, matching the reference
/// app's admin payouts panel.
class AdminPayoutsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminPayoutsScreen({super.key, required this.onBack});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  List<Map<String, dynamic>> _requests = [];
  String _filter = 'Pending';
  bool _loading = true;
  String? _error;
  final Set<String> _processingIds = {};

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
      final data = await AdminService.instance.getAllPayouts();
      if (!mounted) return;
      setState(() {
        _requests = data;
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

  Future<void> _approve(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await AdminService.instance.approvePayout(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('âœ… Approved & notification sent!')),
      );
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
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
              Text('Reject Request', style: AppText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('The reason you type here is shown to the user.', style: AppText.caption(size: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                style: AppText.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Incorrect in-game UID',
                  hintStyle: AppText.caption(),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlineButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'Reject',
                      gradient: const LinearGradient(colors: [AppColors.dangerRed, Color(0xFFFF7A85)]),
                      onPressed: () {
                        if (reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a reason for rejection')),
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(id));
    try {
      await AdminService.instance.rejectPayout(id, reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('âŒ Rejected â€” currency refunded & notification sent!')),
      );
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _requests
        : _requests.where((r) => (r['status'] as String?)?.toLowerCase() == _filter.toLowerCase()).toList();

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
                  Text('Payout Requests', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['Pending', 'Approved', 'Rejected', 'All'].map((f) {
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
                        child: Text(f, style: AppText.body(size: 13, weight: FontWeight.w600, color: active ? Colors.white : AppColors.muted)),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
                  : filtered.isEmpty
                      ? Center(child: Text('No $_filter payout requests', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final r = filtered[i];
                              final id = r['id'] as String;
                              final status = (r['status'] as String?) ?? 'pending';
                              final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
                              final username = (r['user']?['username'] as String?) ?? (r['user']?['email'] as String?) ?? 'Unknown';
                              final gameName = (r['game']?['name'] as String?) ?? 'â€”';
                              final currency = (r['game']?['currency_name'] as String?) ?? '';
                              final gameUsername = (r['game_username'] as String?) ?? 'â€”';
                              final gameUid = (r['game_uid'] as String?) ?? 'â€”';
                              final rejectionReason = (r['rejection_reason'] as String?) ?? '';
                              final note = (r['note'] as String?) ?? '';
                              final isProcessing = _processingIds.contains(id);

                              final statusColor = status == 'approved'
                                  ? AppColors.successGreen
                                  : status == 'rejected'
                                      ? AppColors.dangerRed
                                      : AppColors.gold;

                              return GlassCard(
                                borderColor: statusColor.withOpacity(0.4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(username, style: AppText.body(size: 15, weight: FontWeight.w700))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(AppRadius.chip),
                                          ),
                                          child: Text(status, style: AppText.caption(size: 10, color: statusColor)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('ðŸ’° $amount $currency', style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.gold)),
                                    const SizedBox(height: 3),
                                    Text('ðŸŽ® Game: $gameName', style: AppText.caption(size: 12)),
                                    const SizedBox(height: 3),
                                    Text('ðŸ‘¤ Username: $gameUsername', style: AppText.caption(size: 12)),
                                    const SizedBox(height: 3),
                                    Text('ðŸ”‘ UID: $gameUid', style: AppText.caption(size: 12)),
                                    if (note.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text('ðŸ“ $note', style: AppText.caption(size: 11)),
                                    ],
                                    if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerRed.withOpacity(0.08),
                                          border: Border.all(color: AppColors.dangerRed.withOpacity(0.25)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('ðŸ“ Reason: $rejectionReason', style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                                      ),
                                    ],
                                    if (status == 'pending') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlineButton(
                                              label: 'âœ— Reject',
                                              onPressed: isProcessing ? null : () => _reject(id),
                                              height: 42,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: GradientButton(
                                              label: 'âœ“ Approve & Notify',
                                              gradient: AppGradients.successGlow,
                                              height: 42,
                                              loading: isProcessing,
                                              onPressed: () => _approve(id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
