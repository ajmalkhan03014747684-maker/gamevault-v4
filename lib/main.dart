import 'dart:async';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/cooldown_storage.dart';
import 'services/supabase_config.dart';
import 'services/game_data_service.dart';
import 'screens/01_splash_screen.dart';
import 'screens/02_login_register.dart';
import 'screens/03_home_dashboard.dart';
import 'screens/04_select_game.dart';
import 'screens/05_game_details.dart';
import 'screens/06_ad_watch_screen.dart';
import 'screens/07_reward_success.dart';
import 'screens/08_cooldown_screen.dart';
import 'screens/09_mini_games.dart';
import 'screens/10_profile.dart';
import 'screens/11_wallet.dart';
import 'screens/12_withdraw.dart';
import 'screens/13_withdraw_history.dart';
import 'screens/14_referral.dart';
import 'screens/15_leaderboard.dart';
import 'screens/16_notifications.dart';
import 'screens/18_missions.dart';
import 'screens/admin/admin_gate.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_payouts_screen.dart';
import 'screens/admin/admin_games_screen.dart';
import 'screens/admin/admin_missions_screen.dart';
import 'screens/admin/admin_antibot_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_referral_configs_screen.dart';
import 'screens/admin/admin_withdraw_req_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/security_screen.dart';
import 'screens/profile/language_screen.dart';
import 'screens/profile/notification_settings_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/admin_danger_zone_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const GameVaultApp());
}

class GameVaultApp extends StatelessWidget {
  const GameVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameVault',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootFlow(),
    );
  }
}

/// Full screen flow controller.
///
/// FIX: Daily Check-in removed entirely (per product decision â€” the
/// feature and its admin screen are gone, not just hidden).
/// FIX: `_availableGames` cache removed â€” Select Game / Games section
/// now fetches its own live list (see 04_select_game.dart), so there's
/// nothing to keep in sync here anymore.
/// FIX: every place that used to pass a game's display NAME as its
/// database id now passes `game.id` instead.
class RootFlow extends StatefulWidget {
  const RootFlow({super.key});

  @override
  State<RootFlow> createState() => _RootFlowState();
}

enum _Step {
  splash,
  login,
  home,
  selectGame,
  gameDetails,
  adWatch,
  reward,
  cooldown,
  miniGames,
  profile,
  wallet,
  withdraw,
  withdrawHistory,
  referral,
  leaderboard,
  notifications,
  missions,
  adminDashboard,
  adminPayouts,
  adminGames,
  adminMissions,
  adminAntiBot,
  adminUsers,
  adminSettings,
  adminDangerZone,
  adminReferralConfigs,
  adminWithdrawReq,
  editProfile,
  security,
  language,
  notificationSettings,
}

class _RootFlowState extends State<RootFlow> {
  _Step _step = _Step.splash;
  GameInfo? _selectedGame;
  // Transient â€” filled in by Game Details with REAL per-game data
  // right before handing off to the ad flow. No fake shared counter.
  int _pendingCurrentAds = 0;
  int _pendingAdsRequired = 0;
  double _pendingRewardAmount = 0;
  bool _pendingCycleCompleted = false;
  double _pendingEarned = 0;

  // ---------------------------------------------------------------
  // PAYOUT NOTIFICATION BANNER
  // Polls for a new (unread) payout_approved / payout_rejected
  // notification while the app is open, shows a banner for 10
  // seconds, then auto-dismisses. The notification itself is NOT
  // marked read by the banner â€” it stays in the Notifications screen
  // permanently until the user actually opens it there.
  // ---------------------------------------------------------------
  Timer? _pollTimer;
  Timer? _bannerAutoHideTimer;
  Map<String, dynamic>? _activeBanner;
  final Set<String> _bannerShownIds = {};

