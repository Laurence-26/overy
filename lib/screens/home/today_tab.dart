import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle_prediction.dart';
import '../../models/tracking_mode.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/cycle_ring.dart';
import '../../widgets/phase_legend.dart';
import '../../widgets/stat_card.dart';
import '../log/log_period_sheet.dart';
import '../day_detail_screen.dart';

class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final mode = cycle.trackingMode ?? TrackingMode.period;
    return switch (mode) {
      TrackingMode.period => const _PeriodTodayView(),
      TrackingMode.conception => const _ConceptionTodayView(),
      TrackingMode.pregnancy => const _PregnancyTodayView(),
    };
  }
}

// ============== Period mode ==============
class _PeriodTodayView extends StatelessWidget {
  const _PeriodTodayView();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final p = cycle.prediction;
    final phase = cycle.phaseFor(DateTime.now());
    final name = cycle.profile?.username ??
        cycle.profile?.displayName?.split(' ').first ??
        'there';

    final phaseLabel = switch (phase) {
      CyclePhase.period => 'Period',
      CyclePhase.fertile => 'Fertile',
      CyclePhase.ovulation => 'Ovulation',
      CyclePhase.predicted => 'Predicted',
      CyclePhase.follicular => 'Follicular',
      CyclePhase.luteal => 'Luteal',
      CyclePhase.unknown => '—',
    };
    final phaseColor = switch (phase) {
      CyclePhase.period => AppColors.period,
      CyclePhase.fertile => AppColors.fertile,
      CyclePhase.ovulation => AppColors.ovulation,
      CyclePhase.predicted => AppColors.predicted,
      CyclePhase.follicular => AppColors.accent,
      CyclePhase.luteal => AppColors.accentDark,
      CyclePhase.unknown => AppColors.textTertiary,
    };

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: name, phaseLabel: phaseLabel, phaseColor: phaseColor),
            const SizedBox(height: 28),
            Center(
              child: CycleRing(
                  currentCycle: cycle.currentCycle, prediction: p),
            ),
            const SizedBox(height: 18),
            const Center(child: PhaseLegend()),
            const SizedBox(height: 24),
            // One-tap "period started today" — closes the open cycle (if any)
            // and starts a fresh one beginning today.
            _PeriodStartedTodayBanner(
              hasActiveToday: phase == CyclePhase.period &&
                  cycle.currentCycle != null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.water_drop_rounded,
                    label: 'Log a different date',
                    color: AppColors.period,
                    onTap: () => showLogPeriodSheet(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Log today',
                    color: AppColors.accent,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DayDetailScreen(date: DateTime.now()),
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (p != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.repeat_rounded,
                      label: 'Cycle length',
                      value: '${p.averageCycleLength} days',
                      subtitle: p.isIrregular ? 'Irregular' : 'Regular',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Period length',
                      value: '${p.averagePeriodLength} days',
                      color: AppColors.period,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.eco_rounded,
                      label: 'Fertile window',
                      value:
                          '${DateFormat('MMM d').format(p.fertileWindowStart)} – ${DateFormat('MMM d').format(p.fertileWindowEnd)}',
                      color: AppColors.fertile,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.verified_rounded,
                      label: 'Confidence',
                      value: '${p.confidence}%',
                      subtitle:
                          p.isIrregular ? 'Adaptive' : 'Based on history',
                      color: AppColors.ovulation,
                    ),
                  ),
                ],
              ),
            ] else
              _firstRunHint('Log your first period to unlock predictions.'),
          ],
        ),
      ),
    );
  }
}

// ============== Conception mode ==============
class _ConceptionTodayView extends StatelessWidget {
  const _ConceptionTodayView();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final p = cycle.prediction;
    final phase = cycle.phaseFor(DateTime.now());
    final name = cycle.profile?.username ??
        cycle.profile?.displayName?.split(' ').first ??
        'there';

    final phaseLabel = switch (phase) {
      CyclePhase.period => 'Period',
      CyclePhase.fertile => 'High chance',
      CyclePhase.ovulation => 'Peak day',
      CyclePhase.predicted => 'Period coming',
      CyclePhase.follicular => 'Building up',
      CyclePhase.luteal => 'Waiting',
      CyclePhase.unknown => '—',
    };
    final phaseColor = switch (phase) {
      CyclePhase.fertile || CyclePhase.ovulation => AppColors.fertile,
      CyclePhase.period => AppColors.period,
      _ => AppColors.textTertiary,
    };

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: name, phaseLabel: phaseLabel, phaseColor: phaseColor),
            const SizedBox(height: 28),
            Center(
              child: CycleRing(
                  currentCycle: cycle.currentCycle, prediction: p),
            ),
            const SizedBox(height: 18),
            const Center(child: PhaseLegend()),
            const SizedBox(height: 28),
            if (p != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8E6DC), Color(0xFF8AC8B8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your high chance window',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('MMM d').format(p.fertileWindowStart)} → ${DateFormat('MMM d').format(p.fertileWindowEnd)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'These are your most likely days to conceive. Being intimate during this window gives the best chance.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.brightness_5_rounded,
                      label: 'Peak day',
                      value: DateFormat('MMM d').format(p.ovulationDay),
                      subtitle: 'Highest chance',
                      color: AppColors.ovulation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Next period',
                      value: DateFormat('MMM d').format(p.nextPeriodStart),
                      color: AppColors.period,
                    ),
                  ),
                ],
              ),
            ] else
              _firstRunHint('Log your last period to see your high-chance days.'),
          ],
        ),
      ),
    );
  }
}

