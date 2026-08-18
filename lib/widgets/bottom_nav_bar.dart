import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/game_data_service.dart';
import '../services/sound_service.dart';

/// Checked once per app session and cached, so the ~6 screens that all
/// show the bottom nav don't each fire their own query. Set back to
/// null on a cold app restart, which is when a fresh check happens.
Future<bool>? _referralAvailabilityCache;

class BottomNavBar extends StatefulWidget {
  final int currentIndex; // 0 Home, 1 Games, 2 Wallet, 3 Referrals, 4 Profile
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.sports_esports_rounded, 'Games'),
    (Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.group_rounded, 'Referrals'),
    (Icons.person_rounded, 'Profile'),
  ];

  bool _referralEnabled = true; // optimistic default while checking

  @override
  void initState() {
    super.initState();
    _referralAvailabilityCache ??= GameDataService.instance.hasActiveReferralReward();
    _referralAvailabilityCache!.then((enabled) {
      if (!mounted) return;
      setState(() => _referralEnabled = enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final isReferralSlot = i == 3;
          if (isReferralSlot && !_referralEnabled) {
            // Keep the slot so the remaining 4 icons don't shift
            // position, just render nothing tappable in it.
            return const SizedBox(width: 24);
          }

          final active = i == widget.currentIndex;
          final (icon, label) = _items[i];
          return GestureDetector(
            onTap: () {
              SoundService.instance.playClick();
              widget.onTap(i);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              offset: active ? const Offset(0, -0.12) : Offset.zero,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                scale: active ? 1.15 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: active ? AppColors.primaryPurple : AppColors.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppText.caption(
                        size: 11,
                        color: active ? AppColors.primaryPurple : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
