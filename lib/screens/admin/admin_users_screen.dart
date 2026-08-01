import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminUsersScreen({super.key, required this.onBack});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

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
      final data = await AdminService.instance.getUsers(searchQuery: _searchController.text.trim());
      if (!mounted) return;
      setState(() {
        _users = data;
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

  Future<void> _banDialog(String userId, String username) async {
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
              Text('Ban $username?', style: AppText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                style: AppText.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'Reason for ban',
                  hintStyle: AppText.caption(),
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
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: AppText.body(color: AppColors.muted)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
                      child: const Text('Ban'),
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
    try {
      await AdminService.instance.banUser(userId, reasonController.text.trim());
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _unban(String userId) async {
    try {
      await AdminService.instance.unbanUser(userId);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _warn(String userId) async {
    try {
      await AdminService.instance.warnUser(userId);
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
                  Text('Manage Users', style: AppText.heading(size: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(),
                style: AppText.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'Search username...',
                  hintStyle: AppText.caption(),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
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
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          final id = u['id'] as String;
                          final username = (u['username'] as String?) ?? 'Unknown';
                          final isBanned = (u['is_banned'] as bool?) ?? false;
                          final warnings = (u['warning_count'] as int?) ?? 0;

                          return GlassCard(
                            borderColor: isBanned ? AppColors.dangerRed : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(username, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          if (warnings > 0)
                                            Text('$warnings warning(s)', style: AppText.caption(size: 11, color: AppColors.gold)),
                                          if (isBanned)
                                            Text('BANNED', style: AppText.caption(size: 11, color: AppColors.dangerRed)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (!isBanned) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _warn(id),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.gold)),
                                          child: Text('Warn', style: AppText.caption(size: 12, color: AppColors.gold)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _banDialog(id, username),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.dangerRed)),
                                          child: Text('Ban', style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                                        ),
                                      ),
                                    ] else
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _unban(id),
                                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.successGreen)),
                                          child: Text('Unban', style: AppText.caption(size: 12, color: AppColors.successGreen)),
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
