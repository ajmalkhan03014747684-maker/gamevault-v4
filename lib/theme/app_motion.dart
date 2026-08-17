import 'package:flutter/material.dart';

/// Shared animation timing, mirroring the reference app's CSS timing
/// where it applies, so the two feel like the same product.
class AppMotion {
  AppMotion._();

  // Reference: cubic-bezier(.34,1.56,.64,1) â€” used for popIn/bounceIn/
  // card presses, an overshoot curve that gives a springy "pop" feel.
  static const Cubic springy = Cubic(0.34, 1.56, 0.64, 1);

  // Reference: cubic-bezier(.34,1.2,.64,1) â€” used for slideUp/progress
  // fills/modals, a gentler overshoot for larger movements.
  static const Cubic smooth = Cubic(0.34, 1.2, 0.64, 1);

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  // Reference: countGlow 3s ease infinite
  static const Duration glowCycle = Duration(seconds: 3);

  // Reference: coinFall .9s
  static const Duration coinFall = Duration(milliseconds: 900);

  // Reference: rewardPop .6s cubic-bezier(.34,1.56,.64,1)
  static const Duration rewardPop = Duration(milliseconds: 600);
}
