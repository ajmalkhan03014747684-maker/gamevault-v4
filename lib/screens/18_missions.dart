import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../services/missions_service.dart';

/// Screen — Missions
/// Shows daily, weekly, and monthly missions with live progress and a
/// claim button once complete. Progress tracking is local for now;
/// once Supabase is wired, incrementProgress() calls move server-side
/// so progress is consistent across devices too.
class MissionsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MissionsScreen({super.key, required this.onBack});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  List<MissionProgress> _progress = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MissionsService.instance.getAllProgress();
      if (!mounted) return;
      setState(() {
        _progress = data;
        _loading = false;
      });
    } on MissionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _claim(String missionId) async {
    try {
      final credited = await MissionsService.instance.claim(missionId);
      if (!mounted) return;
      if (credited > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('+${credited.toStringAsFixed(2)} claimed!', style: AppText.body(color: Colors.white))),
        );
      }
      await _load();
    } on MissionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _periodLabel(MissionPeriod p) {
    switch (p) {
      case MissionPeriod.daily:
        return 'DAILY';
      case MissionPeriod.weekly:
        return 'WEEKLY';
      case MissionPeriod.monthly:
        return 'MONTHLY';
    }
  }

  Color _periodColor(MissionPeriod p) {
    switch (p) {
      case MissionPeriod.daily:
        return AppColors.primaryPurple;
      case MissionPeriod.weekly:
        return AppColors.secondaryOrange;
      case MissionPeriod.monthly:
        return AppColors.gold;
    }
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
                      Text('Missions', style: AppText.heading(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(_error!, style: AppText.caption(size: 12, color: AppColors.dangerRed)),
                    ),
                  if (_progress.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No missions available right now', style: AppText.caption())),
                    ),
                  ..._progress.map((mp) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _periodColor(mp.mission.period).withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(AppRadius.chip),
                                    ),
                                    child: Text(
                                      _periodLabel(mp.mission.period),
                                      style: AppText.caption(size: 9, color: _periodColor(mp.mission.period)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(mp.mission.title, style: AppText.body(size: 14, weight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              GlowingProgressBar(value: mp.progress / mp.mission.goalCount),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${mp.progress}/${mp.mission.goalCount}', style: AppText.caption(size: 12)),
                                  Text('+${mp.mission.rewardAmount.toStringAsFixed(2)} 💎', style: AppText.caption(size: 12, color: AppColors.gold)),
                                ],
                              ),
                              if (mp.isComplete && !mp.claimed) ...[
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => _claim(mp.mission.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primaryButton,
                                      borderRadius: BorderRadius.circular(AppRadius.button),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('CLAIM', style: AppText.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                                  ),
                                ),
                              ] else if (mp.claimed) ...[
                                const SizedBox(height: 10),
                                Center(child: Text('✓ Claimed', style: AppText.caption(size: 12, color: AppColors.successGreen))),
                              ],
                            ],
                          ),
                        ),
                      )),
                ],
              ),
      ),
    );
  }
}
