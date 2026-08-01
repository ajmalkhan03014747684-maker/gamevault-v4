import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/connection_status_service.dart';

/// Green dot = actively confirmed storing/reading data in Supabase.
/// Orange dot = not connected / write likely failing.
/// Rechecks every 15 seconds while visible.
class ConnectionStatusDot extends StatefulWidget {
  final bool showLabel;
  const ConnectionStatusDot({super.key, this.showLabel = true});

  @override
  State<ConnectionStatusDot> createState() => _ConnectionStatusDotState();
}

class _ConnectionStatusDotState extends State<ConnectionStatusDot> {
  ConnectionState _state = ConnectionState.checking;

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
      ConnectionState.connected => AppColors.successGreen,
      ConnectionState.disconnected => AppColors.secondaryOrange,
      ConnectionState.checking => AppColors.muted,
    };
    final label = switch (_state) {
      ConnectionState.connected => 'Connected to Supabase',
      ConnectionState.disconnected => 'Not connected',
      ConnectionState.checking => 'Checking...',
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
