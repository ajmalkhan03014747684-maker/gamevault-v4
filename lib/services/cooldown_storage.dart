import 'package:shared_preferences/shared_preferences.dart';

/// Persists the ad cooldown deadline so it survives navigating away,
/// backgrounding, or fully closing and reopening the app. This is what
/// was missing before — the cooldown only lived in memory, so leaving
/// the screen and coming back let users skip it entirely.
class CooldownStorage {
  CooldownStorage._();
  static const _key = 'ad_cooldown_ends_at';

  /// Returns the persisted deadline, or null if there is no active
  /// cooldown (either never set, or already expired — expired ones are
  /// cleared automatically on read).
  static Future<DateTime?> getCooldownEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) return null;

    final end = DateTime.tryParse(stored);
    if (end == null) return null;

    if (DateTime.now().isAfter(end)) {
      await prefs.remove(_key);
      return null;
    }
    return end;
  }

  static Future<void> setCooldownEnd(DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, end.toIso8601String());
  }

  static Future<void> clearCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
