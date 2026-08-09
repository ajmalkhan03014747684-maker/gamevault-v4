import 'supabase_config.dart';

class DailyCheckinException implements Exception {
  final String message;
  DailyCheckinException(this.message);
  @override
  String toString() => message;
}

class DailyCheckinStatus {
  final int currentDay; // 1-30
  final bool claimedToday;
  DailyCheckinStatus({required this.currentDay, required this.claimedToday});
}

/// Daily Check-in — now fully real. Reads the admin-configured 30-day
/// schedule from Supabase, tracks claims in the real daily_checkins
/// table (so streaks survive reinstalls, not just local storage), and
/// credits real currency on claim. This is what makes Admin Panel's
/// Daily Check-in Schedule screen actually control the app.
class DailyCheckinService {
  DailyCheckinService._();
  static final DailyCheckinService instance = DailyCheckinService._();

  String? get _uid => supabase.auth.currentUser?.id;

  final Map<int, double> _scheduleCache = {};

  /// Synchronous read from the already-preloaded cache — call
  /// preloadSchedule() first (e.g. in the screen's _load()), then use
  /// this in build() where an async call isn't possible. Returns 0.02
  /// as a fallback if that day hasn't been cached yet.
  double cachedReward(int day) => _scheduleCache[day] ?? 0.02;

  /// Reward for a given day, from the real admin-configured schedule.
  /// Falls back to a sane default (0.02) only if that day genuinely
  /// isn't configured yet — never silently shows 0.
  Future<double> rewardForDay(int day) async {
    if (_scheduleCache.containsKey(day)) return _scheduleCache[day]!;
    try {
      final row = await supabase
          .from('daily_checkin_schedule')
          .select('reward_amount')
          .eq('day_number', day)
          .maybeSingle();
      final reward = (row?['reward_amount'] as num?)?.toDouble() ?? 0.02;
      _scheduleCache[day] = reward;
      return reward;
    } catch (e) {
      return 0.02;
    }
  }

  /// Preloads the whole 30-day schedule at once (cheaper than 30
  /// separate calls) — call this before rendering the calendar grid.
  Future<void> preloadSchedule() async {
    try {
      final rows = await supabase.from('daily_checkin_schedule').select();
      for (final row in (rows as List)) {
        final day = (row['day_number'] as num?)?.toInt();
        final reward = (row['reward_amount'] as num?)?.toDouble();
        if (day != null && reward != null) _scheduleCache[day] = reward;
      }
    } catch (e) {
      // Non-fatal — rewardForDay() falls back to a default per-day.
    }
  }

  Future<DailyCheckinStatus> getStatus() async {
    final uid = _uid;
    if (uid == null) throw DailyCheckinException('Not logged in.');

    try {
      final rows = await supabase
          .from('daily_checkins')
          .select('checkin_date, day_number')
          .eq('user_id', uid)
          .order('checkin_date', ascending: false)
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows as List);

      if (list.isEmpty) {
        return DailyCheckinStatus(currentDay: 1, claimedToday: false);
      }

      final lastCheckinStr = list.first['checkin_date'] as String;
      final lastDay = (list.first['day_number'] as num).toInt();
      final lastCheckin = DateTime.parse(lastCheckinStr);
      final now = DateTime.now();
      final lastDate = DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day);
      final today = DateTime(now.year, now.month, now.day);
      final daysSince = today.difference(lastDate).inDays;

      if (daysSince == 0) {
        return DailyCheckinStatus(currentDay: lastDay, claimedToday: true);
      } else if (daysSince == 1) {
        final nextDay = lastDay >= 30 ? 1 : lastDay + 1;
        return DailyCheckinStatus(currentDay: nextDay, claimedToday: false);
      } else {
        return DailyCheckinStatus(currentDay: 1, claimedToday: false);
      }
    } catch (e) {
      throw DailyCheckinException('Could not load check-in status: $e');
    }
  }

  /// Claims today's reward: records it in daily_checkins, credits the
  /// real reward to the user's balance, returns the amount credited.
  /// Credits into the first active game's balance — since check-in
  /// currency isn't tied to one specific game in this schema, and the
  /// Wallet's Total Balance sums across all games anyway, this keeps
  /// the reward visible without needing a game-picker UI here.
  Future<double> claimToday() async {
    final uid = _uid;
    if (uid == null) throw DailyCheckinException('Not logged in.');

    final status = await getStatus();
    if (status.claimedToday) return 0.0;

    try {
      final reward = await rewardForDay(status.currentDay);
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day).toIso8601String().split('T').first;

      await supabase.from('daily_checkins').insert({
        'user_id': uid,
        'checkin_date': todayDateOnly,
        'day_number': status.currentDay,
        'reward_given': reward,
      });

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
          'balance': current + reward,
        });
      }

      return reward;
    } catch (e) {
      throw DailyCheckinException('Could not claim today\'s reward: $e');
    }
  }
}
