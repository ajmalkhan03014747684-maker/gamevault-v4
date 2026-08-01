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

  /// Submits a withdrawal request for admin review.
  Future<void> submitWithdrawRequest({
    required String gameId,
    required double amount,
    required String gameUid,
  }) async {
    final uid = _uid;
    if (uid == null) throw GameDataException('Not logged in.');
    try {
      await supabase.from('payout_requests').insert({
        'user_id': uid,
        'game_id': gameId,
        'amount': amount,
        'game_uid': gameUid,
        'status': 'pending',
      });
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
}
