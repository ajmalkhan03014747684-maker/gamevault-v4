import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Drop-in replacement for [RefreshIndicator] with the app's own
/// colors applied consistently, instead of every screen either using
/// the default Material blue or picking its own colors ad hoc.
class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      strokeWidth: 2.6,
      displacement: 44,
      child: child,
    );
  }
}
