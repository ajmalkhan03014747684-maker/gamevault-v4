/// GameVault Ads Configuration
///
/// THIS IS THE ONLY FILE YOU NEED TO TOUCH WHEN REAL HUAWEI ADS KIT
/// CREDENTIALS ARE READY.
///
/// Steps for that day:
/// 1. Set [useRealAds] to true
/// 2. Replace the placeholder IDs below with your real ones from
///    AppGallery Connect
/// 3. That's it — every screen already talks to AdsService, not to
///    these values directly, so nothing else needs to change.
class AdsConfig {
  AdsConfig._();

  /// Master switch. false = simulated ads (current state).
  /// true = real Huawei Ads Kit (once wired + credentials are set below).
  static const bool useRealAds = false;

  /// Your Huawei AppGallery Connect App ID.
  static const String appId = 'YOUR_HUAWEI_APP_ID_HERE';

  /// Rewarded ad slot ID for the main "Watch Rewarded Ad" flow.
  static const String rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID_HERE';

  /// How long the simulated ad "plays" for, in seconds.
  /// Irrelevant once useRealAds is true.
  static const int simulatedAdDurationSeconds = 4;
}
