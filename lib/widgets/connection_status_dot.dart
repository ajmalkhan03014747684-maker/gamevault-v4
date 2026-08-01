import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/connection_status_service.dart';

/// Green dot = actively confirmed reading data from Supabase.
/// Orange dot = not connected / read likely failing.
/// Rechecks every 15 seconds while visible.
class ConnectionStatusDot extends StatefulWidget {
  final bool showLabel;
  const ConnectionStatusDot({super.key, this.showLabel = true});

  @override
  State<ConnectionStatusDot> createState() => _ConnectionStatusDotState();
}

class _ConnectionStatusDotState extends State<ConnectionStatusDot> {
  AppConnectionState _state = AppConnectionState.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final result = await ConnectionStatusService.instance.checkStatus();
    if (!mounted) return;
    setState(() => _state = result);
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) _check();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (_state) {
      AppConnectionState.connected => AppColors.successGreen,
      AppConnectionState.disconnected => AppColors.secondaryOrange,
      AppConnectionState.checking => AppColors.muted,
    };
    final label = switch (_state) {
      AppConnectionState.connected => 'Connected to Supabase',
      AppConnectionState.disconnected => 'Not connected',
      AppConnectionState.checking => 'Checking...',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 8),
          Text(label, style: AppText.caption(size: 12, color: color)),
        ],
      ],
    );
  }
}
