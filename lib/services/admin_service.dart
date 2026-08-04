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
      final request = await supabase
          .from('payout_requests')
          .select()
          .eq('id', requestId)
          .single();

      await supabase
          .from('payout_requests')
          .update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      try {
        await supabase.from('notifications').insert({
          'user_id': request['user_id'],
          'type': 'payout_approved',
          'title': '✅ Payout Approved!',
          'message': 'Your withdrawal request has been approved. You will receive your reward within 12 hours.',
          'is_read': false,
        });
      } catch (_) {
        // Notifications table might not exist yet — non-fatal.
      }
    } catch (e) {
      throw AdminException('Could not approve request: $e');
    }
  }

  /// Rejecting a payout must refund the balance, because the amount
  /// was already deducted the moment the user submitted the request
  /// (see GameDataService.submitWithdrawRequest) — this matches the
  /// original app's exact behavior, which this Flutter version was
  /// missing until now.
  Future<void> rejectPayout(String requestId, String reason) async {
    try {
      final request = await supabase
          .from('payout_requests')
          .select()
          .eq('id', requestId)
          .single();

      final userId = request['user_id'] as String;
      final gameId = request['game_id'] as String;
      final amount = (request['amount'] as num?)?.toDouble() ?? 0;

      final balRow = await supabase
          .from('user_game_balances')
          .select('balance')
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .maybeSingle();
      final currentBalance = (balRow?['balance'] as num?)?.toDouble() ?? 0;

      await supabase.from('user_game_balances').upsert({
        'user_id': userId,
        'game_id': gameId,
        'balance': currentBalance + amount,
      });

      await supabase.from('payout_requests').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', requestId);

      try {
        await supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'payout_rejected',
          'title': '❌ Payout Rejected',
          'message': reason.isNotEmpty
              ? 'Your withdrawal request was rejected. Reason: $reason'
              : 'Your withdrawal request was rejected.',
          'is_read': false,
        });
      } catch (_) {
        // Notifications table might not exist yet — non-fatal.
      }
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

  // ---------------------------------------------------------------
  // GAMES CRUD (full, matching original app's exact fields)
  // ---------------------------------------------------------------
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
      final payload = {
        'name': name,
        'emoji': emoji.isEmpty ? '🎮' : emoji,
        'currency_name': currencyName,
        'currency_icon': currencyIcon.isEmpty ? '💰' : currencyIcon,
        'description': description,
        'is_active': isActive,
      };
      if (id != null) {
        await supabase.from('games').update(payload).eq('id', id);
      } else {
        await supabase.from('games').insert(payload);
      }
    } catch (e) {
      throw AdminException('Could not save game: $e');
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      // Match the original app's cascade order — related config rows
      // first, so nothing gets orphaned.
      await supabase.from('withdraw_requirements').delete().eq('game_id', gameId);
      await supabase.from('referral_configs').delete().eq('game_id', gameId);
      await supabase.from('games').delete().eq('id', gameId);
    } catch (e) {
      throw AdminException('Could not delete game: $e');
    }
  }

  // ---------------------------------------------------------------
  // REFERRAL CONFIGS CRUD
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getReferralConfigs() async {
    try {
      final rows = await supabase.from('referral_configs').select('*, games(name)');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load referral configs: $e');
    }
  }

  Future<void> saveReferralConfig({
    String? id,
    required String gameId,
    required double rewardAmount,
    required bool isActive,
  }) async {
    try {
      final payload = {'game_id': gameId, 'reward_amount': rewardAmount, 'is_active': isActive};
      if (id != null) {
        await supabase.from('referral_configs').update(payload).eq('id', id);
      } else {
        await supabase.from('referral_configs').insert(payload);
      }
    } catch (e) {
      throw AdminException('Could not save referral config: $e');
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
  // WITHDRAW REQUIREMENTS CRUD
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getWithdrawRequirements() async {
    try {
      final rows = await supabase.from('withdraw_requirements').select('*, games(name)');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load withdraw rates: $e');
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
    if (currencyGiven >= targetCurrency) {
      throw AdminException('Target must be greater than currency per cycle.');
    }
    try {
      final payload = {
        'game_id': gameId,
        'ads_required': adsRequired,
        'currency_given': currencyGiven,
        'target_currency': targetCurrency,
        'is_active': isActive,
      };
      if (id != null) {
        await supabase.from('withdraw_requirements').update(payload).eq('id', id);
      } else {
        await supabase.from('withdraw_requirements').insert(payload);
      }
    } catch (e) {
      throw AdminException('Could not save withdraw rate: $e');
    }
  }

  Future<void> deleteWithdrawRequirement(String id) async {
    try {
      await supabase.from('withdraw_requirements').delete().eq('id', id);
    } catch (e) {
      throw AdminException('Could not delete withdraw rate: $e');
    }
  }

  // ---------------------------------------------------------------
  // SETTINGS — Daily Ad Limit (app_settings key/value, matching
  // original app exactly)
  // ---------------------------------------------------------------
  Future<int> getDailyAdLimit() async {
    try {
      final row = await supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'daily_ad_limit')
          .maybeSingle();
      if (row == null) return 0;
      return int.tryParse(row['value']?.toString() ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> setDailyAdLimit(int limit) async {
    try {
      await supabase.from('app_settings').upsert(
        {'key': 'daily_ad_limit', 'value': limit.toString()},
        onConflict: 'key',
      );
    } catch (e) {
      throw AdminException('Could not save daily ad limit: $e');
    }
  }

  // ---------------------------------------------------------------
  // DANGER ZONE — matches original app's clear/reset functions
  // exactly, including the FK-safe delete order for full reset.
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
      throw AdminException('Could not clear games: $e');
    }
  }

  /// Full app reset. Deletes in FK-safe order, exactly matching the
  /// original app: payouts, referrals, balances, ad watches, withdraw
  /// requirements, ad thresholds, referral configs, games, user
  /// profiles. Keeps app_settings (ad IDs, config).
  Future<List<String>> fullAppReset() async {
    final steps = [
      'payout_requests',
      'referrals',
      'user_game_balances',
      'ad_watches',
      'withdraw_requirements',
      'ad_thresholds',
      'referral_configs',
      'games',
      'user_profiles',
    ];
    final failed = <String>[];
    for (final table in steps) {
      try {
        await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000');
      } catch (e) {
        failed.add('$table: $e');
      }
    }
    return failed;
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

  // ---------------------------------------------------------------
  // AD THRESHOLDS (per game: watch N ads -> earn X currency)
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getThresholds() async {
    try {
      final rows = await supabase.from('ad_thresholds').select().order('ads_required');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load thresholds: $e');
    }
  }

  Future<void> createThreshold({
    required String gameId,
    required int adsRequired,
    required double currencyReward,
  }) async {
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
  // REFERRAL CONFIGS (per game: 1 referral = X currency)
  // ---------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getReferralConfigs() async {
    try {
      final rows = await supabase.from('referral_configs').select();
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
  
