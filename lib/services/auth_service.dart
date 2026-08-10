import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  const AuthResult({required this.success, this.errorMessage});
}

/// Real authentication, replacing the simulated login delay.
/// Handles sign up, sign in, guest mode, and exposes the current
/// user's role (for Admin Panel access) once user_profiles.role
/// exists (added in the SQL migration).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResult> signIn({required String email, required String password}) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await supabase.auth.signUp(email: email, password: password);
      final userId = response.user?.id;
      if (userId != null) {
        // Create the matching user_profiles row. If your existing
        // schema auto-creates this via a trigger, this upsert is
        // still safe — it won't create duplicates.
        await supabase.from('user_profiles').upsert({
          'id': userId,
          'email': email,
          'username': username,
        });
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Real anonymous sign-in via Supabase Auth — replaces the old
  /// "Continue as Guest" behavior of just skipping auth entirely
  /// with no real session. Requires Anonymous sign-ins to be enabled
  /// in Supabase → Authentication → Providers (it's off by default).
  Future<AuthResult> signInAsGuest() async {
    try {
      final response = await supabase.auth.signInAnonymously();
      final userId = response.user?.id;
      if (userId != null) {
        await supabase.from('user_profiles').upsert({
          'id': userId,
          'username': 'Guest${userId.substring(0, 6)}',
        });
      }
      return const AuthResult(success: true);
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: e.message.contains('Anonymous')
            ? 'Guest login isn\'t enabled yet. Enable Anonymous sign-ins in Supabase → Authentication → Providers.'
            : e.message,
      );
    } catch (e) {
      return const AuthResult(success: false, errorMessage: 'Could not start guest session.');
    }
  }

  /// Returns 'admin' or 'user'. Defaults to 'user' if anything's
  /// missing/unreachable, so a failed lookup never accidentally
  /// grants admin access.
  Future<String> getCurrentUserRole() async {
    final uid = currentUser?.id;
    if (uid == null) return 'user';
    try {
      final row = await supabase
          .from('user_profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return row['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // ---------------------------------------------------------------
  // PROFILE — Edit Profile, Security, Language, Notifications
  // ---------------------------------------------------------------
  Future<Map<String, dynamic>> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) throw AuthServiceException('Not logged in.');
    try {
      final row = await supabase.from('user_profiles').select().eq('id', uid).single();
      return row;
    } catch (e) {
      throw AuthServiceException('Could not load profile: $e');
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final uid = currentUser?.id;
    if (uid == null) throw AuthServiceException('Not logged in.');
    try {
      await supabase.from('user_profiles').update({'username': newUsername}).eq('id', uid);
    } catch (e) {
      throw AuthServiceException('Could not update username: $e');
    }
  }

  /// Changes the account password. Supabase requires the user to have
  /// a recent session (they do, since they're already logged in) —
  /// no separate "current password" re-entry is needed by the SDK,
  /// though asking for it in the UI first is still good practice.
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthServiceException(e.message);
    } catch (e) {
      throw AuthServiceException('Could not update password: $e');
    }
  }

  Future<void> updateNotificationPrefs({required bool pushEnabled, required bool emailEnabled}) async {
    final uid = currentUser?.id;
    if (uid == null) throw AuthServiceException('Not logged in.');
    try {
      await supabase.from('user_profiles').update({
        'push_notifications_enabled': pushEnabled,
        'email_notifications_enabled': emailEnabled,
      }).eq('id', uid);
    } catch (e) {
      throw AuthServiceException('Could not update notification settings: $e');
    }
  }

  Future<void> updateLanguage(String languageCode) async {
    final uid = currentUser?.id;
    if (uid == null) throw AuthServiceException('Not logged in.');
    try {
      await supabase.from('user_profiles').update({'language': languageCode}).eq('id', uid);
    } catch (e) {
      throw AuthServiceException('Could not update language: $e');
    }
  }
}

class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);
  @override
  String toString() => message;
}
