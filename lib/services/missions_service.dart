import 'supabase_config.dart';

enum MissionPeriod { daily, weekly, monthly }

class MissionsException implements Exception {
  final String message;
  MissionsException(this.message);
  @override
  String toString() => message;
}

class Mission {
  final String id;
  final String title;
  final MissionPeriod period;
  final String goalType; // 'ads_watched' or 'referrals'
  final int goalCount;
  final double rewardAmount;

  Mission({
    required this.id,
    required this.title,
    required this.period,
    required this.goalType,
    required this.goalCount,
    required this.rewardAmount,
  });

  factory Mission.fromRow(Map<String, dynamic> row) {
    final periodStr = (row['period'] as String?) ?? 'daily';
    return Mission(
      id: row['id'].toString(),
      title: (row['title'] as String?) ?? '',
      period: MissionPeriod.values.firstWhere(
        (p) => p.name == periodStr,
        orElse: () => MissionPeriod.daily,
      ),
      goalType: (row['goal_type'] as String?) ?? 'ads_watched',
      goalCount: (row['goal_count'] as num?)?.toInt() ?? 1,
      rewardAmount: (row['reward_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MissionProgress {
  final Mission mission;
  final int progress;
  final bool claimed;
  MissionProgress({required this.mission, required this.progress, required this.claimed});
  bool get isComplete => progress >= mission.goalCount;
}

/// Missions — now fully real. Admin-created missions come straight
/// from Supabase, and progress is computed LIVE from real ad_watches
/// / referrals counts in the relevant time window, rather than a
/// manually-incremented local counter that's easy to forget updating
/// from other screens.
class MissionsService {
  MissionsService._();
  static final MissionsService instance = MissionsService._();

  String? get _uid => supabase.auth.currentUser?.id;

  DateTime _periodStart(MissionPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case MissionPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case MissionPeriod.weekly:
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case MissionPeriod.monthly:
        return DateTime(now.year, now.month, 1);
    }
  }

  String _periodTag(MissionPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case MissionPeriod.daily:
        return '${now.year}-${now.month}-${now.day}';
      case MissionPeriod.weekly:
        final weekOfYear = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).floor();
        return '${now.year}-w$weekOfYear';
      case MissionPeriod.monthly:
        return '${now.year}-${now.month}';
    }
  }

  Future<List<MissionProgress>> getAllProgress() async {
    final uid = _uid;
    if (uid == null) throw MissionsException('Not logged in.');

    try {
      final missionRows = await supabase.from('missions').select().eq('is_active', true);
      final missions = (missionRows as List).map((r) => Mission.fromRow(r as Map<String, dynamic>)).toList();

      final result = <MissionProgress>[];
      for (final mission in missions) {
        final periodStart = _periodStart(mission.period);
        int progress;

        if (mission.goalType == 'referrals') {
          final rows = await supabase
              .from('referrals')
              .select('id')
              .eq('referrer_id', uid)
              .gte('created_at', periodStart.toIso8601String());
          progress = (rows as List).length;
        } else {
          final rows = await supabase
              .from('ad_watches')
              .select('id')
              .eq('user_id', uid)
              .gte('created_at', periodStart.toIso8601String());
          progress = (rows as List).length;
        }

        final claimRow = await supabase
            .from('user_missions')
            .select('is_claimed, period_tag')
            .eq('user_id', uid)
            .eq('mission_id', mission.id)
            .maybeSingle();

        final currentTag = _periodTag(mission.period);
        final claimed = claimRow != null && claimRow['period_tag'] == currentTag && (claimRow['is_claimed'] as bool? ?? false);

        result.add(MissionProgress(mission: mission, progress: progress, claimed: claimed));
      }
      return result;
    } catch (e) {
      throw MissionsException('Could not load missions: $e');
    }
  }

  /// Claims a completed mission's reward. Credits into the first
  /// active game's balance — same reasoning as Daily Check-in, since
  /// mission currency isn't tied to one specific game.
  Future<double> claim(String missionId) async {
    final uid = _uid;
    if (uid == null) throw MissionsException('Not logged in.');

    final all = await getAllProgress();
    final match = all.where((m) => m.mission.id == missionId).toList();
    if (match.isEmpty) throw MissionsException('Mission not found.');
    final mp = match.first;
    if (!mp.isComplete) throw MissionsException('Mission not complete yet.');
    if (mp.claimed) return 0.0;

    try {
      await supabase.from('user_missions').upsert({
        'user_id': uid,
        'mission_id': missionId,
        'period_tag': _periodTag(mp.mission.period),
        'progress': mp.progress,
        'is_claimed': true,
        'claimed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,mission_id,period_tag');

      final targetGame = await supabase.from('games').select('id').eq('is_active', true).limit(1).maybeSingle();
      if (targetGame != null) {
        final gameId = targetGame['id'].toString();
        final balanceRow = await supabase
            .from('user_game_balances')
            .select('balance')
            .eq('user_id', uid)
            .eq('game_id', gameId)
            .maybeSingle();
        final current = (balanceRow?['balance'] as num?)?.toDouble() ?? 0;
        await supabase.from('user_game_balances').upsert({
          'user_id': uid,
          'game_id': gameId,
          'balance': current + mp.mission.rewardAmount,
        });
      }

      return mp.mission.rewardAmount;
    } catch (e) {
      throw MissionsException('Could not claim mission: $e');
    }
  }
}
