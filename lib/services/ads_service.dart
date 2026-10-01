import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:applovin_max/applovin_max.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'ads_network_config_service.dart';

enum AdLoadState { notLoaded, loading, ready, unavailable }

enum AdResult { completed, failed, cancelled }

/// Single point of contact for anything ad-related. Screens call these
/// methods and never touch any ad network's SDK directly.
///
/// This runs a WATERFALL across networks configured in the admin
/// panel (see AdsNetworkConfigService / ad_network_configs table):
/// AdMob is tried first, then AppLovin, then Unity Ads. Which
/// networks are enabled and their App ID / Ad Unit ID come entirely
/// from that admin-editable table â€” no app rebuild needed to change
/// them.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  AdLoadState _state = AdLoadState.notLoaded;
  AdLoadState get state => _state;

  /// Diagnostic field â€” the real reason the last attempted network
  /// failed to load, shown in the UI's "no ads available" notice.
  String? lastLoadError;

  // Which network actually has a ready ad right now ('admob',
  // 'applovin', or 'unity'), so showRewardedAd() knows which SDK to
  // call.
  String? _readyNetwork;

  // --- AdMob state ---
  bool _admobEnabled = false;
  String? _admobAdUnitId;
  RewardedAd? _admobAd;

  // --- AppLovin state ---
  bool _applovinEnabled = false;
  bool _applovinInitialized = false;
  String? _applovinAdUnitId;
  bool _applovinListenerSet = false;
  bool _userEarnedRewardApplovin = false;
  Completer<void>? _applovinLoadCompleter;
  Completer<AdResult>? _applovinShowCompleter;

  // --- Unity Ads state ---
  bool _unityEnabled = false;
  bool _unityInitialized = false;
  String? _unityPlacementId;
  Completer<bool>? _unityLoadCompleter;
  Completer<AdResult>? _unityShowCompleter;

  /// Call this once at app startup (see main.dart) before any ad is
  /// requested. Reads which networks are enabled and their IDs from
  /// the admin-editable Supabase table.
  Future<void> init() async {
    final configs = await AdsNetworkConfigService.instance.loadConfigs();

    final admob = configs['admob'];
    if (admob != null && admob.isEnabled && admob.appId.isNotEmpty && admob.adUnitId.isNotEmpty) {
      _admobEnabled = true;
      _admobAdUnitId = admob.adUnitId;
      try {
        await MobileAds.instance.initialize();
      } catch (_) {
        // If init fails, AdMob load attempts below will simply fail
        // and the waterfall moves on.
      }
    }

    final applovin = configs['applovin'];
    if (applovin != null && applovin.isEnabled && applovin.appId.isNotEmpty && applovin.adUnitId.isNotEmpty) {
      _applovinEnabled = true;
      _applovinAdUnitId = applovin.adUnitId;
      try {
        await AppLovinMAX.initialize(applovin.appId); // appId field holds the AppLovin SDK key
        _applovinInitialized = true;
        _setupApplovinListener();
      } catch (_) {
        // If init fails, AppLovin just won't be tried in the waterfall.
      }
    }

    final unity = configs['unity'];
    if (unity != null && unity.isEnabled && unity.appId.isNotEmpty && unity.adUnitId.isNotEmpty) {
      _unityEnabled = true;
      _unityPlacementId = unity.adUnitId;
      try {
        final completer = Completer<void>();
        UnityAds.init(
          gameId: unity.appId, // appId field holds the Unity Game ID
          testMode: false,
          onComplete: () {
            _unityInitialized = true;
            if (!completer.isCompleted) completer.complete();
          },
          onFailed: (error, message) {
            if (!completer.isCompleted) completer.complete();
          },
        );
        await completer.future;
      } catch (_) {
        // If init fails, Unity Ads just won't be tried in the waterfall.
      }
    }
  }

  void _setupApplovinListener() {
    if (_applovinListenerSet) return;
    _applovinListenerSet = true;

    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
      onAdLoadedCallback: (ad) {
        if (_applovinLoadCompleter != null && !_applovinLoadCompleter!.isCompleted) {
          _applovinLoadCompleter!.complete();
        }
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        lastLoadError = 'AppLovin: code=${error.code} message=${error.message}';
        if (_applovinLoadCompleter != null && !_applovinLoadCompleter!.isCompleted) {
          _applovinLoadCompleter!.complete();
        }
      },
      onAdDisplayedCallback: (ad) {},
      onAdDisplayFailedCallback: (ad, error) {
        if (_applovinShowCompleter != null && !_applovinShowCompleter!.isCompleted) {
          _applovinShowCompleter!.complete(AdResult.failed);
        }
      },
      onAdClickedCallback: (ad) {},
      onAdHiddenCallback: (ad) {
        if (_applovinShowCompleter != null && !_applovinShowCompleter!.isCompleted) {
          _applovinShowCompleter!.complete(
            _userEarnedRewardApplovin ? AdResult.completed : AdResult.cancelled,
          );
        }
      },
      onAdReceivedRewardCallback: (ad, reward) {
        // Only mark earned here â€” never grant the reward from a
        // click/display event, only from this genuine callback.
        _userEarnedRewardApplovin = true;
      },
    ));
  }

  /// Call this when a screen that might show an ad first opens (e.g.
  /// Game Details). Tries AdMob, then AppLovin, then Unity Ads.
  /// Determines whether the "WATCH REWARDED AD" button should even
  /// be shown.
  Future<void> preloadRewardedAd() async {
    _state = AdLoadState.loading;
    _readyNetwork = null;
    lastLoadError = null;

    if (_admobEnabled) {
      final loaded = await _tryLoadAdmob();
      if (loaded) {
        _readyNetwork = 'admob';
        _state = AdLoadState.ready;
        return;
      }
    }

    if (_applovinEnabled && _applovinInitialized) {
      final loaded = await _tryLoadApplovin();
      if (loaded) {
        _readyNetwork = 'applovin';
        _state = AdLoadState.ready;
        return;
      }
    }

    if (_unityEnabled && _unityInitialized) {
      final loaded = await _tryLoadUnity();
      if (loaded) {
        _readyNetwork = 'unity';
        _state = AdLoadState.ready;
        return;
      }
    }

    _state = AdLoadState.unavailable;
  }

  Future<bool> _tryLoadAdmob() async {
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: _admobAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _admobAd = ad;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _admobAd = null;
          lastLoadError = 'AdMob: code=${error.code} domain=${error.domain} message=${error.message}';
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  Future<bool> _tryLoadApplovin() async {
    _applovinLoadCompleter = Completer<void>();
    AppLovinMAX.loadRewardedAd(_applovinAdUnitId!);
    await _applovinLoadCompleter!.future;
    final ready = await AppLovinMAX.isRewardedAdReady(_applovinAdUnitId!) ?? false;
    return ready;
  }

  Future<bool> _tryLoadUnity() async {
    _unityLoadCompleter = Completer<bool>();
    UnityAds.load(
      placementId: _unityPlacementId!,
      onComplete: (placementId) {
        if (!_unityLoadCompleter!.isCompleted) _unityLoadCompleter!.complete(true);
      },
      onFailed: (placementId, error, message) {
        lastLoadError = 'Unity: error=$error message=$message';
        if (!_unityLoadCompleter!.isCompleted) _unityLoadCompleter!.complete(false);
      },
    );
    return _unityLoadCompleter!.future;
  }

  bool get isAdReady => _state == AdLoadState.ready;

  /// Shows the ad on whichever network actually has one ready. Only
  /// ever call this after the user has explicitly confirmed via the
  /// pre-ad disclosure dialog. Returns the real outcome; the caller
  /// must only grant a reward on AdResult.completed.
  Future<AdResult> showRewardedAd() async {
    if (_state != AdLoadState.ready || _readyNetwork == null) {
      return AdResult.failed;
    }

    _state = AdLoadState.notLoaded; // lock immediately, prevents double-show
    final network = _readyNetwork!;
    _readyNetwork = null;

    switch (network) {
      case 'admob':
        return _showAdmob();
      case 'applovin':
        return _showApplovin();
      case 'unity':
        return _showUnity();
      default:
        return AdResult.failed;
    }
  }

  Future<AdResult> _showAdmob() async {
    final ad = _admobAd;
    _admobAd = null;
    if (ad == null) return AdResult.failed;

    bool userEarnedReward = false;
    final completer = Completer<AdResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(userEarnedReward ? AdResult.completed : AdResult.cancelled);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(AdResult.failed);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          userEarnedReward = true;
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(AdResult.failed);
    }

    return completer.future;
  }

  Future<AdResult> _showApplovin() async {
    _userEarnedRewardApplovin = false;
    _applovinShowCompleter = Completer<AdResult>();
    AppLovinMAX.showRewardedAd(_applovinAdUnitId!);
    return _applovinShowCompleter!.future;
  }

  Future<AdResult> _showUnity() async {
    _unityShowCompleter = Completer<AdResult>();
    UnityAds.showVideoAd(
      placementId: _unityPlacementId!,
      onStart: (placementId) {},
      onClick: (placementId) {},
      onSkipped: (placementId) {
        // Watched partway, then bailed â€” no reward for Unity's model.
        if (!_unityShowCompleter!.isCompleted) {
          _unityShowCompleter!.complete(AdResult.cancelled);
        }
      },
      onComplete: (placementId) {
        // Unity has no separate "reward earned" event â€” reaching
        // onComplete (watched fully) IS the reward signal for a
        // rewarded placement.
        if (!_unityShowCompleter!.isCompleted) {
          _unityShowCompleter!.complete(AdResult.completed);
        }
      },
      onFailed: (placementId, error, message) {
        if (!_unityShowCompleter!.isCompleted) {
          _unityShowCompleter!.complete(AdResult.failed);
        }
      },
    );
    return _unityShowCompleter!.future;
  }
}
