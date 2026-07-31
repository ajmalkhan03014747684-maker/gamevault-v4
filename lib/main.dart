import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/cooldown_storage.dart';
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

void main() {
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

/// Full 16-screen flow controller.
/// Cooldown is now persisted via CooldownStorage (survives navigating
/// away, backgrounding, or fully closing the app) — fixes the bug where
/// leaving Cooldown and tapping "WATCH REWARDED AD" again skipped the
/// wait entirely.
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
}

class _RootFlowState extends State<RootFlow> {
  _Step _step = _Step.splash;
  GameInfo _selectedGame = kGames.first;
  int _adsWatched = 42;
  final int _adsRequired = 60;

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
  /// Checks the PERSISTED cooldown first — this is the actual fix.
  /// If a cooldown is still active, route to the Cooldown screen
  /// instead of letting them watch another ad.
  Future<void> _handleWatchAdRequested() async {
    final activeCooldown = await CooldownStorage.getCooldownEnd();
    if (activeCooldown != null) {
      if (!mounted) return;
      setState(() => _step = _Step.cooldown);
      return;
    }
    if (!mounted) return;
    setState(() => _step = _Step.adWatch);
  }

  /// Where the hardware/gesture back button should send the user for
  /// each step — mirrors each screen's own back arrow, so Android's
  /// system back button never dumps the user out to their phone's home
  /// screen while still inside the app flow.
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
        setState(() => _step = _Step.home);
        break;
      case _Step.withdraw:
      case _Step.withdrawHistory:
        setState(() => _step = _Step.wallet);
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
      child: _buildCurrentScreen(),
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
          onNotificationsTapped: () => setState(() => _step = _Step.notifications),
          onMiniGamesTapped: () => setState(() => _step = _Step.miniGames),
        );

      case _Step.selectGame:
        return SelectGameScreen(
          activeGameName: _selectedGame.name,
          onBack: () => setState(() => _step = _Step.home),
          onGameSelected: (g) => setState(() {
            _selectedGame = g;
            _step = _Step.gameDetails;
          }),
        );

      case _Step.gameDetails:
        return GameDetailsScreen(
          game: _selectedGame,
          adsWatched: _adsWatched,
          adsRequired: _adsRequired,
          onBack: () => setState(() => _step = _Step.selectGame),
          onWatchAd: _handleWatchAdRequested,
        );

      case _Step.adWatch:
        return AdWatchScreen(
          currentAds: _adsWatched,
          requiredAds: _adsRequired,
          onAdComplete: () => setState(() {
            _adsWatched += 1;
            _step = _Step.reward;
          }),
          onAdFailed: () => setState(() => _step = _Step.gameDetails),
        );

      case _Step.reward:
        return RewardSuccessScreen(
          newAds: _adsWatched,
          requiredAds: _adsRequired,
          onContinue: () async {
            final end = DateTime.now().add(const Duration(minutes: 1, seconds: 15));
            await CooldownStorage.setCooldownEnd(end);
            if (!mounted) return;
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
        return ProfileScreen(onNavTap: _goToNavTab);

      case _Step.wallet:
        return WalletScreen(
          onNavTap: _goToNavTab,
          onHistoryTapped: () => setState(() => _step = _Step.withdrawHistory),
        );

      case _Step.withdraw:
        return WithdrawScreen(
          game: _selectedGame,
          balance: 260,
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
    }
  }
}
