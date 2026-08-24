import 'dart:async';
import 'package:huawei_ads/hms_ads_lib.dart';
import 'ads_config.dart';

enum AdLoadState { notLoaded, loading, ready, unavailable }

enum AdResult { completed, failed, cancelled }

/// Single point of contact for anything ad-related. Screens call these
/// methods and never touch the Huawei SDK directly — this is what
/// makes swapping test IDs for real ones later a one-file change
/// (see ads_config.dart) instead of a rewrite across every screen.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  AdLoadState _state = AdLoadState.notLoaded;
  AdLoadState get state => _state;

  RewardAd? _rewardAd;
  Completer<AdResult>? _showCompleter;
  bool _userEarnedReward = false;

  /// Call this once at app startup (see main.dart) before any ad is
  /// requested.
  Future<void> init() async {
    if (!AdsConfig.useRealAds) return;
    try {
      await HwAds.init();
    } catch (_) {
      // If HMS Core isn't available on this device (non-Huawei phone),
      // ad calls below will simply fail to load; we handle that
      // gracefully in preloadRewardedAd().
    }
  }

  /// Call this when a screen that might show an ad first opens (e.g.
  /// Game Details). Determines whether the "WATCH REWARDED AD" button
  /// should even be shown, per Huawei's policy requirement that no
  /// button/message appears if no ad is available.
  Future<void> preloadRewardedAd() async {
    _state = AdLoadState.loading;

    if (!AdsConfig.useRealAds) {
      // Simulated: pretend an ad is available after a short "load" delay.
      await Future.delayed(const Duration(milliseconds: 400));
      _state = AdLoadState.ready;
      return;
    }

    final completer = Completer<void>();
    _userEarnedReward = false;

    _rewardAd = RewardAd(
      listener: (RewardAdEvent event, {Reward? reward, int? errorCode}) {
        switch (event) {
          case RewardAdEvent.loaded:
            _state = AdLoadState.ready;
            if (!completer.isCompleted) completer.complete();
            break;
          case RewardAdEvent.failed:
            _state = AdLoadState.unavailable;
            if (!completer.isCompleted) completer.complete();
            if (_showCompleter != null && !_showCompleter!.isCompleted) {
              _showCompleter!.complete(AdResult.failed);
            }
            break;
          case RewardAdEvent.rewarded:
            // Only mark earned here — never grant the reward from a
            // click/open/show event, only from this genuine callback.
            _userEarnedReward = true;
            break;
          case RewardAdEvent.closed:
            if (_showCompleter != null && !_showCompleter!.isCompleted) {
              _showCompleter!.complete(
                _userEarnedReward ? AdResult.completed : AdResult.cancelled,
              );
            }
            break;
          default:
            break;
        }
      },
    );

    try {
      await _rewardAd!.loadAd(
        adSlotId: AdsConfig.rewardedAdUnitId,
        adParam: AdParam(),
      );
    } catch (_) {
      _state = AdLoadState.unavailable;
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future;
  }

  bool get isAdReady => _state == AdLoadState.ready;

  /// Shows the ad. Only ever call this after the user has explicitly
  /// confirmed via the pre-ad disclosure dialog (Huawei policy
  /// requirement — reward amount must be disclosed before the ad
  /// starts). Returns the real outcome; the caller must only grant a
  /// reward on AdResult.completed.
  Future<AdResult> showRewardedAd() async {
    if (_state != AdLoadState.ready) {
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

    _showCompleter = Completer<AdResult>();
    try {
      await _rewardAd!.show();
    } catch (_) {
      if (!_showCompleter!.isCompleted) {
        _showCompleter!.complete(AdResult.failed);
      }
    }

    final result = await _showCompleter!.future;
    _rewardAd?.destroy();
    _rewardAd = null;
    return result;
  }
}
