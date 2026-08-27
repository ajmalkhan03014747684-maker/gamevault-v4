import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_config.dart';

enum AdLoadState { notLoaded, loading, ready, unavailable }

enum AdResult { completed, failed, cancelled }

/// Single point of contact for anything ad-related. Screens call these
/// methods and never touch the AdMob SDK directly — this is what
/// makes swapping test IDs for real ones later a one-file change
/// (see ads_config.dart) instead of a rewrite across every screen.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  AdLoadState _state = AdLoadState.notLoaded;
  AdLoadState get state => _state;

  RewardedAd? _rewardedAd;
  bool _userEarnedReward = false;

  /// TEMPORARY DIAGNOSTIC FIELD — captures the real reason the last ad
  /// load failed (AdMob error code/domain/message), so it can be shown
  /// in the UI instead of a generic "no ads available" message. Safe
  /// to remove once ads are confirmed working reliably.
  String? lastLoadError;

  /// Call this once at app startup (see main.dart) before any ad is
  /// requested.
  Future<void> init() async {
    if (!AdsConfig.useRealAds) return;
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // If init fails for any reason, ad calls below will simply fail
      // to load; handled gracefully in preloadRewardedAd().
    }
  }

  /// Call this when a screen that might show an ad first opens (e.g.
  /// Game Details). Determines whether the "WATCH REWARDED AD" button
  /// should even be shown.
  Future<void> preloadRewardedAd() async {
    _state = AdLoadState.loading;

    if (!AdsConfig.useRealAds) {
      // Simulated: pretend an ad is available after a short "load" delay.
      await Future.delayed(const Duration(milliseconds: 400));
      _state = AdLoadState.ready;
      return;
    }

    final completer = Completer<void>();

    RewardedAd.load(
      adUnitId: AdsConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _state = AdLoadState.ready;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _state = AdLoadState.unavailable;
          lastLoadError = 'code=${error.code} domain=${error.domain} message=${error.message}';
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    await completer.future;
  }

  bool get isAdReady => _state == AdLoadState.ready;

  /// Shows the ad. Only ever call this after the user has explicitly
  /// confirmed via the pre-ad disclosure dialog (reward amount must
  /// be disclosed before the ad starts). Returns the real outcome;
  /// the caller must only grant a reward on AdResult.completed.
  Future<AdResult> showRewardedAd() async {
    if (_state != AdLoadState.ready || _rewardedAd == null) {
      return AdResult.failed;
    }

    _state = AdLoadState.notLoaded; // lock immediately, prevents double-show

    if (!AdsConfig.useRealAds) {
      // Simulated ad playback.
      await Future.delayed(
        Duration(seconds: AdsConfig.simulatedAdDurationSeconds),
      );
      return AdResult.completed;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    _userEarnedReward = false;
    final showCompleter = Completer<AdResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(
            _userEarnedReward ? AdResult.completed : AdResult.cancelled,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(AdResult.failed);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // Only mark earned here — never grant the reward from a
          // click/open/show event, only from this genuine callback.
          _userEarnedReward = true;
        },
      );
    } catch (_) {
      if (!showCompleter.isCompleted) {
        showCompleter.complete(AdResult.failed);
      }
    }

    return showCompleter.future;
  }
}
