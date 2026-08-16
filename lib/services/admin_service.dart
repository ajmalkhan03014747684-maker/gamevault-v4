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
/// checked by the calling screen â€” the REAL security is the RLS
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

  /// All payout requests (any status), newest first, with the user's
  /// username and the game's name/currency embedded â€” needed to show
  /// a readable admin list and to compose notification messages.
  Future<List<Map<String, dynamic>>> getAllPayouts() async {
    try {
      final rows = await supabase
          .from('payout_requests')
          .select('*, user:user_id(username,email), game:game_id(name,currency_name,emoji)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load payout requests: $e');
    }
  }

  /// Kept for any screen that only wants pending ones.
  Future<List<Map<String, dynamic>>> getPendingPayouts() async {
    try {
      final rows = await supabase
          .from('payout_requests')
          .select('*, user:user_id(username,email), game:game_id(name,currency_name,emoji)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw AdminException('Could not load payout requests: $e');
    }
  }

  /// Approves a payout AND sends the user a permanent notification.
  /// Balance was already deducted when the user submitted the
  /// withdrawal request (see GameDataService.submitCycleWithdraw), so
  /// nothing further needs deducting here â€” only the status change and
  /// the notification.
  Future<void> approvePayout(String requestId) async {
    try {
      final request = await supabase
          .from('payout_requests')
          .select('*, user:user_id(username,email), game:game_id(name,currency_name)')
          .eq('id', requestId)
          .single();

      if (request['status'] != 'pending') {
        throw AdminException('This request was already processed.');
      }

      await supabase.from('payout_requests').update({
        'status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      final username = (request['user']?['username'] as String?) ??
          (request['user']?['email'] as String?) ??
          'User';
      final gameName = (request['game']?['name'] as String?) ?? 'the game';
      final currency = (request['game']?['currency_name'] as String?) ?? '';
      final amount = (request['amount'] as num?)?.toStringAsFixed(2) ?? '0';
      final gameUsername = (request['game_username'] as String?) ?? '';
      final gameUid = (request['game_uid'] as String?) ?? 'N/A';

      final message =
          'Dear $username, your withdrawal request of $amount $currency for $gameName '
          '(Username: $gameUsername, UID: $gameUid) has been approved. '
          'You will receive your $currency within 12 hours. Thank you!';

      try {
        await supabase.from('notifications').insert({
          'user_id': request['user_id'],
          'type': 'payout_approved',
          'title': 'âœ… Payout Approved!',
          'message': message,
          'payout_id': requestId,
          'is_read': false,
        });
      } catch (_) {
        // Approval already succeeded â€” don't fail the whole action
        // just because the notification insert had a problem.
      }
    } on AdminException {
      rethrow;
    } catch (e) {
      throw AdminException('Could not approve request: $e');
    }
  }

  /// Rejects a payout request, REFUNDS the balance that was deducted
  /// when the user submitted it (their ad-cycle progress stays reset
  /// though â€” only the currency comes back), and sends a permanent
  /// notification that includes the reason.
  Future<void> rejectPayout(String requestId, String reason) async {
    try {
      final request = await supabase
          .from('payout_requests')
          .select('*, user:user_id(username,email), game:game_id(name,currency_name)')
          .eq('id', requestId)
          .single();

      if (request['status'] != 'pending') {
        throw AdminException('This request was already processed.');
      }

      final userId = request['user_id'] as String;
      final gameId = request['game_id'] as String;
      final amount = (request['amount'] as num).toDouble();

      final balanceRow = await supabase
          .from('user_game_balances')
          .select('balance')
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .maybeSingle();
      final currentBalance = (balanceRow?['balance'] as num?)?.toDouble() ?? 0;

      // FIX: without onConflict, Supabase checks the row's own `id`
      // for conflicts instead of the actual unique key (user_id,
      // game_id), so an existing balance row is never recognized and
      // the upsert fails with a duplicate-key error.
      await supabase.from('user_game_balances').upsert({
        'user_id': userId,
        'game_id': gameId,
        'balance': currentBalance + amount,
      }, onConflict: 'user_id,game_id');

      await supabase.from('payout_requests').update({
        'status': 'rejected',
        'rejection_reason': reason,
      }).eq('id', requestId);

      final username = (request['user']?['username'] as String?) ??
          (request['user']?['email'] as String?) ??
          'User';
      final gameName = (request['game']?['name'] as String?) ?? 'the game';
      final currency = (request['game']?['currency_name'] as String?) ?? '';
      final amountStr = amount.toStringAsFixed(2);
      final reasonText = reason.trim().isNotEmpty ? reason.trim() : 'No reason was provided.';

      final message =
          'Dear $username, your withdrawal request of $amountStr $currency for $gameName '
          'has been rejected. Reason: $reasonText. Your $amountStr $currency has been '
          'refunded to your balance.';

      try {
        await supabase.from('notifications').insert({
          'user_id': userId,
          'type': 'payout_rejected',
          'title': 'âŒ Payout Rejected',
          'message': message,
          'payout_id': requestId,
          'is_read': false,
        });
      } catch (_) {
        // Rejection + refund already succeeded â€” don't fail the whole
        // action just because the notification insert had a problem.
      }
    } on AdminException {
      rethrow;
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

  /// The app's existing currency system is per-game (games.currency_name).
  /// This returns the distinct currency names currently in use, so the
  /// Check-In Schedule editor can offer a picker instead of free text.
  Future<List<String>> getCurrencyOptions() async {
    try {
      final rows = await supabase.from('games').select('currency_name');
      final names = (rows as List)
          .map((r) => (r['currency_name'] as String?)?.trim() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      names.sort();
      return names;
    } catch (e) {
      throw AdminException('Could not load currency options: $e');
    }
  }

  /// FIX: now also writes currency_id (the column already existed in
  /// the schema â€” it just wasn't being set from the UI before).
  Future<void> updateCheckinDay(int dayNumber, double rewardAmount, String currencyId) async {
    try {
      await supabase.from('daily_checkin_schedule').update({
        'reward_amount': rewardAmount,
        'currency_id': currencyId,
      }).eq('day_number', dayNumber);
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
    String goalType = 'ads_watched',
  }) async {
    try {
      await supabase.from('missions').insert({
        'title': title,
        'period': period,
        'goal_type': goalType,
        'goal_count': goalCount,
        'reward_amount': rewardAmount,
        'is_active': true,
      });
    } catch (e) {
      throw AdminException('Could not create mission: $e');
    }
  }

  /// Full edit support for an existing mission â€” previously missing;
  /// admins could only toggle active/inactive or delete, not correct
  /// a typo or adjust a goal/reward without deleting and recreating.
  Future<void> updateMission(
    String missionId, {
    required String title,
    required String period,
    required int goalCount,
    required double rewardAmount,
    required String goalType,
  }) async {
    try {
      await supabase.from('missions').update({
        'title': title,
        'period': period,
        'goal_type': goalType,
        'goal_count': goalCount,
        'reward_amount': rewardAmount,
      }).eq('id', missionId);
    } catch (e) {
      throw AdminException('Could not update mission: $e');
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