// ============== Pregnancy mode ==============
class _PregnancyTodayView extends StatelessWidget {
  const _PregnancyTodayView();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final preg = cycle.pregnancyStatus;
    final name = cycle.profile?.username ??
        cycle.profile?.displayName?.split(' ').first ??
        'there';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              name: name,
              phaseLabel: preg?.trimesterLabel ?? '—',
              phaseColor: AppColors.accent,
            ),
            const SizedBox(height: 28),
            Center(child: _PregnancyRing(progress: preg?.progress ?? 0,
                weeks: preg?.weeksAlong, daysIntoWeek: preg?.daysIntoWeek)),
            const SizedBox(height: 28),
            if (preg != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.eco_rounded,
                      label: 'Next trimester',
                      value: preg.nextTrimesterStart != null
                          ? DateFormat('MMM d')
                              .format(preg.nextTrimesterStart!)
                          : 'You\'re there!',
                      color: AppColors.fertile,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.event_available_rounded,
                      label: 'Due date',
                      value: DateFormat('MMM d').format(preg.dueDate),
                      subtitle: '${preg.daysUntilDue} days to go',
                      color: AppColors.period,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _BabyKicksCard(),
            ] else
              _firstRunHint(
                  'Add your last period or due date in Profile to begin.'),
          ],
        ),
      ),
    );
  }
}

class _PregnancyRing extends StatelessWidget {
  final double progress;
  final int? weeks;
  final int? daysIntoWeek;
  const _PregnancyRing({
    required this.progress,
    required this.weeks,
    required this.daysIntoWeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 18,
              backgroundColor: AppColors.accentLight.withOpacity(0.35),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WEEK',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                weeks?.toString() ?? '—',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                weeks == null
                    ? 'Set due date to begin'
                    : '${daysIntoWeek}d into week $weeks',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BabyKicksCard extends StatelessWidget {
  const _BabyKicksCard();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC4D6), Color(0xFFFFB3CC)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3),
            ),
            child: const Icon(Icons.child_friendly_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Baby kicks today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cycle.todayKicks}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Total tracked: ${cycle.totalKicks}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await cycle.logBabyKick();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kick logged 👶'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.95),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _firstRunHint(String text) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );

// Shared
class _Header extends StatelessWidget {
  final String name;
  final String phaseLabel;
  final Color phaseColor;

  const _Header({
    required this.name,
    required this.phaseLabel,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Hi, $name 🌸',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: phaseColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            phaseLabel,
            style: TextStyle(
              color: phaseColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-tap CTA: "My period started today." Closes the open cycle (if any)
/// and creates a brand-new cycle starting today.
class _PeriodStartedTodayBanner extends StatefulWidget {
  final bool hasActiveToday;
  const _PeriodStartedTodayBanner({required this.hasActiveToday});

  @override
  State<_PeriodStartedTodayBanner> createState() =>
      _PeriodStartedTodayBannerState();
}

class _PeriodStartedTodayBannerState extends State<_PeriodStartedTodayBanner> {
  bool _saving = false;

  Future<void> _confirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new period today?'),
        content: const Text(
          'This will close your current cycle and start a fresh one beginning today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start today'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    setState(() => _saving = true);
    final cycle = context.read<CycleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cycle
          .startPeriod(DateTime.now())
          .timeout(const Duration(seconds: 15));
      messenger.showSnackBar(const SnackBar(
        content: Text('New period started today 🌸'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Could not save: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.hasActiveToday
        ? 'Period continues today'
        : 'Period started today?';
    final subtitle = widget.hasActiveToday
        ? 'Tap to start a fresh cycle if this is a new period.'
        : 'Tap to log today as your new period start.';

    return Material(
      color: AppColors.period.withOpacity(0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _saving ? null : () => _confirm(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.period.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: AppColors.period),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_saving)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.period),
                  ),
                )
              else
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.period),
            ],
          ),
        ),
      ),
    );
  }
}
