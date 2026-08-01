import 'supabase_config.dart';

/// Renamed from ConnectionState to avoid colliding with Flutter's
/// built-in ConnectionState (used internally by FutureBuilder /
/// StreamBuilder, exported via package:flutter/material.dart) — that
/// collision was the actual build error, not a logic problem.
enum AppConnectionState { connected, disconnected, checking }

/// Actively verifies Supabase is reachable AND that reads actually
/// succeed — not just "the client object exists". A green dot should
/// mean "data is really being stored," matching what the HTML app's
/// indicator meant.
class ConnectionStatusService {
  ConnectionStatusService._();
  static final ConnectionStatusService instance = ConnectionStatusService._();

  Future<AppConnectionState> checkStatus() async {
    try {
      await supabase.from('user_profiles').select('id').limit(1);
      return AppConnectionState.connected;
    } catch (e) {
      return AppConnectionState.disconnected;
    }
  }
}
