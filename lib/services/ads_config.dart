/// GameVault Ads Configuration
///
/// Wired to the real Google AdMob SDK with real production App ID and
/// ad unit ID. Note: newly created AdMob ad units can take up to an
/// hour after creation before they start actually serving ads — if
/// "no ads available" shows up right after switching to real IDs,
/// that's expected, just wait and retry.
class AdsConfig {
  AdsConfig._();

  /// Master switch. false = simulated ads (in-app fake timer, no SDK).
  /// true = real AdMob SDK calls.
  static const bool useRealAds = true;

  /// AdMob App ID — real production ID.
  static const String appId = 'ca-app-pub-4745209091204946~1801167791';

  /// Rewarded ad unit ID for the main "Watch Rewarded Ad" flow.
  /// Real production ad unit ID.
  static const String rewardedAdUnitId = 'ca-app-pub-4745209091204946/8063323819';

  /// How long the simulated ad "plays" for, in seconds.
  /// Irrelevant once useRealAds is true.
  static const int simulatedAdDurationSeconds = 4;
}
