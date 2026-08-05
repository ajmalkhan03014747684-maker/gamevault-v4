import 'supabase_config.dart';

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
/// checked by the calling screen — the REAL security is the RLS
/// policies on each table, not this UI-level gate.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  // ---------------------------------------------------------------
  // DASHBOARD STATS
  // ---------------------------------------------------------------
  Future<AdminStats> getStats() async {
    try {
      final users = await supabase.from('user_profiles').select('id');
      final ads = await supabase.from('ad_watches').select('id');
      final pending = await supabase.from('payout_requests').select('id').eq('status', 'pending');
      final paid = await supabase.from('payout_requests').select('amount').eq('status', 'approved');

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

  // ---------------------------------------------------------------
  // PAYOUT REQUESTS
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getPendingPayouts() async {
    try {
      final rows = await supabase.from('payout_requests').select().eq('status', 'pending').order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load payout requests: $e');
    }
  }

  Future<void> approvePayout(String requestId) async {
    try {
      await supabase.from('payout_requests').update({'status': 'approved'}).eq('id', requestId);
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

  // ---------------------------------------------------------------
  // GAMES (full CRUD)
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getGames() async {
    try {
      final rows = await supabase.from('games').select().order('name');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load games: $e');
    }
  }

  Future<void> createOrUpdateGame({
    String? id,
    required String name,
    required String emoji,
    required String currencyName,
    required String currencyIcon,
    required String description,
    required bool isActive,
  }) async {
    try {
      final data = {
        'name': name,
        'emoji': emoji,
        'currency_name': currencyName,
        'currency_icon': currencyIcon,
        'description': description,
        'is_active': isActive,
      };
      if (id != null) {
        await supabase.from('games').update(data).eq('id', id);
      } else {
        await supabase.from('games').insert(data);
      }
    } catch (e) {
      throw AdminException('Could not save game: $e');
    }
  }

  Future<void> setGameActive(String gameId, bool active) async {
    try {
      await supabase.from('games').update({'is_active': active}).eq('id', gameId);
    } catch (e) {
      throw AdminException('Could not update game: $e');
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      await supabase.from('games').delete().eq('id', gameId);
    } catch (e) {
      throw AdminException('Could not delete game: $e');
    }
  }

  // ---------------------------------------------------------------
  // DAILY CHECK-IN SCHEDULE
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCheckinSchedule() async {
    try {
      final rows = await supabase.from('daily_checkin_schedule').select().order('day_number');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load check-in schedule: $e');
    }
  }

  Future<void> updateCheckinDay(int dayNumber, double rewardAmount) async {
    try {
      await supabase.from('daily_checkin_schedule').update({'reward_amount': rewardAmount}).eq('day_number', dayNumber);
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
      final rows = await supabase.from('suspicious_activity_log').select().order('created_at', ascending: false).limit(100);
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
      final row = await supabase.from('user_profiles').select('warning_count').eq('id', userId).single();
      final current = (row['warning_count'] as int?) ?? 0;
      await supabase.from('user_profiles').update({'warning_count': current + 1}).eq('id', userId);
    } catch (e) {
      throw AdminException('Could not warn user: $e');
    }
  }

  // ---------------------------------------------------------------
  // AD THRESHOLDS
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getThresholds() async {
    try {
      final rows = await supabase.from('ad_thresholds').select().order('ads_required');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load thresholds: $e');
    }
  }

  Future<void> createThreshold({required String gameId, required int adsRequired, required double currencyReward}) async {
    try {
      await supabase.from('ad_thresholds').insert({
        'game_id': gameId,
        'ads_required': adsRequired,
        'currency_reward': currencyReward,
        'is_active': true,
      });
    } catch (e) {
      throw AdminException('Could not create threshold: $e');
    }
  }

  Future<void> updateThreshold(String id, {required int adsRequired, required double currencyReward}) async {
    try {
      await supabase.from('ad_thresholds').update({
        'ads_required': adsRequired,
        'currency_reward': currencyReward,
      }).eq('id', id);
    } catch (e) {
      throw AdminException('Could not update threshold: $e');
    }
  }

  Future<void> setThresholdActive(String id, bool active) async {
    try {
      await supabase.from('ad_thresholds').update({'is_active': active}).eq('id', id);
    } catch (e) {
      throw AdminException('Could not update threshold: $e');
    }
  }

  Future<void> deleteThreshold(String id) async {
    try {
      await supabase.from('ad_thresholds').delete().eq('id', id);
    } catch (e) {
      throw AdminException('Could not delete threshold: $e');
    }
  }

  // ---------------------------------------------------------------
  // REFERRAL CONFIGS
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getReferralConfigs() async {
    try {
      final rows = await supabase.from('referral_configs').select();
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load referral configs: $e');
    }
  }

  Future<void> createReferralConfig({required String gameId, required double rewardAmount}) async {
    try {
      await supabase.from('referral_configs').insert({
        'game_id': gameId,
        'reward_amount': rewardAmount,
        'is_active': true,
      });
    } catch (e) {
      throw AdminException('Could not create referral config: $e');
    }
  }

  Future<void> updateReferralConfig(String id, {required double rewardAmount}) async {
    try {
      await supabase.from('referral_configs').update({'reward_amount': rewardAmount}).eq('id', id);
    } catch (e) {
      throw AdminException('Could not update referral config: $e');
    }
  }

  Future<void> setReferralConfigActive(String id, bool active) async {
    try {
      await supabase.from('referral_configs').update({'is_active': active}).eq('id', id);
    } catch (e) {
      throw AdminException('Could not update referral config: $e');
    }
  }

  Future<void> deleteReferralConfig(String id) async {
    try {
      await supabase.from('referral_configs').delete().eq('id', id);
    } catch (e) {
      throw AdminException('Could not delete referral config: $e');
    }
  }

  // ---------------------------------------------------------------
  // WITHDRAW REQUIREMENTS
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getWithdrawRequirements() async {
    try {
      final rows = await supabase.from('withdraw_requirements').select().order('created_at');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load withdraw requirements: $e');
    }
  }

  Future<void> saveWithdrawRequirement({
    String? id,
    required String gameId,
    required int adsRequired,
    required double currencyGiven,
    required double targetCurrency,
    required bool isActive,
  }) async {
    try {
      final data = {
        'game_id': gameId,
        'ads_required': adsRequired,
        'currency_given': currencyGiven,
        'target_currency': targetCurrency,
        'is_active': isActive,
      };
      if (id != null) {
        await supabase.from('withdraw_requirements').update(data).eq('id', id);
      } else {
        await supabase.from('withdraw_requirements').insert(data);
      }
    } catch (e) {
      throw AdminException('Could not save withdraw requirement: $e');
    }
  }

  Future<void> deleteWithdrawRequirement(String id) async {
    try {
      await supabase.from('withdraw_requirements').delete().eq('id', id);
    } catch (e) {
      throw AdminException('Could not delete withdraw requirement: $e');
    }
  }

  // ---------------------------------------------------------------
  // APP SETTINGS
  // ---------------------------------------------------------------
  Future<int> getDailyAdLimit() async {
    try {
      final row = await supabase.from('app_settings').select('value').eq('key', 'daily_ad_limit').maybeSingle();
      if (row == null) return 0;
      return int.tryParse(row['value'] as String? ?? '0') ?? 0;
    } catch (e) {
      throw AdminException('Could not load daily ad limit: $e');
    }
  }

  Future<void> setDailyAdLimit(int value) async {
    try {
      await supabase.from('app_settings').upsert({'key': 'daily_ad_limit', 'value': '$value'}, onConflict: 'key');
    } catch (e) {
      throw AdminException('Could not save daily ad limit: $e');
    }
  }

  // ---------------------------------------------------------------
  // DANGER ZONE
  // ---------------------------------------------------------------
  Future<void> clearAllAdWatches() async {
    try {
      await supabase.from('ad_watches').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      throw AdminException('Could not clear ad watches: $e');
    }
  }

  Future<void> clearAllBalances() async {
    try {
      await supabase.from('user_game_balances').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      throw AdminException('Could not clear balances: $e');
    }
  }

  Future<void> clearAllPayouts() async {
    try {
      await supabase.from('payout_requests').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      throw AdminException('Could not clear payouts: $e');
    }
  }

  Future<void> clearAllReferrals() async {
    try {
      await supabase.from('referrals').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      throw AdminException('Could not clear referrals: $e');
    }
  }

  Future<void> clearAllGames() async {
    try {
      await supabase.from('withdraw_requirements').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('ad_thresholds').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('referral_configs').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('games').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      throw AdminException('Could not clear games and rates: $e');
    }
  }

  Future<void> fullAppReset() async {
    await clearAllAdWatches();
    await clearAllBalances();
    await clearAllPayouts();
    await clearAllReferrals();
    await clearAllGames();
  }
}
