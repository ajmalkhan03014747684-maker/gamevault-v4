import 'dart:async';
import 'ads_config.dart';

enum AdLoadState { notLoaded, loading, ready, unavailable }

enum AdResult { completed, failed, cancelled }

/// Single point of contact for anything ad-related. Screens call these
/// methods and never touch a Timer or an SDK directly — this is what
/// makes swapping in real Huawei Ads Kit later a one-file change
/// instead of a rewrite across every screen.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  AdLoadState _state = AdLoadState.notLoaded;
  AdLoadState get state => _state;

  /// Call this when a screen that might show an ad first opens (e.g.
  /// Game Details). Determines whether the "WATCH REWARDED AD" button
  /// should even be shown, per Huawei's policy requirement that no
  /// button/message appears if no ad is available.
  Future<void> preloadRewardedAd() async {
    _state = AdLoadState.loading;

    if (AdsConfig.useRealAds) {
      // TODO once real Ads Kit is wired: call the HMS SDK's ad-loading
      // method here, and set _state based on its actual callback
      // (ready vs. unavailable). Do not grant rewards from this method.
      throw UnimplementedError(
        'Real Ads Kit not wired yet. Set AdsConfig.useRealAds = true '
        'only after implementing the real SDK calls here.',
      );
    }

    // Simulated: pretend an ad is available after a short "load" delay.
    await Future.delayed(const Duration(milliseconds: 400));
    _state = AdLoadState.ready;
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

    if (AdsConfig.useRealAds) {
      // TODO once real Ads Kit is wired: call the HMS SDK's show method,
      // and return AdResult.completed ONLY from its genuine
      // "video watched fully" callback — never on ad click, ad shown,
      // or any partial-watch event.
      throw UnimplementedError('Real Ads Kit not wired yet.');
    }

    // Simulated ad playback.
    await Future.delayed(
      Duration(seconds: AdsConfig.simulatedAdDurationSeconds),
    );
    return AdResult.completed;
  }
}
