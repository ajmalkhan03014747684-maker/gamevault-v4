import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/game_data_service.dart';
import '../services/auth_service.dart';

/// Screen 15 — Leaderboard
/// Real cross-user data via leaderboard_view, ranked by ads watched
/// today (matches your original request that the app auto-detects
/// who's watched more ads today). Note: this ranks raw ad-watch
/// count, which can indirectly reward fast/repetitive watching — if
/// that becomes a problem, switch the ranking to total_earned instead
/// (already available in the same data).
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _tab = 'Weekly';
  List<Map<String, dynamic>> _entries = [];
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
      final data = await GameDataService.instance.getLeaderboard();
      if (!mounted) return;
      setState(() {
        _entries = data;
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
    final myUid = AuthService.instance.currentUser?.id;
    final myRank = _entries.indexWhere((e) => e['user_id'] == myUid) + 1;

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
                  Text('Leaderboard', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.button)),
                child: Row(
                  children: ['Weekly', 'Monthly', 'All Time'].map((t) {
                    final active = t == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primaryPurple : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.button - 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(t,
                              style: AppText.body(
                                  size: 12, weight: FontWeight.w700, color: active ? Colors.white : AppColors.muted)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Currently showing all-time data — Weekly/Monthly filtering needs date-scoped ad_watches, not yet wired.',
                style: AppText.caption(size: 10),
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
                  : _entries.isEmpty
                      ? Center(child: Text('No leaderboard data yet', style: AppText.caption()))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final e = _entries[i];
                              final rank = i + 1;
                              final isMe = e['user_id'] == myUid;
                              final username = (e['username'] as String?) ?? 'Player';
                              final adsToday = (e['ads_today'] as num?)?.toInt() ?? 0;

                              return GlassCard(
                                borderColor: isMe ? AppColors.primaryPurple : null,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '#$rank',
                                        style: AppText.body(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: rank == 1
                                              ? AppColors.gold
                                              : rank == 2
                                                  ? const Color(0xFFC0C0C0)
                                                  : rank == 3
                                                      ? const Color(0xFFCD7F32)
                                                      : AppColors.muted,
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(radius: 16, backgroundColor: AppColors.surface2, child: const Icon(Icons.person, size: 18, color: AppColors.muted)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(username, style: AppText.body(size: 14, weight: FontWeight.w600))),
                                    Row(
                                      children: [
                                        const Icon(Icons.play_circle_outline_rounded, color: AppColors.primaryPurple, size: 16),
                                        const SizedBox(width: 4),
                                        Text('$adsToday ads', style: AppText.body(size: 13, weight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (myRank > 0)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Your Rank: #$myRank', style: AppText.caption(size: 13), textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
