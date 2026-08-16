import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glowing_progress_bar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/cyber_text_field.dart';
import '../widgets/ad_disclosure_dialog.dart';
import '../services/ads_service.dart';
import '../services/game_data_service.dart';
import '03_home_dashboard.dart';

/// Screen 5 — Game Details
///
/// Mirrors the reference app's system: currency is auto-credited the
/// instant total ads watched for this game hits a multiple of the
/// admin's "ads per cycle" (no manual claim step). "Request Payout" is
/// always visible at the bottom — tapping it opens a form; if the user
/// hasn't completed at least one cycle yet, it explains that instead
/// of letting them submit. Submitting a payout resets the whole cycle
/// back to #1 (balance, ad count, and ad history all clear for this
/// game), exactly like the reference app.
class GameDetailsScreen extends StatefulWidget {
  final GameInfo game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  Map<String, dynamic> _eligibility = {};
  bool _loading = true;
  bool _checkingAd = false;
  bool _requestInFlight = false;
  bool _dailyLimitReached = false;

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    setState(() => _loading = true);
    try {
      final result = await GameDataService.instance
          .getGameEligibility(widget.game.id);
      if (!mounted) return;
      setState(() {
        _eligibility = result;
        _dailyLimitReached = result['daily_limit_reached'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _totalAdsWatched =>
      (_eligibility['total_ads_watched'] as int?) ?? 0;

  int get _adsPerCycle =>
      (_eligibility['ads_per_cycle'] as int?) ?? 0;

  double get _currencyPerCycle =>
      (_eligibility['currency_per_cycle'] as double?) ?? 0;

  double get _balance =>
      (_eligibility['balance'] as double?) ?? 0;

  int get _cyclePos {
    if (_adsPerCycle <= 0) return 0;
    return _totalAdsWatched % _adsPerCycle;
  }

  int get _adsLeftInCycle {
    if (_adsPerCycle <= 0) return 0;
    final pos = _cyclePos;
    return pos == 0 ? _adsPerCycle : _adsPerCycle - pos;
  }

  double get progress {
    if (_adsPerCycle <= 0) return 0;
    return (_cyclePos / _adsPerCycle).clamp(0.0, 1.0);
  }

  bool get _hasConfig => _eligibility['has_config'] == true;

  void _openScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(
        game: widget.game,
        eligibility: _eligibility,
      ),
    );
  }

  void _openPayoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayoutSheet(
        game: widget.game,
        eligibility: _eligibility,
      ),
    ).then((_) => _loadEligibility());
  }

