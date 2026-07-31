import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../services/daily_checkin_service.dart';

/// Screen — Daily Check-in
/// 30-day cycle, each day can have its own reward amount (admin
/// configurable once Supabase is wired — currently uses the local
/// default schedule in DailyCheckinService).
class DailyCheckinScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DailyCheckinScreen({super.key, required this.onBack});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  int _currentDay = 1;
  bool _claimedToday = false;
  bool _loading = true;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await DailyCheckinService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _currentDay = status.currentDay;
      _claimedToday = status.claimedToday;
      _loading = false;
    });
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    await DailyCheckinService.instance.claimToday();
    if (!mounted) return;
    setState(() => _claiming = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      GestureDetector(onTap: widget.onBack, child: const Icon(Icons.arrow_back_rounded, color: AppColors.text)),
                      const SizedBox(width: 14),
                      Text('Daily Check-In', style: AppText.heading(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Day $_currentDay of 30 — come back every day!', style: AppText.caption()),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 30,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, i) {
                      final day = i + 1;
                      final isPast = day < _currentDay;
                      final isToday = day == _currentDay;
                      final reward = DailyCheckinService.instance.rewardForDay(day);

                      Color bg;
                      Color border;
                      if (isPast) {
                        bg = AppColors.successGreen.withOpacity(0.12);
                        border = AppColors.successGreen;
                      } else if (isToday) {
                        bg = AppColors.primaryPurple.withOpacity(0.18);
                        border = AppColors.primaryPurple;
                      } else {
                        bg = AppColors.surface;
                        border = AppColors.glassBorder;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: isToday ? 1.5 : 1),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPast)
                              const Icon(Icons.check_rounded, color: AppColors.successGreen, size: 16)
                            else
                              Text('$day', style: AppText.caption(size: 11, color: isToday ? AppColors.text : AppColors.muted)),
                            Text(reward.toStringAsFixed(2), style: AppText.caption(size: 9)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      children: [
                        Text('Today\'s Reward', style: AppText.caption()),
                        const SizedBox(height: 6),
                        Text(
                          '${DailyCheckinService.instance.rewardForDay(_currentDay).toStringAsFixed(2)} 💎',
                          style: AppText.heading(size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: _claimedToday ? 'CLAIMED — COME BACK TOMORROW' : 'CLAIM TODAY\'S BONUS',
                    onPressed: _claimedToday ? null : _claim,
                    loading: _claiming,
                  ),
                ],
              ),
      ),
    );
  }
}
