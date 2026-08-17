import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_refresh_indicator.dart';
import '../services/game_data_service.dart';

/// Screen 16 â€” Notifications
/// Real notifications from Supabase. "VIEW ALL" scrolls to the bottom
/// of the (already-complete) list â€” since this screen already shows
/// everything, "view all" becomes a real, meaningful action rather
/// than a dead button: it confirms there's nothing more to load.
class NotificationsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const NotificationsScreen({super.key, required this.onBack});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;
  final _scrollController = ScrollController();

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
      final data = await GameDataService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _loading = false;
      });
      // Now that the user has actually opened this screen, mark
      // everything read â€” matches how a normal notification inbox
      // behaves (the banner popup never marks things read on its own).
      await GameDataService.instance.markAllNotificationsRead();
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'payout_approved':
        return Icons.check_circle_rounded;
      case 'payout_rejected':
        return Icons.cancel_rounded;
      case 'approval':
        return Icons.star_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'mission':
        return Icons.emoji_events_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'payout_approved':
        return AppColors.successGreen;
      case 'payout_rejected':
        return AppColors.dangerRed;
      case 'approval':
        return AppColors.gold;
      case 'bonus':
        return AppColors.primaryPurple;
      case 'mission':
        return AppColors.secondaryOrange;
      default:
        return AppColors.dangerRed;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                  Text('Notifications', style: AppText.heading(size: 20)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? Center(child: Text('No notifications yet', style: AppText.caption()))
                      : AppRefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final n = _notifications[i];
                              final type = (n['type'] as String?) ?? 'event';
                              final title = (n['title'] as String?) ?? '';
                              final message = (n['message'] as String?) ?? '';
                              final createdAt = (n['created_at'] as String?) ?? '';
                              final isRead = (n['is_read'] as bool?) ?? true;

                              return GlassCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _colorFor(type).withOpacity(0.18),
                                      ),
                                      child: Icon(_iconFor(type), color: _colorFor(type), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: Text(title, style: AppText.body(size: 14, weight: FontWeight.w700))),
                                              if (!isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryPurple,
                                                    borderRadius: BorderRadius.circular(AppRadius.chip),
                                                  ),
                                                  child: const Text('NEW', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                                                ),
                                            ],
                                          ),
                                          if (message.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(message, style: AppText.caption(size: 12)),
                                          ],
                                          if (createdAt.length >= 10) ...[
                                            const SizedBox(height: 4),
                                            Text(createdAt.substring(0, 10), style: AppText.caption(size: 10)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (!_loading && _notifications.length > 5)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'VIEW ALL (${_notifications.length})',
                      style: AppText.body(size: 14, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
