import 'supabase_config.dart';
import 'auth_service.dart';

class GameDataException implements Exception {
  final String message;
  GameDataException(this.message);
  @override
  String toString() => message;
}

/// Real data layer, replacing the static placeholder numbers used
/// throughout the app so far. Wraps Supabase calls with clear error
/// messages — since some table/column names were reconstructed from
/// the old HTML file rather than a live schema, a query here failing
/// at runtime with a specific Postgrest error is expected the first
/// time; the error text will point at exactly what needs fixing.
class GameDataService {
  GameDataService._();
  static final GameDataService instance = GameDataService._();

  String? get _uid => AuthService.instance.currentUser?.id;

  /// Balance for a specific game (by game id/name — adjust the filter
  /// column below to match your real user_game_balances schema).
  Future<double> getBalance(String gameId) async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final row = await supabase
          .from('user_game_balances')
          .select('balance')
          .eq('user_id', uid)
          .eq('game_id', gameId)
          .maybeSingle();
      if (row == null) return 0;
      return (row['balance'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      throw GameDataException('Could not load balance: $e');
    }
  }

  /// Total ads watched today, across all games, for the current user.
  Future<int> getAdsWatchedToday() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final rows = await supabase
          .from('ad_watches')
          .select('id')
          .eq('user_id', uid)
          .gte('created_at', startOfDay);
      return (rows as List).length;
    } catch (e) {
      throw GameDataException('Could not load today\'s ad count: $e');
    }
  }

  /// Reads the admin-configured daily ad limit (0 = unlimited).
  /// Lives here (not just in AdminService) so any screen — not only
  /// the Admin Panel — can check it before letting a user watch
  /// another ad.
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
      return 0; // unlimited if unreadable — never blocks users on error
    }
  }

  /// True if the user has hit today's admin-configured limit.
  /// 0 limit always means unlimited.
  Future<bool> hasReachedDailyLimit() async {
    final limit = await getDailyAdLimit();
    if (limit <= 0) return false;
    final watchedToday = await getAdsWatchedToday();
    return watchedToday >= limit;
  }

  /// Ads watched for a SPECIFIC game (not global) — needed so Game
  /// Details can show real per-game progress against real thresholds,
  /// instead of a fake shared counter.
  Future<int> getAdsWatchedForGame(String gameId) async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final rows = await supabase.from('ad_watches').select('id').eq('user_id', uid).eq('game_id', gameId);
      return (rows as List).length;
    } catch (e) {
      throw GameDataException('Could not load ads watched for this game: $e');
    }
  }

  /// The next active ad_thresholds tier the user hasn't reached yet
  /// for this game — this is what makes Admin Panel's Ad Thresholds
  /// screen actually control the app instead of being disconnected
  /// from it. Returns null if no active thresholds exist for the game
  /// (caller should show a sensible fallback).
  Future<Map<String, dynamic>?> getNextThreshold(String gameId, int currentAdsForGame) async {
    try {
      final rows = await supabase
          .from('ad_thresholds')
          .select()
          .eq('game_id', gameId)
          .eq('is_active', true)
          .order('ads_required', ascending: true);
      final list = List<Map<String, dynamic>>.from(rows as List);
      for (final t in list) {
        final required = (t['ads_required'] as num?)?.toInt() ?? 0;
        if (required > currentAdsForGame) return t;
      }
      // All tiers reached, or list non-empty but none higher — return
      // the highest tier so the screen still shows something sensible
      // rather than nothing.
      return list.isNotEmpty ? list.last : null;
    } catch (e) {
      throw GameDataException('Could not load reward tiers: $e');
    }
  }


  /// Total ads watched all-time, for the current user.
  Future<int> getTotalAdsWatched() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final rows = await supabase.from('ad_watches').select('id').eq('user_id', uid);
      return (rows as List).length;
    } catch (e) {
      throw GameDataException('Could not load total ad count: $e');
    }
  }

  /// Call this when an ad finishes successfully. Logs the watch and
  /// credits the reward to the user's balance for that game.
  /// Returns the new balance.
  Future<double> recordAdWatchAndCredit({
    required String gameId,
    required double rewardAmount,
  }) async {
    final uid = _uid;
    if (uid == null) throw GameDataException('Not logged in.');

    try {
      await supabase.from('ad_watches').insert({
        'user_id': uid,
        'game_id': gameId,
      });

      final current = await getBalance(gameId);
      final newBalance = current + rewardAmount;

      await supabase.from('user_game_balances').upsert({
        'user_id': uid,
        'game_id': gameId,
        'balance': newBalance,
      });

      return newBalance;
    } catch (e) {
      throw GameDataException('Could not save ad watch / credit reward: $e');
    }
  }

  /// Submits a withdrawal request for admin review. Matches the
  /// original app's exact behavior: the balance is deducted
  /// IMMEDIATELY on request (not on approval) — if the admin rejects
  /// it, AdminService.rejectPayout refunds it back. This prevents a
  /// user from requesting the same balance twice while a request is
  /// pending.
  Future<void> submitWithdrawRequest({
    required String gameId,
    required double amount,
    required String gameUid,
    required String gameUsername,
  }) async {
    final uid = _uid;
    if (uid == null) throw GameDataException('Not logged in.');
    try {
      final currentBalance = await getBalance(gameId);
      if (currentBalance < amount) {
        throw GameDataException('Insufficient balance for this withdrawal.');
      }

      await supabase.from('user_game_balances').upsert({
        'user_id': uid,
        'game_id': gameId,
        'balance': currentBalance - amount,
      });

      await supabase.from('payout_requests').insert({
        'user_id': uid,
        'game_id': gameId,
        'amount': amount,
        'game_uid': gameUid,
        'game_username': gameUsername,
        'status': 'pending',
      });
    } on GameDataException {
      rethrow;
    } catch (e) {
      throw GameDataException('Could not submit withdrawal: $e');
    }
  }

  /// Withdrawal history for the current user.
  Future<List<Map<String, dynamic>>> getWithdrawHistory() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await supabase
          .from('payout_requests')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw GameDataException('Could not load withdrawal history: $e');
    }
  }

  /// Live leaderboard from the SQL view — ranked by ads watched today,
  /// currency as tiebreaker (see leaderboard_view in the schema).
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final rows = await supabase
          .from('leaderboard_view')
          .select()
          .order('ads_today', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw GameDataException('Could not load leaderboard: $e');
    }
  }

  /// Active games list — this is what makes Admin Panel's "Manage
  /// Games" toggle actually mean something; before this, the app used
  /// a hardcoded 6-game list that ignored is_active entirely.
  Future<List<Map<String, dynamic>>> getActiveGames() async {
    try {
      final rows = await supabase.from('games').select().eq('is_active', true).order('name');
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw GameDataException('Could not load games: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final rows = await supabase
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw GameDataException('Could not load notifications: $e');
    }
  }

  Future<Map<String, dynamic>> getReferralStats() async {
    final uid = _uid;
    if (uid == null) return {'total_referrals': 0, 'total_earned': 0.0};
    try {
      final rows = await supabase.from('referrals').select().eq('referrer_id', uid);
      final list = rows as List;
      double totalEarned = 0;
      for (final r in list) {
        totalEarned += (r['reward_amount'] as num?)?.toDouble() ?? 0;
      }
      return {'total_referrals': list.length, 'total_earned': totalEarned};
    } catch (e) {
      throw GameDataException('Could not load referral stats: $e');
    }
  }

  Future<String> getMyReferralCode() async {
    final uid = _uid;
    if (uid == null) return '';
    try {
      final row = await supabase
          .from('user_profiles')
          .select('referral_code')
          .eq('id', uid)
          .maybeSingle();
      final existing = row?['referral_code'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;

      // Generate one if this user doesn't have one yet.
      final generated = 'GAMEVAULT${uid.substring(0, 6).toUpperCase()}';
      await supabase.from('user_profiles').update({'referral_code': generated}).eq('id', uid);
      return generated;
    } catch (e) {
      throw GameDataException('Could not load referral code: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWithdrawRates(String gameId) async {
    try {
      final rows = await supabase.from('withdraw_requirements').select().eq('game_id', gameId);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      throw GameDataException('Could not load withdraw rates: $e');
    }
  }

  /// Sum of balances across all games for this user — used for Home
  /// Dashboard's "Total Balance" card, which previously showed a
  /// static "260" regardless of real data.
  Future<double> getTotalBalance() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final rows = await supabase
          .from('user_game_balances')
          .select('balance')
          .eq('user_id', uid);
      double total = 0;
      for (final row in (rows as List)) {
        total += (row['balance'] as num?)?.toDouble() ?? 0;
      }
      return total;
    } catch (e) {
      throw GameDataException('Could not load total balance: $e');
    }
  }
}
