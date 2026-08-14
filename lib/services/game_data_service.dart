import 'supabase_config.dart';
import 'auth_service.dart';

class GameDataException implements Exception {
  final String message;
  GameDataException(this.message);
  @override
  String toString() => message;
}

/// Real data layer for Supabase-backed app state.
///
/// FIX: ad_watches' real timestamp column is `watched_at`, not
/// `created_at` (confirmed against the live schema) â€” every query
/// that used to reference `created_at` on this table now uses
/// `watched_at`, and every insert now sets it explicitly so a
/// record is never missing a timestamp regardless of the column's
/// database default.
class GameDataService {
  GameDataService._();
  static final GameDataService instance = GameDataService._();

  String? get _uid => AuthService.instance.currentUser?.id;

  /// Balance for a specific game (by game id).
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
          .gte('watched_at', startOfDay);
      return (rows as List).length;
    } catch (e) {
      throw GameDataException('Could not load today\'s ad count: $e');
    }
  }

  /// Reads the admin-configured daily ad limit (0 = unlimited).
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
      return 0; // unlimited if unreadable â€” never blocks users on error
    }
  }

  /// True if the user has hit today's admin-configured limit.
  Future<bool> hasReachedDailyLimit() async {
    final limit = await getDailyAdLimit();
    if (limit <= 0) return false;
    final watchedToday = await getAdsWatchedToday();
    return watchedToday >= limit;
  }

  /// Ads watched for a SPECIFIC game (not global).
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

  /// The next active ad_thresholds tier the user hasn't reached yet.
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

  /// Call this when an ad finishes successfully. Logs the watch (with
  /// an explicit watched_at timestamp) and credits the reward to the
  /// user's balance for that game. Returns the new balance.
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
        'watched_at': DateTime.now().toIso8601String(),
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

  /// Submits a withdrawal request for admin review.
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

  /// Live leaderboard from the SQL view.
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

  /// Active games list.
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

  /// FIX: referrals' real reward column is `reward_paid`, not
  /// `reward_amount` â€” the old code silently read a nonexistent
  /// field and always summed to 0.
  Future<Map<String, dynamic>> getReferralStats() async {
    final uid = _uid;
    if (uid == null) return {'total_referrals': 0, 'total_earned': 0.0};
    try {
      final rows = await supabase.from('referrals').select().eq('referrer_id', uid);
      final list = rows as List;
      double totalEarned = 0;
      for (final r in list) {
        totalEarned += (r['reward_paid'] as num?)?.toDouble() ?? 0;
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

  /// Sum of balances across all games for this user.
  /// Kept for any screen that still wants a single aggregate number,
  /// but the Wallet/Profile screens now show per-game currency
  /// instead (a single sum across different in-game currencies never
  /// meant anything real).
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

  /// One balance row per active game, each carrying that game's own
  /// currency name/icon â€” this is what "Total Balance" gets replaced
  /// with everywhere: a per-currency breakdown instead of one number
  /// that mixed unrelated in-game currencies together.
  Future<List<Map<String, dynamic>>> getAllGameBalances() async {
    final uid = _uid;
    try {
      final games = await supabase.from('games').select().eq('is_active', true).order('name');
      final result = <Map<String, dynamic>>[];
      for (final g in (games as List)) {
        final gameId = g['id'].toString();
        double balance = 0;
        if (uid != null) {
          final row = await supabase
              .from('user_game_balances')
              .select('balance')
              .eq('user_id', uid)
              .eq('game_id', gameId)
              .maybeSingle();
          balance = (row?['balance'] as num?)?.toDouble() ?? 0;
        }
        result.add({
          'id': gameId,
          'name': g['name'],
          'currency_name': g['currency_name'],
          'currency_icon': g['currency_icon'],
          'balance': balance,
        });
      }
      return result;
    } catch (e) {
      throw GameDataException('Could not load wallet balances: $e');
    }
  }

  /// True only if the admin has at least one ACTIVE referral config
  /// with a reward greater than zero. Used to hide the Referral tab
  /// and any referral entry points app-wide when there's genuinely
  /// nothing to earn â€” fails closed (hides) if the check itself
  /// errors, since showing a broken/empty referral program is worse
  /// than not showing one.
  Future<bool> hasActiveReferralReward() async {
    try {
      final rows = await supabase.from('referral_configs').select('reward_amount').eq('is_active', true);
      for (final r in (rows as List)) {
        final amount = (r['reward_amount'] as num?)?.toDouble() ?? 0;
        if (amount > 0) return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
