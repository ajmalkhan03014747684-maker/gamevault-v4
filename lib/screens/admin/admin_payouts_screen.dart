import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../services/admin_service.dart';

class AdminPayoutsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminPayoutsScreen({super.key, required this.onBack});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  List<Map<String, dynamic>> _requests = [];
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
      final data = await AdminService.instance.getPendingPayouts();
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
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                style: AppText.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'Reason (shown to the user)',
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
                      onPressed: () => Navigator.pop(context, true),
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? Center(child: Text('No pending payout requests', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final r = _requests[i];
                              final id = r['id'] as String;
                              final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
                              final gameUid = (r['game_uid'] as String?) ?? '—';
                              final gameId = (r['game_id'] as String?) ?? '—';
                              final isProcessing = _processingIds.contains(id);

                              return GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.diamond_rounded, color: AppColors.gold, size: 22),
                                        const SizedBox(width: 8),
                                        Text(amount.toStringAsFixed(2), style: AppText.body(size: 16, weight: FontWeight.w700)),
                                        const Spacer(),
                                        Text(gameId, style: AppText.caption(size: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Game UID: $gameUid', style: AppText.caption(size: 12)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlineButton(
                                            label: 'Reject',
                                            onPressed: isProcessing ? null : () => _reject(id),
                                            height: 42,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: GradientButton(
                                            label: 'Approve',
                                            gradient: AppGradients.successGlow,
                                            height: 42,
                                            loading: isProcessing,
                                            onPressed: () => _approve(id),
                                          ),
                                        ),
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
