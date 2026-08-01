import 'supabase_config.dart';
import 'auth_service.dart';

class AdminException implements Exception {
  final String message;
  AdminException(this.message);
  @override
  String toString() => message;
}

class AdminStats {
  final int totalUsers;
  final int totalAdsWatched;
  final int pendingPayouts;
  final double totalPaidOut;
  const AdminStats({
    required this.totalUsers,
    required this.totalAdsWatched,
    required this.pendingPayouts,
    required this.totalPaidOut,
  });
}

/// All admin operations. Every method here should only ever be reached
/// after AuthService.getCurrentUserRole() == 'admin' has already been
/// checked by the calling screen — this class doesn't re-check itself,
/// it relies on Supabase's Row Level Security policies (from the SQL
/// migration) as the real enforcement layer. UI-level gating is
/// convenience, not security — RLS is the actual security.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<AdminStats> getStats() async {
    try {
      final users = await supabase.from('user_profiles').select('id');
      final ads = await supabase.from('ad_watches').select('id');
      final pending = await supabase
          .from('payout_requests')
          .select('id')
          .eq('status', 'pending');
      final paid = await supabase
          .from('payout_requests')
          .select('amount')
          .eq('status', 'approved');

      double totalPaid = 0;
      for (final row in (paid as List)) {
        totalPaid += (row['amount'] as num?)?.toDouble() ?? 0;
      }

      return AdminStats(
        totalUsers: (users as List).length,
        totalAdsWatched: (ads as List).length,
        pendingPayouts: (pending as List).length,
        totalPaidOut: totalPaid,
      );
    } catch (e) {
      throw AdminException('Could not load stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPayouts() async {
    try {
      final rows = await supabase
          .from('payout_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load payout requests: $e');
    }
  }

  Future<void> approvePayout(String requestId) async {
    try {
      await supabase
          .from('payout_requests')
          .update({'status': 'approved'})
          .eq('id', requestId);
    } catch (e) {
      throw AdminException('Could not approve request: $e');
    }
  }

  Future<void> rejectPayout(String requestId, String reason) async {
    try {
      await supabase.from('payout_requests').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', requestId);
    } catch (e) {
      throw AdminException('Could not reject request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGames() async {
    try {
      final rows = await supabase.from('games').select().order('name');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load games: $e');
    }
  }

  Future<void> setGameActive(String gameId, bool active) async {
    try {
      await supabase.from('games').update({'is_active': active}).eq('id', gameId);
    } catch (e) {
      throw AdminException('Could not update game: $e');
    }
  }

  // ---------------------------------------------------------------
  // DAILY CHECK-IN SCHEDULE
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCheckinSchedule() async {
    try {
      final rows = await supabase
          .from('daily_checkin_schedule')
          .select()
          .order('day_number');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load check-in schedule: $e');
    }
  }

  Future<void> updateCheckinDay(int dayNumber, double rewardAmount) async {
    try {
      await supabase
          .from('daily_checkin_schedule')
          .update({'reward_amount': rewardAmount})
          .eq('day_number', dayNumber);
    } catch (e) {
      throw AdminException('Could not update day $dayNumber: $e');
    }
  }

  // ---------------------------------------------------------------
  // MISSIONS CRUD
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMissions() async {
    try {
      final rows = await supabase.from('missions').select().order('created_at');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load missions: $e');
    }
  }

  Future<void> createMission({
    required String title,
    required String period,
    required int goalCount,
    required double rewardAmount,
  }) async {
    try {
      await supabase.from('missions').insert({
        'title': title,
        'period': period,
        'goal_count': goalCount,
        'reward_amount': rewardAmount,
        'is_active': true,
      });
    } catch (e) {
      throw AdminException('Could not create mission: $e');
    }
  }

  Future<void> setMissionActive(String missionId, bool active) async {
    try {
      await supabase.from('missions').update({'is_active': active}).eq('id', missionId);
    } catch (e) {
      throw AdminException('Could not update mission: $e');
    }
  }

  Future<void> deleteMission(String missionId) async {
    try {
      await supabase.from('missions').delete().eq('id', missionId);
    } catch (e) {
      throw AdminException('Could not delete mission: $e');
    }
  }

  // ---------------------------------------------------------------
  // ANTI-BOT / FLAGGED ACTIVITY
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getSuspiciousActivity() async {
    try {
      final rows = await supabase
          .from('suspicious_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load flagged activity: $e');
    }
  }

  // ---------------------------------------------------------------
  // USER MANAGEMENT / BAN / WARN
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getUsers({String? searchQuery}) async {
    try {
      var query = supabase.from('user_profiles').select();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('username', '%$searchQuery%');
      }
      final rows = await query.order('username').limit(100);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load users: $e');
    }
  }

  Future<void> banUser(String userId, String reason) async {
    try {
      await supabase.from('user_profiles').update({
        'is_banned': true,
        'ban_reason': reason,
        'banned_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw AdminException('Could not ban user: $e');
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await supabase.from('user_profiles').update({
        'is_banned': false,
        'ban_reason': null,
        'banned_at': null,
      }).eq('id', userId);
    } catch (e) {
      throw AdminException('Could not unban user: $e');
    }
  }

  Future<void> warnUser(String userId) async {
    try {
      final row = await supabase
          .from('user_profiles')
          .select('warning_count')
          .eq('id', userId)
          .single();
      final current = (row['warning_count'] as int?) ?? 0;
      await supabase
          .from('user_profiles')
          .update({'warning_count': current + 1}).eq('id', userId);
    } catch (e) {
      throw AdminException('Could not warn user: $e');
    }
  }
}
