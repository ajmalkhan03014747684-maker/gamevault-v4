import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 4 â€” Select Game / Games section
///
/// FIX: this used to receive a `games` list handed down from Home
/// Dashboard's last successful load, cached in RootFlow. Tapping the
/// bottom-nav "Games" tab directly (not via Home's "View All") never
/// updated that cache, so this screen could show a stale or even
/// empty list even after the admin added/removed a game. It now
/// fetches active games itself, every time it opens â€” same as Home
/// does â€” so both always agree.
class SelectGameScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(GameInfo game) onGameSelected;
  final String activeGameName;

  const SelectGameScreen({
    super.key,
    required this.onBack,
    required this.onGameSelected,
    this.activeGameName = '',
  });

  @override
  State<SelectGameScreen> createState() => _SelectGameScreenState();
}

class _SelectGameScreenState extends State<SelectGameScreen> {
  List<GameInfo> _games = [];
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
      final rows = await GameDataService.instance.getActiveGames();
      if (!mounted) return;
      setState(() {
        _games = rows.map((r) => GameInfo.fromRow(r)).toList();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications_none_rounded, color: AppColors.text),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Select Game', style: AppText.heading(size: 24)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose a game to earn rewards', style: AppText.caption()),
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
                  : _games.isEmpty
                      ? Center(
                          child: Text(
                            'No games available right now.\nCheck back soon!',
                            textAlign: TextAlign.center,
                            style: AppText.caption(),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _games.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final g = _games[i];
                              final isActive = g.name == widget.activeGameName;
                              return GlassCard(
                                onTap: () => widget.onGameSelected(g),
                                padding: const EdgeInsets.all(14),
                                borderColor: isActive ? AppColors.primaryPurple : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(g.icon, color: AppColors.primaryPurple),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(g.name, style: AppText.body(size: 15, weight: FontWeight.w700)),
                                              if (isActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryPurple.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(AppRadius.chip),
                                                  ),
                                                  child: Text('Active',
                                                      style: AppText.caption(size: 10, color: AppColors.primaryPurple)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(g.currency, style: AppText.caption(size: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
