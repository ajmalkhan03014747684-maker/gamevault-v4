import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminGamesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminGamesScreen({super.key, required this.onBack});

  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
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
      final data = await AdminService.instance.getGames();
      if (!mounted) return;
      setState(() {
        _games = data;
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

  Future<void> _toggle(String id, bool current) async {
    try {
      await AdminService.instance.setGameActive(id, !current);
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
                  Text('Manage Games', style: AppText.heading(size: 20)),
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
                  : _games.isEmpty
                      ? Center(child: Text('No games found', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _games.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final g = _games[i];
                              final id = (g['id'] ?? '').toString();
                              final name = (g['name'] as String?) ?? 'Unknown';
                              final currency = (g['currency_name'] as String?) ?? '';
                              final active = (g['is_active'] as bool?) ?? true;

                              return GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          Text(currency, style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: active,
                                      onChanged: (_) => _toggle(id, active),
                                      activeColor: AppColors.primaryPurple,
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
