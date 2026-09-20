import 'supabase_config.dart';

class AdNetworkConfig {
  final String networkName;
  final String appId; // AdMob App ID, or AppLovin SDK Key
  final String adUnitId;
  final bool isEnabled;

  const AdNetworkConfig({
    required this.networkName,
    required this.appId,
    required this.adUnitId,
    required this.isEnabled,
  });

  factory AdNetworkConfig.fromRow(Map<String, dynamic> row) {
    return AdNetworkConfig(
      networkName: row['network_name'] as String,
      appId: (row['app_id'] as String?) ?? '',
      adUnitId: (row['ad_unit_id'] as String?) ?? '',
      isEnabled: (row['is_enabled'] as bool?) ?? false,
    );
  }
}

/// Loads and saves ad network settings (AdMob, AppLovin) from a single
/// Supabase table, so the admin panel can change them without needing
/// a new app build. AdsService reads this once at startup.
class AdsNetworkConfigService {
  AdsNetworkConfigService._();
  static final AdsNetworkConfigService instance = AdsNetworkConfigService._();

  Future<Map<String, AdNetworkConfig>> loadConfigs() async {
    try {
      final rows = await supabase.from('ad_network_configs').select();
      final map = <String, AdNetworkConfig>{};
      for (final row in rows as List) {
        final config = AdNetworkConfig.fromRow(row as Map<String, dynamic>);
        map[config.networkName] = config;
      }
      return map;
    } catch (_) {
      // If this fails (e.g. no network at startup), AdsService simply
      // won't have any networks enabled — no ads shown, no crash.
      return {};
    }
  }

  Future<void> saveConfig({
    required String networkName,
    required String appId,
    required String adUnitId,
    required bool isEnabled,
  }) async {
    await supabase.from('ad_network_configs').upsert({
      'network_name': networkName,
      'app_id': appId,
      'ad_unit_id': adUnitId,
      'is_enabled': isEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
