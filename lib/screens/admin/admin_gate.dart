import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

/// Real admin access gate. Checks the logged-in user's role from
/// Supabase (user_profiles.role) — replaces the old HTML app's
/// hardcoded email/password check, which was a genuine security
/// issue since it lived in readable client-side JS.
///
/// This screen-level check is a convenience for UX (don't show admin
/// UI to non-admins) — the REAL security is the RLS policies on each
/// admin table, which reject writes from non-admin users regardless
/// of what the app's UI does.
class AdminGate extends StatefulWidget {
  final Widget adminContent;
  final VoidCallback onAccessDenied;

  const AdminGate({
    super.key,
    required this.adminContent,
    required this.onAccessDenied,
  });

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool _checking = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final role = await AuthService.instance.getCurrentUserRole();
    if (!mounted) return;
    if (role != 'admin') {
      widget.onAccessDenied();
      return;
    }
    setState(() {
      _isAdmin = true;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return const Scaffold(backgroundColor: AppColors.background, body: SizedBox());
    }
    return widget.adminContent;
  }
}
