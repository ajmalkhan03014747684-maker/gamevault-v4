import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cosmic_particles_background.dart';

/// Screen 8 — Cooldown Screen
/// Deadline is persisted by the caller (CooldownStorage) so the
/// countdown survives navigating away or closing the app entirely.
/// Now includes floating background particles for the "waiting" mood.
class CooldownScreen extends StatefulWidget {
  final DateTime cooldownEndsAt;
  final VoidCallback onPlayMiniGames;
  final VoidCallback onGoHome;
  final VoidCallback onCooldownFinished;

  const CooldownScreen({
    super.key,
    required this.cooldownEndsAt,
    required this.onPlayMiniGames,
    required this.onGoHome,
    required this.onCooldownFinished,
  });

  @override
  State<CooldownScreen> createState() => _CooldownScreenState();
}

class _CooldownScreenState extends State<CooldownScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _remaining;

  late final AnimationController _ringController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _remaining = widget.cooldownEndsAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = widget.cooldownEndsAt.difference(DateTime.now());
      if (rem.isNegative || rem == Duration.zero) {
        _timer.cancel();
        widget.onCooldownFinished();
      } else {
        setState(() => _remaining = rem);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CosmicParticlesBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text('Next Ad Available In', style: AppText.heading(size: 20)),
                const SizedBox(height: 28),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _ringController,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(colors: [
                              AppColors.primaryPurple,
                              AppColors.secondaryOrange,
                              AppColors.primaryPurple,
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.4),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 148,
                        height: 148,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$minutes:$seconds', style: AppText.heading(size: 28)),
                          Text('Minutes  Seconds', style: AppText.caption(size: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Play mini games or explore the app while you wait.',
                  textAlign: TextAlign.center,
                  style: AppText.caption(size: 13),
                ),
                const Spacer(flex: 2),
                GradientButton(
                  label: 'PLAY MINI GAMES',
                  icon: Icons.play_arrow_rounded,
                  onPressed: widget.onPlayMiniGames,
                ),
                const SizedBox(height: 12),
                OutlineButton(label: 'Go to Home', onPressed: widget.onGoHome),
                const SizedBox(height: 16),
                Text(
                  'Cooldown helps keep the app fair for everyone!',
                  textAlign: TextAlign.center,
                  style: AppText.caption(size: 11),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
