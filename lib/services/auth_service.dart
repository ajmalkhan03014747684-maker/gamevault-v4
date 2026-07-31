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
}
