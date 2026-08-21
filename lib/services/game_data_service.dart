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
/// `created_at` (confirmed against the live schema) Ã¢â‚¬â€ every query
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
      return 0; // unlimited if unreadable Ã¢â‚¬â€ never blocks users on error
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

  /// Call this when an ad finishes successfully. Logs the watch,
  /// increments the game's running ad count, and Ã¢â‚¬â€ matching the
  /// reference app exactly Ã¢â‚¬â€ auto-credits the cycle reward the moment
  /// total ads watched for this game hits a multiple of the admin's
  /// configured "ads per cycle". No manual claim step: crediting is
  /// automatic and repeats every cycle for as long as the user keeps
  /// watching ads.
  ///
  /// FIX: this used to insert ad_watches and credit currency directly
  /// from the client, in three separate calls. Now it's a single RPC
  /// to record_ad_watch() Ã¢â‚¬â€ a server-side function that runs the
  /// anti-bot checks (watched-too-fast, impossible frequency, repeated
  /// identical timing) BEFORE crediting anything. Doing this
  /// server-side (not in this Dart method) is deliberate: a modified
  /// client could otherwise just skip past client-side checks
  /// entirely, since a bot is exactly the kind of client that would.
  ///
  /// [adDurationMs] is how long the ad actually took, measured by the
  /// caller from when it started to when it completed.
  ///
  /// Returns info the UI can use for a toast/message: whether this ad
  /// completed a cycle, how much was earned, and whether a first-strike
  /// warning should be shown (the credit still goes through on a first
  /// strike Ã¢â‚¬â€ see the SQL function for the two-strike policy).
  Future<Map<String, dynamic>> recordAdWatch({
    required String gameId,
    required int adDurationMs,
  }) async {
    final uid = _uid;
    if (uid == null) throw GameDataException('Not logged in.');

    try {
      final result = await supabase.rpc('record_ad_watch', params: {
        'p_game_id': gameId,
        'p_ad_duration_ms': adDurationMs,
      });

      final data = Map<String, dynamic>.from(result as Map);

      if (data['success'] != true) {
        final error = data['error'] as String?;
        if (error == 'banned') {
          throw GameDataException(
              'Your account has been banned for repeated suspicious activity.');
        }
        if (error == 'account_banned') {
          throw GameDataException('Your account is banned.');
        }
        throw GameDataException('Could not record ad watch.');
      }

      return {
        'cycle_completed': data['cycle_completed'] == true,
        'earned': (data['earned'] as num?)?.toDouble() ?? 0,
        'new_ads': (data['new_ads'] as num?)?.toInt() ?? 0,
        'new_balance': (data['new_balance'] as num?)?.toDouble() ?? 0,
        'warning': data['warning'] == true,
      };
    } on GameDataException {
      rethrow;
    } catch (e) {
      throw GameDataException('Could not save ad watch: $e');
    }
  }

  /// The active withdraw-rate / cycle config for a game Ã¢â‚¬â€ one row in
  /// withdraw_requirements doubles as BOTH the withdraw rate AND the
  /// ad-watch cycle config (ads_required = ads per cycle,
  /// currency_given = currency per cycle, target_currency = the cap
  /// shown on the auto-calculated schedule).
  Future<Map<String, dynamic>?> getCycleConfig(String gameId) async {
    try {
      final rows = await supabase
          .from('withdraw_requirements')
          .select()
          .eq('game_id', gameId)
          .eq('is_active', true)
          .order('ads_required', ascending: true)
          .limit(1);
      final list = rows as List;
      return list.isNotEmpty ? Map<String, dynamic>.from(list.first as Map) : null;
    } catch (e) {
      throw GameDataException('Could not load withdraw rate: $e');
    }
  }

  /// Generates the full cumulative milestone schedule from a cycle
  /// config: cycle 1 = adsPerCycle ads / currencyPerCycle currency,
  /// cycle 2 = 2Ãƒâ€”/2Ãƒâ€”, and so on Ã¢â‚¬â€ capped at `target` on the final row.
  List<Map<String, num>> calcSchedule(int adsPerCycle, double currencyPerCycle, double target) {
    final rows = <Map<String, num>>[];
    if (adsPerCycle <= 0 || currencyPerCycle <= 0 || target <= 0) return rows;
    int totalAds = 0;
    double totalCurrency = 0;
    while (totalCurrency < target) {
      totalAds += adsPerCycle;
      totalCurrency += currencyPerCycle;
      if (totalCurrency > target) totalCurrency = target;
      rows.add({'ads': totalAds, 'currency': totalCurrency});
      if (totalCurrency >= target) break;
    }
    return rows;
  }

  /// Everything the Withdraw Rates / Payout screen needs in one call:
  /// current balance & ad count, the config, the full schedule, and
  /// which milestone the user is currently eligible to withdraw up to.
  Future<Map<String, dynamic>> getWithdrawEligibility(String gameId) async {
    final uid = _uid;
    try {
      final config = await getCycleConfig(gameId);

      double balance = 0;
      int totalAdsWatched = 0;
      if (uid != null) {
        final row = await supabase
            .from('user_game_balances')
            .select('balance, total_ads_watched')
            .eq('user_id', uid)
            .eq('game_id', gameId)
            .maybeSingle();
        balance = (row?['balance'] as num?)?.toDouble() ?? 0;
        totalAdsWatched = (row?['total_ads_watched'] as num?)?.toInt() ?? 0;
      }

      if (config == null) {
        return {
          'has_config': false,
          'balance': balance,
          'total_ads_watched': totalAdsWatched,
          'schedule': <Map<String, num>>[],
        };
      }

      final adsPerCycle = (config['ads_required'] as num?)?.toInt() ?? 0;
      final currencyPerCycle = (config['currency_given'] as num?)?.toDouble() ?? 0;
      final target = (config['target_currency'] as num?)?.toDouble() ?? 0;
      final schedule = calcSchedule(adsPerCycle, currencyPerCycle, target);

      final completed = schedule.where((s) => totalAdsWatched >= s['ads']!).toList();
      final nextRow = schedule.firstWhere(
        (s) => totalAdsWatched < s['ads']!,
        orElse: () => <String, num>{},
      );

      final cyclePos = adsPerCycle > 0 ? totalAdsWatched % adsPerCycle : 0;
      final adsLeftInCycle = adsPerCycle > 0 ? adsPerCycle - cyclePos : 0;

      return {
        'has_config': true,
        'ads_per_cycle': adsPerCycle,
        'currency_per_cycle': currencyPerCycle,
        'target_currency': target,
        'balance': balance,
        'total_ads_watched': totalAdsWatched,
        'cycle_pos': cyclePos,
        'ads_left_in_cycle': adsLeftInCycle,
        'schedule': schedule,
        'cycles_done': completed.length,
        'total_cycles': schedule.length,
        'next_row': nextRow,
        // Eligibility to WITHDRAW is just "do you have any balance" Ã¢â‚¬â€
        // ad-watch progress (the schedule above) is a separate,
        // purely informational lifetime tracker. It used to gate
        // withdrawals too, back when a withdrawal reset the whole
        // cycle; now that withdrawals only deduct what's withdrawn,
        // there's no reason to tie the two together.
        'eligible': balance > 0,
      };
    } catch (e) {
      throw GameDataException('Could not load withdraw eligibility: $e');
    }
  }

  /// Submits a real-world payout request for PART or ALL of the
  /// user's balance:
  /// - balance is reduced by exactly the withdrawn amount (a partial
  ///   withdrawal keeps the remainder)
  /// - the ad-watch cycle ALWAYS resets to zero on any withdrawal,
  ///   regardless of the amount Ã¢â‚¬â€ so the user starts back at cycle #1
  ///   and has to watch ads again to earn more, even if they only
  ///   withdrew part of their balance.
  Future<void> submitCycleWithdraw({
    required String gameId,
    required double amount,
    required String gameUid,
    required String gameUsername,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) throw GameDataException('Not logged in.');
    if (amount <= 0) throw GameDataException('Enter a valid amount.');
    if (gameUsername.trim().isEmpty) throw GameDataException('Enter your in-game username.');
    if (gameUid.trim().isEmpty) throw GameDataException('Enter your in-game UID.');

    try {
      final eligibility = await getWithdrawEligibility(gameId);
      final balance = eligibility['balance'] as double;
      if (amount > balance) throw GameDataException('Insufficient balance.');

      String cycleInfo = '';
      if (eligibility['has_config'] == true) {
        final cyclesDone = eligibility['cycles_done'] as int;
        final totalCycles = eligibility['total_cycles'] as int;
        final totalAds = eligibility['total_ads_watched'] as int;
        cycleInfo = 'Cycles: $cyclesDone/$totalCycles | Ads: $totalAds';
      }

      await supabase.from('payout_requests').insert({
        'user_id': uid,
        'game_id': gameId,
        'amount': amount,
        'game_username': gameUsername.trim(),
        'game_uid': gameUid.trim(),
        'note': [if (note != null && note.trim().isNotEmpty) note.trim(), cycleInfo]
            .where((s) => s.isNotEmpty)
            .join(' | '),
        'status': 'pending',
      });

      // Balance: only the withdrawn amount is deducted (partial
      // withdrawals keep the rest). Ad cycle: always resets to 0, so
      // the next reward requires watching ads again from cycle #1 Ã¢â‚¬â€
      // this happens on every withdrawal, not just full ones.
      await supabase.from('user_game_balances').upsert({
        'user_id': uid,
        'game_id': gameId,
        'balance': balance - amount,
        'total_ads_watched': 0,
      }, onConflict: 'user_id,game_id');
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
          .select('*, game:game_id(name,currency_name,emoji)')
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

  /// Marks every unread notification as read Ã¢â‚¬â€ call this once the
  /// user has actually opened the Notifications screen.
  Future<void> markAllNotificationsRead() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await supabase.from('notifications').update({'is_read': true}).eq('user_id', uid).eq('is_read', false);
    } catch (_) {
      // Non-critical Ã¢â‚¬â€ the list will just show them as unread a bit
      // longer if this fails.
    }
  }

  /// How many notifications are currently unread Ã¢â‚¬â€ drives the bell
  /// badge on Home.
  Future<int> getUnreadNotificationCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final rows = await supabase.from('notifications').select('id').eq('user_id', uid).eq('is_read', false);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// The most recent unread payout notification (approved/rejected) Ã¢â‚¬â€
  /// used to trigger the auto-dismissing popup banner. Does NOT mark
  /// it read; it stays unread (and in the bell) until the user opens
  /// Notifications, matching how a normal notification inbox works.
  Future<Map<String, dynamic>?> getLatestUnreadPayoutNotification() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final rows = await supabase
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(20);
      final list = List<Map<String, dynamic>>.from(rows as List);
      for (final row in list) {
        final type = row['type'] as String?;
        if (type == 'payout_approved' || type == 'payout_rejected') return row;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// FIX: referrals' real reward column is `reward_paid`, not
  /// `reward_amount` Ã¢â‚¬â€ the old code silently read a nonexistent
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
  /// currency name/icon Ã¢â‚¬â€ this is what "Total Balance" gets replaced
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
  /// nothing to earn Ã¢â‚¬â€ fails closed (hides) if the check itself
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
