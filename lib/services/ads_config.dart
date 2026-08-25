/// GameVault Ads Configuration
///
/// THIS IS THE ONLY FILE YOU NEED TO TOUCH WHEN REAL HUAWEI ADS KIT
/// CREDENTIALS ARE READY.
///
/// Current state: wired to the real Huawei Ads Kit SDK, but pointed at
/// Huawei's official PUBLIC TEST ad slot ID. Test ads are unlimited,
/// free, and safe to click — they never pay out and never risk your
/// account. This lets us verify the whole load/show/reward flow works
/// end-to-end before Petal Ads Publisher Service issues real IDs.
///
/// Steps for the day real ad unit IDs exist (after AppGallery
/// publishing + Petal Ads Publisher Service approval):
/// 1. Replace [rewardedAdUnitId] below with your real slot ID from
///    Petal Publisher Center.
/// 2. That's it — every screen already talks to AdsService, not to
///    this value directly, so nothing else needs to change.
class AdsConfig {
  AdsConfig._();

  /// Master switch. false = simulated ads (in-app fake timer, no SDK).
  /// true = real Huawei Ads Kit SDK calls (currently using Huawei's
  /// public test slot ID below — safe to leave true during development).
  static const bool useRealAds = true;

  /// AppGallery Connect App ID for this app (from agconnect-services.json).
  /// Shown for reference in the admin panel only — not used by the SDK
  /// directly (the SDK reads agconnect-services.json itself).
  static const String appId = '118739351';

  /// Rewarded ad slot ID for the main "Watch Rewarded Ad" flow.
  ///
  /// This is Huawei's official public test slot ID for rewarded video
  /// ads (documented at developer.huawei.com and safe to ship during
  /// testing). Replace with your real slot ID once Petal Ads
  /// Publisher Service approves the app post-publishing.
  static const String rewardedAdUnitId = 'testx9dtjwj8hp';

  /// How long the simulated ad "plays" for, in seconds.
  /// Irrelevant once useRealAds is true.
  static const int simulatedAdDurationSeconds = 4;
}
