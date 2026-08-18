import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

/// Speaker icon that toggles SoundService.muted on tap. Self-contained
/// â€” reads the shared ValueNotifier directly, so every instance of
/// this widget anywhere in the app always agrees.
class SoundToggle extends StatelessWidget {
  final double size;
  const SoundToggle({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundService.instance.muted,
      builder: (context, isMuted, _) {
        return GestureDetector(
          onTap: SoundService.instance.toggleMuted,
          child: Icon(
            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: isMuted ? AppColors.muted : AppColors.text,
            size: size,
          ),
        );
      },
    );
  }
}

/// A full settings-style row version, for Profile â€” icon, label, and a
/// Switch, matching the look of the other menu rows on that screen.
class SoundToggleRow extends StatelessWidget {
  const SoundToggleRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundService.instance.muted,
      builder: (context, isMuted, _) {
        return Row(
          children: [
            Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('Sound & Music', style: AppText.body(size: 14, weight: FontWeight.w600))),
            Switch(
              value: !isMuted,
              activeColor: AppColors.primaryPurple,
              onChanged: (_) => SoundService.instance.toggleMuted(),
            ),
          ],
        );
      },
    );
  }
}
