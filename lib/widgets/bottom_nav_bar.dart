import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex; // 0 Home, 1 Games, 2 Wallet, 3 Referrals, 4 Profile
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.sports_esports_rounded, 'Games'),
    (Icons.account_balance_wallet_rounded, 'Wallet'),
    (Icons.group_rounded, 'Referrals'),
    (Icons.person_rounded, 'Profile'),
  ];

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
          final active = i == currentIndex;
          final (icon, label) = _items[i];
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
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
          );
        }),
      ),
    );
  }
}
