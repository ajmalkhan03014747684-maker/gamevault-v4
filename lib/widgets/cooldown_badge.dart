import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';
import '../services/cooldown_storage.dart';

/// Lightweight global "please open the Cooldown screen" signal.
///
/// CooldownBadge is dropped into ~7 different screens with zero
/// constructor wiring by design (see its own docs). Rather than thread
/// an onTap callback through every one of those screens' constructors
/// just for this, tapping the badge pings this shared notifier and
/// RootFlow (in main.dart) listens for it once, centrally, and
/// navigates. Nothing here is persisted â€” it's purely an in-memory
/// tap signal for this session.
class CooldownNav {
  CooldownNav._();
  static final ValueNotifier<int> tapSignal = ValueNotifier<int>(0);
  static void requestOpen() => tapSignal.value++;
}

/// Small compact "â± 01:08" badge shown in a screen's header while an
/// ad cooldown is active â€” renders nothing when there isn't one.
///
/// - Animated: pulses a soft glow continuously while counting down
///   (mirrors the reference app's livePulse treatment).
/// - Clickable: tapping it opens the full Cooldown screen, with a
///   quick press-scale for tactile feedback and a light haptic tick.
///
/// Fully self-contained for display: each instance polls
/// CooldownStorage on its own every second, so it can be dropped into
/// any screen's header with zero extra wiring and will always agree
/// with every other instance elsewhere in the app.
class CooldownBadge extends StatefulWidget {
  const CooldownBadge({super.key});

  @override
  State<CooldownBadge> createState() => _CooldownBadgeState();
}

class _CooldownBadgeState extends State<CooldownBadge> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int? _secondsLeft;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 0.08,
  );

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
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    CooldownNav.requestOpen();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _secondsLeft;
    if (seconds == null) return const SizedBox.shrink();

    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _pressController]),
        builder: (context, child) {
          final glow = 0.3 + (_pulseController.value * 0.35);
          final scale = 1 - _pressController.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(glow),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 13, color: AppColors.primaryPurple),
                  const SizedBox(width: 5),
                  Text('$m:$s', style: AppText.caption(size: 12, color: AppColors.primaryPurple)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