  // Ad-cooldown-ended detector â€” separate from the small display
  // badges (which just read storage independently); this one is the
  // single source that fires the one-time "ad ready" banner and
  // clears the stored deadline once it passes.
  Timer? _cooldownTicker;
  bool _cooldownEndBannerFired = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollForPayoutNotification());
    // Also check shortly after the app opens, in case something was
    // already waiting from before this session.
    Future.delayed(const Duration(seconds: 3), _pollForPayoutNotification);

    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) => _tickCooldown());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _bannerAutoHideTimer?.cancel();
    _cooldownTicker?.cancel();
    super.dispose();
  }

  Future<void> _tickCooldown() async {
    if (!mounted) return;
    final end = await CooldownStorage.getCooldownEnd();
    if (!mounted) return;

    if (end == null) {
      // No active cooldown â€” reset the fired-flag so the NEXT
      // cooldown (started by watching another ad) gets its own banner.
      _cooldownEndBannerFired = false;
      return;
    }

    final secondsLeft = end.difference(DateTime.now()).inSeconds;
    if (secondsLeft > 0) return; // still counting down, nothing to do

    if (_cooldownEndBannerFired) return; // already announced this one
    _cooldownEndBannerFired = true;

    await CooldownStorage.clearCooldown();
    if (!mounted) return;
    _showEphemeralBanner(
      type: 'cooldown_ready',
      title: 'ðŸ”” Ready for your next ad!',
      message: 'Your cooldown has ended â€” go watch an ad to earn more.',
      duration: const Duration(seconds: 10),
    );
  }

  Future<void> _pollForPayoutNotification() async {
    if (!mounted) return;
    // Don't poll before the user is logged in.
    if (_step == _Step.splash || _step == _Step.login) return;

    final notif = await GameDataService.instance.getLatestUnreadPayoutNotification();
    if (!mounted || notif == null) return;

    final id = notif['id']?.toString();
    if (id == null || _bannerShownIds.contains(id)) return;

    _bannerShownIds.add(id);
    _bannerAutoHideTimer?.cancel();
    setState(() => _activeBanner = notif);
    _bannerAutoHideTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _activeBanner = null);
    });
  }

  void _dismissBanner() {
    _bannerAutoHideTimer?.cancel();
    setState(() => _activeBanner = null);
  }

  void _goToNavTab(int i) {
    switch (i) {
      case 0:
        setState(() => _step = _Step.home);
        break;
      case 1:
        setState(() => _step = _Step.selectGame);
        break;
      case 2:
        setState(() => _step = _Step.wallet);
        break;
      case 3:
        setState(() => _step = _Step.referral);
        break;
      case 4:
        setState(() => _step = _Step.profile);
        break;
    }
  }

  /// Called when the user taps "WATCH REWARDED AD" on Game Details.
  /// Restored: routes to the full-screen Cooldown screen when a
  /// cooldown is still active, same as before. The small CooldownBadge
  /// in every header still shows the countdown everywhere else.
  Future<void> _handleWatchAdRequested(int currentAds, int adsRequired, double rewardAmount) async {
    final activeCooldown = await CooldownStorage.getCooldownEnd();
    if (activeCooldown != null) {
      if (!mounted) return;
      setState(() => _step = _Step.cooldown);
      return;
    }
    if (!mounted) return;
    setState(() {
      _pendingCurrentAds = currentAds;
      _pendingAdsRequired = adsRequired;
      _pendingRewardAmount = rewardAmount;
      _step = _Step.adWatch;
    });
  }

  /// Shows a transient top banner that auto-dismisses after [duration]
  /// â€” used for both the cooldown-active tap warning and the
  /// cooldown-just-ended notice. Nothing here is written to the
  /// database; it only ever lives in memory for this session.
  void _showEphemeralBanner({
    required String type,
    required String title,
    required String message,
    required Duration duration,
  }) {
    _bannerAutoHideTimer?.cancel();
    setState(() {
      _activeBanner = {'id': null, 'type': type, 'title': title, 'message': message};
    });
    _bannerAutoHideTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _activeBanner = null);
    });
  }

  /// Where the hardware/gesture back button should send the user for
  /// each step.
  void _goBack() {
    switch (_step) {
      case _Step.selectGame:
        setState(() => _step = _Step.home);
        break;
      case _Step.gameDetails:
        setState(() => _step = _Step.selectGame);
        break;
      case _Step.adWatch:
        setState(() => _step = _Step.gameDetails);
        break;
      case _Step.reward:
      case _Step.cooldown:
      case _Step.miniGames:
      case _Step.profile:
      case _Step.wallet:
      case _Step.referral:
      case _Step.leaderboard:
      case _Step.notifications:
      case _Step.missions:
        setState(() => _step = _Step.home);
        break;
      case _Step.withdraw:
      case _Step.withdrawHistory:
        setState(() => _step = _Step.wallet);
        break;
      case _Step.adminPayouts:
      case _Step.adminGames:
      case _Step.adminMissions:
      case _Step.adminAntiBot:
      case _Step.adminUsers:
      case _Step.adminSettings:
      case _Step.adminDangerZone:
      case _Step.adminReferralConfigs:
      case _Step.adminWithdrawReq:
        setState(() => _step = _Step.adminDashboard);
        break;
      case _Step.editProfile:
      case _Step.security:
      case _Step.language:
      case _Step.notificationSettings:
        setState(() => _step = _Step.profile);
        break;
      case _Step.adminDashboard:
        setState(() => _step = _Step.profile);
        break;
      case _Step.splash:
      case _Step.login:
      case _Step.home:
        break;
    }
  }

  bool get _isRootStep =>
      _step == _Step.splash || _step == _Step.login || _step == _Step.home;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isRootStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Stack(
        children: [
          _buildCurrentScreen(),
          if (_activeBanner != null) _buildPayoutBanner(_activeBanner!),
        ],
      ),
    );
  }

  Widget _buildPayoutBanner(Map<String, dynamic> notif) {
    final isApproved = notif['type'] == 'payout_approved';
    final isCooldownReady = notif['type'] == 'cooldown_ready';
    final title = (notif['title'] as String?) ?? (isApproved ? 'âœ… Payout Approved!' : 'âŒ Payout Update');
    final message = (notif['message'] as String?) ?? '';
    final color = isCooldownReady
        ? AppColors.gold
        : isApproved
            ? AppColors.successGreen
            : AppColors.dangerRed;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, spreadRadius: 1)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.body(size: 14, weight: FontWeight.w700, color: color)),
                      const SizedBox(height: 4),
                      Text(message, style: AppText.caption(size: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismissBanner,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_step) {
      case _Step.splash:
        return SplashScreen(onFinished: () => setState(() => _step = _Step.login));

      case _Step.login:
        return LoginRegisterScreen(
          onLoginSuccess: () => setState(() => _step = _Step.home),
        );

      case _Step.home:
        return HomeDashboardScreen(
          onNavTap: _goToNavTab,
          onSelectGameTapped: () => setState(() => _step = _Step.selectGame),
          onGameRowTapped: (g) => setState(() {
            _selectedGame = g;
            _step = _Step.gameDetails;
          }),
          onNotificationsTapped: () => setState(() => _step = _Step.notifications),
          onMiniGamesTapped: () => setState(() => _step = _Step.miniGames),
          onMissionsTapped: () => setState(() => _step = _Step.missions),
          onLeaderboardTapped: () => setState(() => _step = _Step.leaderboard),
        );

      case _Step.selectGame:
        return SelectGameScreen(
          activeGameName: _selectedGame?.name ?? '',
          onBack: () => setState(() => _step = _Step.home),
          onGameSelected: (g) => setState(() {
            _selectedGame = g;
            _step = _Step.gameDetails;
          }),
        );

      case _Step.gameDetails:
        return GameDetailsScreen(
          game: _selectedGame!,
          onBack: () => setState(() => _step = _Step.selectGame),
          onWatchAd: _handleWatchAdRequested,
        );

      case _Step.adWatch:
        return AdWatchScreen(
          currentAds: _pendingCurrentAds,
          requiredAds: _pendingAdsRequired,
          gameId: _selectedGame!.id,
          rewardAmount: _pendingRewardAmount,
          onAdComplete: (cycleCompleted, earned) => setState(() {
            _pendingCurrentAds += 1;
            _pendingCycleCompleted = cycleCompleted;
            _pendingEarned = earned;
            _step = _Step.reward;
          }),
          onAdFailed: () => setState(() => _step = _Step.gameDetails),
        );

      case _Step.reward:
        return RewardSuccessScreen(
          newAds: _pendingCurrentAds,
          requiredAds: _pendingAdsRequired,
          cycleCompleted: _pendingCycleCompleted,
          earned: _pendingEarned,
          currency: _selectedGame?.currency ?? '',
          onContinue: () async {
            final end = DateTime.now().add(const Duration(minutes: 1, seconds: 15));
            await CooldownStorage.setCooldownEnd(end);
            _cooldownEndBannerFired = false;
            if (!mounted) return;
            // Restored: routes to the full-screen Cooldown screen,
            // same as before. If the user leaves it early (Mini Games
            // / Go to Home), the small CooldownBadge + the global
            // ticker in _tickCooldown still track it and fire the
            // "ready" banner the moment it ends.
            setState(() => _step = _Step.cooldown);
          },
        );

      case _Step.cooldown:
        return FutureBuilder<DateTime?>(
          future: CooldownStorage.getCooldownEnd(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final end = snapshot.data ?? DateTime.now();
            return CooldownScreen(
              cooldownEndsAt: end,
              onPlayMiniGames: () => setState(() => _step = _Step.miniGames),
              onGoHome: () => setState(() => _step = _Step.home),
              onCooldownFinished: () async {
                await CooldownStorage.clearCooldown();
                if (!mounted) return;
                setState(() => _step = _Step.home);
              },
            );
          },
        );

      case _Step.miniGames:
        return MiniGamesHubScreen(
          onBack: () => setState(() => _step = _Step.home),
        );

      case _Step.profile:
        return ProfileScreen(
          onNavTap: _goToNavTab,
          onAdminTapped: () => setState(() => _step = _Step.adminDashboard),
          onEditProfileTapped: () => setState(() => _step = _Step.editProfile),
          onSecurityTapped: () => setState(() => _step = _Step.security),
          onNotificationsTapped: () => setState(() => _step = _Step.notificationSettings),
          onLanguageTapped: () => setState(() => _step = _Step.language),
        );

      case _Step.wallet:
        return WalletScreen(
          onNavTap: _goToNavTab,
          onHistoryTapped: () => setState(() => _step = _Step.withdrawHistory),
          onWithdrawTapped: (g) => setState(() {
            _selectedGame = g;
            _step = _Step.withdraw;
          }),
        );

      case _Step.withdraw:
        return WithdrawScreen(
          game: _selectedGame!,
          onSubmitted: () => setState(() => _step = _Step.withdrawHistory),
        );

      case _Step.withdrawHistory:
        return WithdrawHistoryScreen(
          onBack: () => setState(() => _step = _Step.wallet),
        );

      case _Step.referral:
        return ReferralScreen(onNavTap: _goToNavTab);

      case _Step.leaderboard:
        return LeaderboardScreen(
          onBack: () => setState(() => _step = _Step.home),
        );

      case _Step.notifications:
        return NotificationsScreen(
          onBack: () => setState(() => _step = _Step.home),
        );

      case _Step.missions:
        return MissionsScreen(
          onBack: () => setState(() => _step = _Step.home),
        );

      case _Step.adminDashboard:
        return AdminGate(
          onAccessDenied: () => setState(() => _step = _Step.home),
          adminContent: AdminDashboardScreen(
            onExit: () => setState(() => _step = _Step.profile),
            onPayoutsTapped: () => setState(() => _step = _Step.adminPayouts),
            onGamesTapped: () => setState(() => _step = _Step.adminGames),
            onMissionsTapped: () => setState(() => _step = _Step.adminMissions),
            onAntiBotTapped: () => setState(() => _step = _Step.adminAntiBot),
            onUsersTapped: () => setState(() => _step = _Step.adminUsers),
            onSettingsTapped: () => setState(() => _step = _Step.adminSettings),
            onDangerZoneTapped: () => setState(() => _step = _Step.adminDangerZone),
            onReferralConfigsTapped: () => setState(() => _step = _Step.adminReferralConfigs),
            onWithdrawReqTapped: () => setState(() => _step = _Step.adminWithdrawReq),
          ),
        );

      case _Step.adminPayouts:
        return AdminPayoutsScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminGames:
        return AdminGamesScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminMissions:
        return AdminMissionsScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminAntiBot:
        return AdminAntiBotScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminUsers:
        return AdminUsersScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminSettings:
        return AdminSettingsScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminDangerZone:
        return AdminDangerZoneScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminReferralConfigs:
        return AdminReferralConfigsScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.adminWithdrawReq:
        return AdminWithdrawReqScreen(
          onBack: () => setState(() => _step = _Step.adminDashboard),
        );

      case _Step.editProfile:
        return EditProfileScreen(
          onBack: () => setState(() => _step = _Step.profile),
        );

      case _Step.security:
        return SecurityScreen(
          onBack: () => setState(() => _step = _Step.profile),
        );

      case _Step.language:
        return LanguageScreen(
          onBack: () => setState(() => _step = _Step.profile),
        );

      case _Step.notificationSettings:
        return NotificationSettingsScreen(
          onBack: () => setState(() => _step = _Step.profile),
        );
    }
  }
}
