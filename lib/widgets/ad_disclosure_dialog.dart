import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// Huawei Ads Kit policy requires users be told, BEFORE the ad starts,
/// that they only receive the reward after watching the complete video.
/// Call this and only proceed to AdsService.showRewardedAd() if it
/// returns true.
Future<bool> showAdDisclosureDialog(
  BuildContext context, {
  required String rewardText,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryPurple, size: 44),
            const SizedBox(height: 16),
            Text(
              'You\'ll receive $rewardText after watching this ad completely.',
              textAlign: TextAlign.center,
              style: AppText.body(size: 15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Watch Now',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            OutlineButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Shown in place of the "WATCH REWARDED AD" button when no ad is
/// currently available — per Huawei policy, no button/message should
/// invite a tap when there's nothing to show.
class NoAdAvailableNotice extends StatelessWidget {
  final String? debugDetail;
  const NoAdAvailableNotice({super.key, this.debugDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No ads available right now — check back soon',
            style: AppText.caption(size: 13),
            textAlign: TextAlign.center,
          ),
          if (debugDetail != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                debugDetail!,
                style: AppText.caption(size: 10, color: AppColors.dangerRed),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
