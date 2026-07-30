import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
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

/// Full 16-screen flow controller, in-memory state for now.
/// Real Supabase wiring, Admin Panel, and real Ads Kit integration are
/// still pending — this covers the complete UI/navigation flow with
/// local/simulated data.
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
  DateTime _cooldownEndsAt = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
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
          onWatchAd: () => setState(() => _step = _Step.adWatch),
        );

      case _Step.adWatch:
        return AdWatchScreen(
          currentAds: _adsWatched,
          requiredAds: _adsRequired,
          onAdComplete: () => setState(() {
            _adsWatched += 1;
            _step = _Step.reward;
          }),
        );

      case _Step.reward:
        return RewardSuccessScreen(
          newAds: _adsWatched,
          requiredAds: _adsRequired,
          onContinue: () => setState(() {
            _cooldownEndsAt = DateTime.now().add(const Duration(minutes: 1, seconds: 15));
            _step = _Step.cooldown;
          }),
        );

      case _Step.cooldown:
        return CooldownScreen(
          cooldownEndsAt: _cooldownEndsAt,
          onPlayMiniGames: () => setState(() => _step = _Step.miniGames),
          onGoHome: () => setState(() => _step = _Step.home),
          onCooldownFinished: () => setState(() => _step = _Step.home),
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