  Future<void> _onWatchAdTapped() async {
    if (_requestInFlight || _checkingAd) return;

    setState(() {
      _requestInFlight = true;
      _checkingAd = true;
    });

    try {
      if (!AdsService.instance.isAdReady) {
        await AdsService.instance.loadRewardedAd();
      }

      if (!AdsService.instance.isAdReady) {
        if (!mounted) return;
        setState(() {
          _requestInFlight = false;
          _checkingAd = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad is not ready. Please try again.')),
        );
        return;
      }

      setState(() => _checkingAd = false);

      final rewarded = await AdsService.instance.showRewardedAd();

      if (!rewarded) {
        if (!mounted) return;
        setState(() => _requestInFlight = false);
        return;
      }

      final result = await GameDataService.instance.recordAdWatch(
        gameId: widget.game.id,
      );

      if (!mounted) return;

      setState(() {
        _eligibility = result;
        _dailyLimitReached = result['daily_limit_reached'] == true;
        _requestInFlight = false;
      });

      final earned = (result['earned_this_ad'] as num?)?.toDouble() ?? 0;

      if (earned > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+${earned.toStringAsFixed(2)} ${widget.game.currency} earned!',
            ),
          ),
        );
      }
    } on GameDataException catch (e) {
      if (!mounted) return;
      setState(() {
        _requestInFlight = false;
        _checkingAd = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _requestInFlight = false;
        _checkingAd = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.game.name,
          style: AppText.body(size: 18, weight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEligibility,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        widget.game.icon,
                        color: AppColors.primaryPurple,
                        size: 46,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.game.name,
                        style: AppText.heading(size: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your Balance',
                        style: AppText.caption(size: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _balance.toStringAsFixed(2),
                        style: AppText.heading(size: 34),
                      ),
                      Text(
                        widget.game.currency,
                        style: AppText.caption(size: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MiniStat(
                            label: 'Ads Watched',
                            value: '$_totalAdsWatched',
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.glassBorder,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          _MiniStat(
                            label: 'Cycles Done',
                            value: '${_eligibility['cycles_done'] ?? 0}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Earn By Watching Ads',
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                if (!_hasConfig)
                  Text(
                    'No withdraw rate configured for this game yet',
                    style: AppText.caption(
                      size: 12,
                      color: AppColors.secondaryOrange,
                    ),
                  )
                else ...[
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ondemand_video_rounded,
                          color: AppColors.gold,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Every $_adsPerCycle ads → earn ${_currencyPerCycle.toStringAsFixed(2)} ${widget.game.currency}',
                                style: AppText.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$_adsLeftInCycle more ad${_adsLeftInCycle == 1 ? '' : 's'} to complete this cycle',
                                style: AppText.caption(size: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlowingProgressBar(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    '$_cyclePos / $_adsPerCycle ads in current cycle',
                    style: AppText.caption(size: 12),
                  ),
                ],

                const SizedBox(height: 18),

                if (_checkingAd)
                  const SizedBox(
                    height: 52,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                        ),
                      ),
                    ),
                  )
                else if (_dailyLimitReached)
                  Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface2.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color:
                            AppColors.secondaryOrange.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'Daily ad limit reached — come back tomorrow',
                      style: AppText.caption(
                        size: 13,
                        color: AppColors.secondaryOrange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (!AdsService.instance.isAdReady)
                  const NoAdAvailableNotice()
                else
                  GradientButton(
                    label: 'WATCH AD & EARN',
                    gradient: AppGradients.rewardButton,
                    icon: Icons.play_arrow_rounded,
                    loading: _requestInFlight,
                    onPressed: _onWatchAdTapped,
                  ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _openScheduleSheet,
                  child: Row(
                    children: [
                      Text(
                        'Withdraw Rates',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View full schedule',
                        style: AppText.caption(size: 12),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openPayoutSheet,
                    icon: const Icon(
                      Icons.payments_rounded,
                      size: 18,
                    ),
                    label: const Text('REQUEST PAYOUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.body(
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.caption(size: 10),
        ),
      ],
    );
  }
}

class _ScheduleSheet extends StatelessWidget {
  final GameInfo game;
  final Map<String, dynamic> eligibility;

  const _ScheduleSheet({
    required this.game,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    if (eligibility['has_config'] != true) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No withdraw rate configured for ${game.name} yet.',
              style: AppText.caption(),
            ),
          ),
        ),
      );
    }

    final schedule =
        (eligibility['schedule'] as List).cast<Map<String, num>>();
    final totalAdsWatched =
        eligibility['total_ads_watched'] as int;
    final balance =
        eligibility['balance'] as double;
    final cyclesDone =
        eligibility['cycles_done'] as int;
    final totalCycles =
        eligibility['total_cycles'] as int;
    final target =
        eligibility['target_currency'] as double;
    final adsPerCycle =
        eligibility['ads_per_cycle'] as int;
    final currencyPerCycle =
        eligibility['currency_per_cycle'] as double;

    final pct = totalCycles > 0
        ? (cyclesDone / totalCycles * 100).clamp(0, 100)
        : 0.0;

    final nextRow =
        (eligibility['next_row'] as Map).cast<String, num>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin:
                  const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                '${game.name} — Auto-Calculated Schedule',
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Cycles Done',
                          value: '$cyclesDone/$totalCycles',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: game.currency,
                          value: balance.toStringAsFixed(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'To Target',
                          value:
                              '${pct.toStringAsFixed(0)}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GlowingProgressBar(
                    value: totalCycles > 0
                        ? cyclesDone / totalCycles
                        : 0.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextRow.isNotEmpty
                        ? 'Next: ${nextRow['ads']} ads → ${(nextRow['currency'] as num).toStringAsFixed(2)} ${game.currency} · ${(nextRow['ads']! - totalAdsWatched)} ads to go'
                        : 'Target reached! You have all ${target.toStringAsFixed(2)} ${game.currency}!',
                    style: AppText.caption(size: 12),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Full Schedule',
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0;
                      i < schedule.length;
                      i++)
                    _ScheduleRow(
                      cycleNumber: i + 1,
                      cumulativeAds:
                          schedule[i]['ads']!.toInt(),
                      cumulativeCurrency:
                          schedule[i]['currency']!.toDouble(),
                      currency: game.currency,
                      totalAdsWatched: totalAdsWatched,
                      previousCumulativeAds: i == 0
                          ? 0
                          : schedule[i - 1]['ads']!.toInt(),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Rate: every $adsPerCycle ads = ${currencyPerCycle.toStringAsFixed(2)} ${game.currency} · Target: ${target.toStringAsFixed(2)}',
                    style: AppText.caption(size: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final int cycleNumber;
  final int cumulativeAds;
  final double cumulativeCurrency;
  final String currency;
  final int totalAdsWatched;
  final int previousCumulativeAds;

  const _ScheduleRow({
    required this.cycleNumber,
    required this.cumulativeAds,
    required this.cumulativeCurrency,
    required this.currency,
    required this.totalAdsWatched,
    required this.previousCumulativeAds,
  });

  @override
  Widget build(BuildContext context) {
    final done =
        totalAdsWatched >= cumulativeAds;

    final isCurrent =
        !done &&
        totalAdsWatched >= previousCumulativeAds;

    final String label;
    final Color color;

    if (done) {
      label = '✓ Done';
      color = AppColors.successGreen;
    } else if (isCurrent) {
      label =
          '${cumulativeAds - totalAdsWatched} left';
      color = AppColors.primaryPurple;
    } else {
      label = '🔒';
      color = AppColors.muted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        borderColor:
            isCurrent ? AppColors.primaryPurple : null,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$cycleNumber',
                style: AppText.caption(size: 12),
              ),
            ),
            Expanded(
              child: Text(
                '$cumulativeAds ads',
                style: AppText.body(size: 13),
              ),
            ),
            Expanded(
              child: Text(
                '${cumulativeCurrency.toStringAsFixed(2)} $currency',
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              label,
              style: AppText.caption(
                size: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.caption(size: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PayoutSheet extends StatefulWidget {
  final GameInfo game;
  final Map<String, dynamic> eligibility;

  const _PayoutSheet({
    required this.game,
    required this.eligibility,
  });

  @override
  State<_PayoutSheet> createState() =>
      _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  late final TextEditingController _amountController;
  final _usernameController =
      TextEditingController();
  final _uidController =
      TextEditingController();
  final _noteController =
      TextEditingController();

  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  bool get _eligible =>
      widget.eligibility['eligible'] == true;

  @override
  void initState() {
    super.initState();

    final maxEligible =
        (widget.eligibility['balance'] as double?) ?? 0;

    _amountController = TextEditingController(
      text: maxEligible > 0
          ? maxEligible.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _usernameController.dispose();
    _uidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount =
        double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      setState(() =>
          _error = 'Enter a valid amount.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await GameDataService.instance
          .submitCycleWithdraw(
        gameId: widget.game.id,
        amount: amount,
        gameUsername:
            _usernameController.text,
        gameUid: _uidController.text,
        note: _noteController.text,
      );

      if (!mounted) return;

      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on GameDataException catch (e) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        (widget.eligibility['balance'] as double?) ?? 0;

    final totalAds =
        (widget.eligibility['total_ads_watched'] as int?) ?? 0;

    final cyclesDone =
        (widget.eligibility['cycles_done'] as int?) ?? 0;

    final totalCycles =
        (widget.eligibility['total_cycles'] as int?) ?? 0;

    final adsPerCycle =
        (widget.eligibility['ads_per_cycle'] as int?) ?? 0;

    final currencyPerCycle =
        (widget.eligibility['currency_per_cycle'] as double?) ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
                20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.game.icon,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.game.name,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Balance: ${balance.toStringAsFixed(2)} ${widget.game.currency} · Ads: $totalAds',
              style: AppText.caption(size: 12),
            ),

            const SizedBox(height: 12),

            if (_submitted) ...[
              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successGreen
                      .withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.successGreen
                        .withOpacity(0.3),
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  'Withdrawal requested! Your cycle has restarted from #1 — watch ads again to earn more.',
                  style: AppText.body(
                    size: 13,
                    color:
                        AppColors.successGreen,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'DONE',
                  onPressed: () =>
                      Navigator.pop(context),
                ),
              ),
            ] else if (!_eligible) ...[
              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed
                      .withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.dangerRed
                        .withOpacity(0.25),
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  adsPerCycle > 0
                      ? '🔒 You don\'t have any balance yet — watch $adsPerCycle ads to earn ${currencyPerCycle.toStringAsFixed(2)} ${widget.game.currency}.'
                      : '🔒 No withdraw rate configured for this game yet.',
                  style: AppText.body(
                    size: 13,
                    color:
                        AppColors.dangerRed,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen
                      .withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.successGreen
                        .withOpacity(0.25),
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  'Available to withdraw: ${balance.toStringAsFixed(2)} ${widget.game.currency}'
                  '${totalCycles > 0 ? ' · Lifetime cycles: $cyclesDone/$totalCycles' : ''}',
                  style: AppText.caption(
                    size: 12,
                    color:
                        AppColors.successGreen,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              CyberTextField(
                hint: 'Amount to withdraw',
                icon:
                    Icons.diamond_outlined,
                controller:
                    _amountController,
              ),

              const SizedBox(height: 12),

              CyberTextField(
                hint:
                    'Your in-game username',
                icon:
                    Icons.person_outline_rounded,
                controller:
                    _usernameController,
              ),

              const SizedBox(height: 12),

              CyberTextField(
                hint: 'Your in-game UID',
                icon:
                    Icons.badge_outlined,
                controller: _uidController,
              ),

              const SizedBox(height: 12),

              CyberTextField(
                hint: 'Note (optional)',
                icon:
                    Icons.edit_note_rounded,
                controller: _noteController,
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppText.caption(
                    size: 12,
                    color:
                        AppColors.dangerRed,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              Text(
                'Admin will manually process and send currency to your game account. You can withdraw part of your balance — the rest stays available.',
                style: AppText.caption(
                  size: 11,
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label:
                      'SUBMIT REQUEST',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
