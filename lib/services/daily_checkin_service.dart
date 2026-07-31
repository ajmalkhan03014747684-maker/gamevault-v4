import 'package:shared_preferences/shared_preferences.dart';

class DailyCheckinStatus {
  final int currentDay; // 1-30
  final bool claimedToday;
  DailyCheckinStatus({required this.currentDay, required this.claimedToday});
}

/// Daily Check-in logic. Currently local-only (per-device), matching the
/// rest of the app's current architecture. Once Supabase is wired, the
/// reward schedule below moves to the `daily_checkins`-adjacent admin
/// config table (already defined in the SQL migration) so admins can
/// set a different reward per day, per currency, for up to 30 days —
/// this class's public API (getStatus/claimToday/rewardForDay) stays
/// the same either way, so screens don't need to change.
class DailyCheckinService {
  DailyCheckinService._();
  static final DailyCheckinService instance = DailyCheckinService._();

  static const _lastClaimKey = 'daily_checkin_last_claim_date';
  static const _currentDayKey = 'daily_checkin_current_day';

  /// Placeholder default schedule — 30 days, gently increasing reward.
  /// Replace with a real admin-configured schedule once Supabase is
  /// wired (this is exactly the kind of value the Admin Panel's Daily
  /// Check-in config screen will control).
  double rewardForDay(int day) {
    final base = 0.02;
    final bonus = (day / 5).floor() * 0.01;
    return base + bonus;
  }

  Future<DailyCheckinStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimStr = prefs.getString(_lastClaimKey);
    final currentDay = prefs.getInt(_currentDayKey) ?? 1;

    if (lastClaimStr == null) {
      return DailyCheckinStatus(currentDay: 1, claimedToday: false);
    }

    final lastClaim = DateTime.parse(lastClaimStr);
    final now = DateTime.now();
    final lastClaimDay = DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
    final today = DateTime(now.year, now.month, now.day);
    final daysSince = today.difference(lastClaimDay).inDays;

    if (daysSince == 0) {
      // Already claimed today.
      return DailyCheckinStatus(currentDay: currentDay, claimedToday: true);
    } else if (daysSince == 1) {
      // Streak continues, ready to claim next day.
      final nextDay = currentDay >= 30 ? 1 : currentDay + 1;
      return DailyCheckinStatus(currentDay: nextDay, claimedToday: false);
    } else {
      // Missed a day or more — streak resets to day 1.
      return DailyCheckinStatus(currentDay: 1, claimedToday: false);
    }
  }

  Future<double> claimToday() async {
    final status = await getStatus();
    if (status.claimedToday) return 0.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastClaimKey, DateTime.now().toIso8601String());
    await prefs.setInt(_currentDayKey, status.currentDay);

    // TODO once Supabase is wired: also credit this amount to the
    // user's real currency balance server-side, not just local state.
    return rewardForDay(status.currentDay);
  }
}
