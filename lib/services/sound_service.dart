import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central sound + music controller.
///
/// - One looping player for background music (started once, lives for
///   the whole app session).
/// - A separate pool of short-lived players for one-shot SFX, so an
///   effect (e.g. a coin sound) never cuts off or restarts the
///   background music.
/// - Mute state is persisted (SharedPreferences, same pattern as
///   CooldownStorage) and exposed as a ValueNotifier so any toggle UI
///   anywhere in the app stays in sync automatically.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _mutedKey = 'sound_muted';

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _musicStarted = false;
  bool _musicPausedForAd = false;

  /// True = muted. Starts optimistic (unmuted) until the persisted
  /// value loads, matching "on by default".
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  Future<void> init() async {
    // FIX (background music turning off on nav taps): audioplayers
    // defaults to requesting exclusive Android "audio focus" for every
    // player. When a short SFX (like the nav click) started, Android
    // paused the looping music player to hand focus to the SFX player
    // â€” and nothing ever told the music player to resume afterward.
    // Setting focus to "none" globally means every player in this app
    // just mixes together instead of fighting over exclusive focus.
    try {
      await AudioPlayer.global.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {
      // Non-critical â€” worst case players fall back to default focus
      // behavior, which is still better than crashing on init.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_mutedKey) ?? false;
    } catch (_) {
      // Default to unmuted (on by default) if prefs fail to load.
    }
    muted.addListener(_onMutedChanged);
  }

  Future<void> _onMutedChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutedKey, muted.value);
    } catch (_) {
      // Non-critical â€” worst case the toggle doesn't persist across
      // a full app restart.
    }

    if (muted.value) {
      await _musicPlayer.pause();
    } else if (_musicStarted && !_musicPausedForAd) {
      await _musicPlayer.resume();
    }
  }

  void toggleMuted() => muted.value = !muted.value;

  /// Starts the looping background track. Safe to call multiple times
  /// â€” only actually starts playback once per app session.
  Future<void> startBackgroundMusic() async {
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      // Belt-and-braces: set it directly on this specific player too,
      // not just as the global default, in case this player was
      // constructed before the global default was applied.
      await _musicPlayer.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.35);
      if (!muted.value) {
        await _musicPlayer.play(AssetSource('sounds/bg_music.ogg'));
      }
    } catch (_) {
      // Missing/invalid asset shouldn't crash the app â€” sound is a
      // nice-to-have, never a blocker.
    }
  }

  /// Call right before showing a rewarded ad â€” ads have their own
  /// audio, so background music ducks out while one is playing.
  Future<void> pauseForAd() async {
    _musicPausedForAd = true;
    try {
      await _musicPlayer.pause();
    } catch (_) {}
  }

  /// Call once the ad flow is done (completed OR failed/cancelled) to
  /// bring background music back, unless the user has muted it.
  Future<void> resumeAfterAd() async {
    _musicPausedForAd = false;
    if (muted.value || !_musicStarted) return;
    try {
      await _musicPlayer.resume();
    } catch (_) {}
  }

  Future<void> _playSfx(String assetFile) async {
    if (muted.value) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(0.7);
      // Auto-dispose once the clip finishes, so short SFX players
      // don't pile up in memory over a long session.
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource('sounds/$assetFile'));
    } catch (_) {
      // Missing/invalid asset â€” never let a sound effect crash the
      // actual game action it's attached to.
    }
  }

  Future<void> playClick() => _playSfx('click.ogg');
  Future<void> playAdWatch() => _playSfx('ad_watch.ogg');
  Future<void> playCoin() => _playSfx('coin.ogg');
  Future<void> playApproved() => _playSfx('approved.ogg');
  Future<void> playRejected() => _playSfx('rejected.ogg');
  Future<void> playCooldownReady() => _playSfx('cooldown_ready.ogg');
  Future<void> playMissionClaim() => _playSfx('mission_claim.ogg');
}
