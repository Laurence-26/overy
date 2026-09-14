import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle_prediction.dart';
import '../../models/tracking_mode.dart';
import '../../providers/cycle_provider.dart';
import '../../services/personalization_service.dart';
import '../../widgets/cycle_ring.dart';
import '../../widgets/phase_legend.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/surface_panel.dart';
import '../log/log_period_sheet.dart';
import '../day_detail_screen.dart';

String _firstName(CycleProvider cycle) {
  final raw = (cycle.profile?.username ??
          cycle.profile?.displayName ??
          'there')
      .trim();
  if (raw.isEmpty) return 'there';
  return raw.split(RegExp(r'\s+')).first;
}

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
    final name = _firstName(cycle);

    final phaseLabel = switch (phase) {
      CyclePhase.period => 'Period',
      CyclePhase.fertile => 'Fertile',
      CyclePhase.ovulation => 'Ovulation',
      CyclePhase.predicted => 'Predicted',
      CyclePhase.follicular => 'Follicular',
      CyclePhase.luteal => 'Luteal',
      CyclePhase.unknown => '-',
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
        padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: name, phaseLabel: phaseLabel, phaseColor: phaseColor),
            SizedBox(height: 16),
            const _PersonalizedTip(),
            SizedBox(height: 20),
            Center(
              child: CycleRing(currentCycle: cycle.currentCycle, prediction: p),
            ),
            SizedBox(height: 18),
            Center(child: PhaseLegend(mode: TrackingMode.period)),
            SizedBox(height: 24),
            // One-tap "period started today" - closes the open cycle (if any)
            // and starts a fresh one beginning today.
            _PeriodStartedTodayBanner(
              hasActiveToday:
                  phase == CyclePhase.period && cycle.currentCycle != null,
            ),
            SizedBox(height: 16),
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
                SizedBox(width: 12),
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
            SizedBox(height: 24),
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
                  SizedBox(width: 12),
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
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.eco_rounded,
                      label: 'Fertile window',
                      value:
                          '${DateFormat('MMM d').format(p.fertileWindowStart)} - ${DateFormat('MMM d').format(p.fertileWindowEnd)}',
                      color: AppColors.fertile,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.verified_rounded,
                      label: 'Confidence',
                      value: '${p.confidence}%',
                      subtitle: p.isLate
                          ? 'Period looks late'
                          : p.predictedRangeDays > 0
                              ? 'Likely ${DateFormat('MMM d').format(p.earliestPeriodStart)}-${DateFormat('MMM d').format(p.latestPeriodStart)}'
                              : 'Based on your history',
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
    final name = _firstName(cycle);

    final phaseLabel = switch (phase) {
      CyclePhase.period => 'Period',
      CyclePhase.fertile => 'High chance',
      CyclePhase.ovulation => 'Peak day',
      CyclePhase.predicted => 'Period coming',
      CyclePhase.follicular => 'Building up',
      CyclePhase.luteal => 'Waiting',
      CyclePhase.unknown => '-',
    };
    final phaseColor = switch (phase) {
      CyclePhase.fertile || CyclePhase.ovulation => AppColors.fertile,
      CyclePhase.period => AppColors.period,
      _ => AppColors.textTertiary,
    };

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(name: name, phaseLabel: phaseLabel, phaseColor: phaseColor),
            SizedBox(height: 16),
            const _PersonalizedTip(),
            SizedBox(height: 20),
            Center(
              child: CycleRing(currentCycle: cycle.currentCycle, prediction: p),
            ),
            SizedBox(height: 18),
            Center(child: PhaseLegend(mode: TrackingMode.conception)),
            SizedBox(height: 28),
            if (p != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC8E6DC), Color(0xFF8AC8B8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your high chance window',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${DateFormat('MMM d').format(p.fertileWindowStart)} > ${DateFormat('MMM d').format(p.fertileWindowEnd)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
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
              SizedBox(height: 16),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.water_drop_outlined,
                      label: p.predictedRangeDays > 0
                          ? 'Likely period'
                          : 'Next period',
                      value: p.predictedRangeDays > 0
                          ? '${DateFormat('MMM d').format(p.earliestPeriodStart)}-${DateFormat('MMM d').format(p.latestPeriodStart)}'
                          : DateFormat('MMM d').format(p.nextPeriodStart),
                      color: AppColors.period,
                    ),
                  ),
                ],
              ),
            ] else
              _firstRunHint(
                  'Log your last period to see your high-chance days.'),
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
    final name = _firstName(cycle);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              name: name,
              phaseLabel: preg?.trimesterLabel ?? '-',
              phaseColor: AppColors.accent,
            ),
            SizedBox(height: 16),
            const _PersonalizedTip(),
            SizedBox(height: 20),
            Center(
                child: _PregnancyRing(
                    progress: preg?.progress ?? 0,
                    weeks: preg?.weeksAlong,
                    daysIntoWeek: preg?.daysIntoWeek)),
            SizedBox(height: 28),
            if (preg != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.eco_rounded,
                      label: 'Next trimester',
                      value: preg.nextTrimesterStart != null
                          ? DateFormat('MMM d').format(preg.nextTrimesterStart!)
                          : 'You\'re there!',
                      color: AppColors.fertile,
                    ),
                  ),
                  SizedBox(width: 12),
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
              SizedBox(height: 12),
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
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WEEK',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                weeks?.toString() ?? '-',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                weeks == null
                    ? 'Set due date to begin'
                    : '${daysIntoWeek}d into week $weeks',
                style: TextStyle(
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
            child: Icon(Icons.child_friendly_rounded,
                color: Colors.white, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baby kicks today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cycle.todayKicks}',
                  style: TextStyle(
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
                  SnackBar(
                    content: Text('Kick logged'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.95),
              ),
              child:
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _firstRunHint(String text) => SurfacePanel(
      tint: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

class _PersonalizedTip extends StatelessWidget {
  const _PersonalizedTip();

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final mode = cycle.trackingMode ?? TrackingMode.period;
    final tip = PersonalizationService.todayTip(
      profile: cycle.profile,
      mode: mode,
      phase: cycle.phaseFor(DateTime.now()),
      pregnancy: cycle.pregnancyStatus,
      recentLogs: cycle.allLogs,
    );
    final color = switch (mode) {
      TrackingMode.period => AppColors.primary,
      TrackingMode.conception => AppColors.fertile,
      TrackingMode.pregnancy => AppColors.accent,
    };
    return SurfacePanel(
      tint: color,
      padding: const EdgeInsets.all(16),
      opacity: 0.58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.45,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return SurfacePanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      elevated: true,
      opacity: 0.6,
      tint: phaseColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hi, $name',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: phaseColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: phaseColor.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                  color: Colors.white.withOpacity(0.55), width: 1.5),
            ),
            child: Text(
              phaseLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
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
    return SurfacePanel(
      tint: color,
      padding: EdgeInsets.zero,
      onTap: onTap,
      opacity: 0.58,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
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
        title: Text('Start a new period today?'),
        content: Text(
          'This will close your current cycle and start a fresh one beginning today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Start today'),
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
      messenger.showSnackBar(SnackBar(
        content: Text('New period started today'),
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

    return SurfacePanel(
      tint: AppColors.period,
      padding: EdgeInsets.zero,
      onTap: _saving ? null : () => _confirm(context),
      borderColor: AppColors.period.withOpacity(0.35),
      opacity: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.period.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.water_drop_rounded, color: AppColors.period),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_saving)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.period),
                ),
              )
            else
              Icon(Icons.arrow_forward_rounded, color: AppColors.period),
          ],
        ),
      ),
    );
  }
}
