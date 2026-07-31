import 'package:shared_preferences/shared_preferences.dart';

enum MissionPeriod { daily, weekly, monthly }

class Mission {
  final String id;
  final String title;
  final MissionPeriod period;
  final int goalCount;
  final double rewardAmount;
  const Mission({
    required this.id,
    required this.title,
    required this.period,
    required this.goalCount,
    required this.rewardAmount,
  });
}

/// Placeholder mission list — once Supabase is wired, this comes from
/// the `missions` table (already in the SQL migration) so admins can
/// add/edit daily, weekly, and monthly missions from the Admin Panel.
const kDefaultMissions = [
  Mission(id: 'watch_5_ads', title: 'Watch 5 ads today', period: MissionPeriod.daily, goalCount: 5, rewardAmount: 0.05),
  Mission(id: 'refer_1', title: 'Refer 1 friend', period: MissionPeriod.weekly, goalCount: 1, rewardAmount: 0.20),
  Mission(id: 'watch_50_ads_month', title: 'Watch 50 ads this month', period: MissionPeriod.monthly, goalCount: 50, rewardAmount: 1.00),
];

class MissionProgress {
  final Mission mission;
  final int progress;
  final bool claimed;
  MissionProgress({required this.mission, required this.progress, required this.claimed});
  bool get isComplete => progress >= mission.goalCount;
}

/// Tracks mission progress locally, with automatic reset when the
/// relevant period (day/week/month) rolls over.
class MissionsService {
  MissionsService._();
  static final MissionsService instance = MissionsService._();

  String _progressKey(String missionId) => 'mission_progress_$missionId';
  String _claimedKey(String missionId) => 'mission_claimed_$missionId';
  String _periodKey(String missionId) => 'mission_period_$missionId';

  String _currentPeriodTag(MissionPeriod period) {
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
    final prefs = await SharedPreferences.getInstance();
    final result = <MissionProgress>[];

    for (final mission in kDefaultMissions) {
      final currentTag = _currentPeriodTag(mission.period);
      final storedTag = prefs.getString(_periodKey(mission.id));

      if (storedTag != currentTag) {
        // Period rolled over — reset this mission.
        await prefs.setInt(_progressKey(mission.id), 0);
        await prefs.setBool(_claimedKey(mission.id), false);
        await prefs.setString(_periodKey(mission.id), currentTag);
      }

      final progress = prefs.getInt(_progressKey(mission.id)) ?? 0;
      final claimed = prefs.getBool(_claimedKey(mission.id)) ?? false;
      result.add(MissionProgress(mission: mission, progress: progress, claimed: claimed));
    }

    return result;
  }

  /// Call this whenever a relevant action happens (e.g. an ad is
  /// watched) to increment progress toward matching missions.
  Future<void> incrementProgress(String missionId, {int by = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_progressKey(missionId)) ?? 0;
    await prefs.setInt(_progressKey(missionId), current + by);
  }

  Future<double> claim(String missionId) async {
    final all = await getAllProgress();
    final match = all.where((m) => m.mission.id == missionId).toList();
    if (match.isEmpty || !match.first.isComplete || match.first.claimed) return 0.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claimedKey(missionId), true);

    // TODO once Supabase is wired: credit reward to real balance server-side.
    return match.first.mission.rewardAmount;
  }
}
