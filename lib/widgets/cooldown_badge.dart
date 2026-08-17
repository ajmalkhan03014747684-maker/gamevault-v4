import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/cooldown_storage.dart';

/// Small compact "â± 01:08" badge shown in a screen's header while an
/// ad cooldown is active â€” renders nothing when there isn't one.
///
/// Fully self-contained: each instance polls CooldownStorage on its
/// own every second, so it can be dropped into any screen's header
/// with zero extra wiring and will always agree with every other
/// instance elsewhere in the app, since they all read the same
/// persisted deadline.
class CooldownBadge extends StatefulWidget {
  const CooldownBadge({super.key});

  @override
  State<CooldownBadge> createState() => _CooldownBadgeState();
}

class _CooldownBadgeState extends State<CooldownBadge> {
  Timer? _timer;
  int? _secondsLeft;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    final end = await CooldownStorage.getCooldownEnd();
    if (!mounted) return;
    if (end == null) {
      if (_secondsLeft != null) setState(() => _secondsLeft = null);
      return;
    }
    final diff = end.difference(DateTime.now()).inSeconds;
    setState(() => _secondsLeft = diff > 0 ? diff : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _secondsLeft;
    if (seconds == null) return const SizedBox.shrink();

    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.primaryPurple),
          const SizedBox(width: 5),
          Text('$m:$s', style: AppText.caption(size: 12, color: AppColors.primaryPurple)),
        ],
      ),
    );
  }
}
