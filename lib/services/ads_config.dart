/// GameVault Ads Configuration
///
/// THIS IS THE ONLY FILE YOU NEED TO TOUCH WHEN REAL ADMOB
/// CREDENTIALS ARE READY.
///
/// Current state: wired to the real Google AdMob SDK, but pointed at
/// Google's official PUBLIC TEST App ID and ad unit ID. Test ads are
/// unlimited, free, and safe to click — they never pay out and never
/// risk your AdMob account. This lets us verify the whole
/// load/show/reward flow works end-to-end before your real AdMob app
/// finishes its readiness review (which requires linking to a
/// supported store — see the Amazon Appstore listing plan).
///
/// Steps for the day your real AdMob App ID + ad unit ID exist:
/// 1. Replace [admobAppId] below with your real App ID
///    (format: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY) — this also
///    needs to be updated in the Android manifest injection step in
///    the GitHub Actions workflow (search for APPLICATION_ID there).
/// 2. Replace [rewardedAdUnitId] with your real ad unit ID
///    (format: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ).
/// 3. That's it — every screen already talks to AdsService, not to
///    this value directly, so nothing else needs to change.
class AdsConfig {
  AdsConfig._();

  /// Master switch. false = simulated ads (in-app fake timer, no SDK).
  /// true = real AdMob SDK calls (currently using Google's public
  /// test IDs below — safe to leave true during development).
  static const bool useRealAds = true;

  /// AdMob App ID. This is Google's official public TEST App ID —
  /// safe to ship during development. Must also be updated in the
  /// AndroidManifest.xml injection step in the build workflow.
  static const String appId = 'ca-app-pub-3940256099942544~3347511713';

  /// Rewarded ad unit ID for the main "Watch Rewarded Ad" flow.
  ///
  /// This is Google's official public test ad unit ID for rewarded
  /// video ads (documented at developers.google.com/admob and safe to
  /// ship during testing). Replace with your real ad unit ID once
  /// your AdMob app passes its readiness review.
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// How long the simulated ad "plays" for, in seconds.
  /// Irrelevant once useRealAds is true.
  static const int simulatedAdDurationSeconds = 4;
}
