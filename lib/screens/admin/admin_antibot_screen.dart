import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminAntiBotScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminAntiBotScreen({super.key, required this.onBack});

  @override
  State<AdminAntiBotScreen> createState() => _AdminAntiBotScreenState();
}

class _AdminAntiBotScreenState extends State<AdminAntiBotScreen> {
  List<Map<String, dynamic>> _events = [];
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
      final data = await AdminService.instance.getSuspiciousActivity();
      if (!mounted) return;
      setState(() {
        _events = data;
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
                  Text('Flagged Activity', style: AppText.heading(size: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Most recent 100 suspicious events, newest first', style: AppText.caption(size: 12)),
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
                  : _events.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_rounded, color: AppColors.successGreen, size: 36),
                              const SizedBox(height: 10),
                              Text('No suspicious activity detected', style: AppText.caption()),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _events.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final e = _events[i];
                              final type = (e['event_type'] as String?) ?? 'unknown';
                              final detail = (e['detail'] as String?) ?? '';
                              final userId = (e['user_id'] as String?) ?? '';
                              final createdAt = (e['created_at'] as String?) ?? '';

                              return GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.secondaryOrange, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(type, style: AppText.body(size: 13, weight: FontWeight.w700)),
                                          if (detail.isNotEmpty) Text(detail, style: AppText.caption(size: 11)),
                                          Text('User: ${userId.length > 8 ? userId.substring(0, 8) : userId}...', style: AppText.caption(size: 10)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                                      style: AppText.caption(size: 10),
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
