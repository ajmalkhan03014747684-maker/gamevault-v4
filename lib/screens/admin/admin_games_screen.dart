import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/admin_service.dart';

/// Admin â€” Manage Games. Create/edit form matching the games table
/// exactly (name, emoji, currency name/icon, description, active
/// toggle), plus delete.
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

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameController = TextEditingController(text: existing?['name'] as String? ?? '');
    final emojiController = TextEditingController(text: existing?['emoji'] as String? ?? 'ðŸŽ®');
    final currencyNameController = TextEditingController(text: existing?['currency_name'] as String? ?? '');
    final currencyIconController = TextEditingController(text: existing?['currency_icon'] as String? ?? 'ðŸ’Ž');
    final descriptionController = TextEditingController(text: existing?['description'] as String? ?? '');
    bool isActive = (existing?['is_active'] as bool?) ?? true;

    final saved = await showDialog<bool>(
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
                  Text(existing == null ? 'Add Game' : 'Edit Game', style: AppText.body(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _field(nameController, 'Game name (e.g. Free Fire)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _field(emojiController, 'Emoji (e.g. ðŸ”¥)')),
                      const SizedBox(width: 10),
                      Expanded(child: _field(currencyIconController, 'Currency emoji (e.g. ðŸ’Ž)')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(currencyNameController, 'Currency name (e.g. Diamonds)'),
                  const SizedBox(height: 10),
                  _field(descriptionController, 'Short description (optional)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Active', style: AppText.body(size: 14)),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (v) => setDialogState(() => isActive = v),
                      ),
                    ],
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
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                          child: Text(existing == null ? 'Add' : 'Save'),
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

    if (saved != true) return;
    if (nameController.text.trim().isEmpty || currencyNameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game name and currency name are required.')),
      );
      return;
    }

    try {
      await AdminService.instance.createOrUpdateGame(
        id: existing?['id']?.toString(),
        name: nameController.text.trim(),
        emoji: emojiController.text.trim().isEmpty ? 'ðŸŽ®' : emojiController.text.trim(),
        currencyName: currencyNameController.text.trim(),
        currencyIcon: currencyIconController.text.trim().isEmpty ? 'ðŸ’Ž' : currencyIconController.text.trim(),
        description: descriptionController.text.trim(),
        isActive: isActive,
      );
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
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
      await AdminService.instance.setGameActive(id, !current);
      await _load();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete $name?', style: AppText.body(size: 16, weight: FontWeight.w700)),
        content: Text('This cannot be undone.', style: AppText.caption()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppText.body(color: AppColors.muted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: AppText.body(color: AppColors.dangerRed))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AdminService.instance.deleteGame(id);
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
                  Expanded(child: Text('Manage Games', style: AppText.heading(size: 18))),
                  GestureDetector(
                    onTap: () => _openForm(),
                    child: const Icon(Icons.add_circle_rounded, color: AppColors.primaryPurple, size: 28),
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
                  : _games.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('No games yet', style: AppText.caption()),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(Icons.add, color: AppColors.primaryPurple),
                                label: Text('Add your first game', style: AppText.body(color: AppColors.primaryPurple)),
                              ),
                            ],
                          ),
                        )
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
                              final emoji = (g['emoji'] as String?) ?? 'ðŸŽ®';
                              final currency = (g['currency_name'] as String?) ?? '';
                              final active = (g['is_active'] as bool?) ?? true;

                              return GlassCard(
                                onTap: () => _openForm(existing: g),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: AppText.body(size: 14, weight: FontWeight.w700)),
                                          Text(currency, style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    Switch(value: active, onChanged: (_) => _toggle(id, active), activeColor: AppColors.primaryPurple),
                                    GestureDetector(
                                      onTap: () => _delete(id, name),
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
