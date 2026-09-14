import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle_prediction.dart';
import '../../models/pregnancy_status.dart';
import '../../models/tracking_mode.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/phase_legend.dart';
import '../day_detail_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final mode = cycle.trackingMode ?? TrackingMode.period;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                mode.calendarTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(8),
              child: TableCalendar(
                firstDay:
                    DateTime.now().subtract(const Duration(days: 365 * 2)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                focusedDay: _focused,
                selectedDayPredicate: (d) =>
                    _selected != null && isSameDay(d, _selected),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selected = selected;
                    _focused = focused;
                  });
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DayDetailScreen(date: selected),
                  ));
                },
                onPageChanged: (d) => _focused = d,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: AppColors.primary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focusedDay) =>
                      _buildDay(cycle, day, false),
                  todayBuilder: (ctx, day, focusedDay) =>
                      _buildDay(cycle, day, true),
                  selectedBuilder: (ctx, day, focusedDay) =>
                      _buildDay(cycle, day, false, selected: true),
                  outsideBuilder: (ctx, day, focusedDay) => Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: PhaseLegend(mode: mode),
            ),
            SizedBox(height: 24),
            if (mode == TrackingMode.pregnancy && cycle.pregnancyStatus != null)
              _pregnancySummary(cycle.pregnancyStatus!)
            else if (cycle.prediction != null)
              _summary(cycle.prediction!, mode),
          ],
        ),
      ),
    );
  }

  Widget _buildDay(CycleProvider cycle, DateTime day, bool today,
      {bool selected = false}) {
    final mode = cycle.trackingMode ?? TrackingMode.period;
    if (mode == TrackingMode.pregnancy) {
      return _buildPregnancyDay(cycle, day, today, selected: selected);
    }
    final phase = cycle.phaseFor(day);
    final log = cycle.logForDay(day);

    Color? bg;
    Color textColor = AppColors.textPrimary;
    BoxShape shape = BoxShape.circle;
    bool isSafeDay = false;

    switch (phase) {
      case CyclePhase.period:
        bg = AppColors.period;
        textColor = Colors.white;
        break;
      case CyclePhase.predicted:
        bg = AppColors.predicted;
        break;
      case CyclePhase.ovulation:
        bg = AppColors.ovulation;
        textColor = Colors.white;
        break;
      case CyclePhase.fertile:
        bg = AppColors.fertile.withOpacity(0.4);
        break;
      default:
        // Safe day — soft sky blue (not white like predicted used to look).
        bg = AppColors.safe.withOpacity(0.35);
        isSafeDay = true;
    }

    return Center(
      child: Container(
        margin: EdgeInsets.all(4),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: shape,
          border: today
              ? Border.all(color: AppColors.primary, width: 2)
              : selected
                  ? Border.all(color: AppColors.accent, width: 2)
                  : isSafeDay
                      ? Border.all(color: AppColors.safe, width: 1.5)
                      : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (log != null && log.symptoms.isNotEmpty)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor == Colors.white
                        ? Colors.white
                        : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyDay(CycleProvider cycle, DateTime day, bool today,
      {bool selected = false}) {
    final preg = cycle.pregnancyStatus;
    final log = cycle.logForDay(day);
    Color bg = Colors.white;
    Color textColor = AppColors.textPrimary;
    if (preg != null) {
      final d = DateTime(day.year, day.month, day.day);
      if (!d.isBefore(preg.lmp) && !d.isAfter(preg.dueDate)) {
        final weeks = d.difference(preg.lmp).inDays ~/ 7;
        if (weeks < 13) {
          bg = AppColors.accentLight.withOpacity(0.55);
        } else if (weeks < 28) {
          bg = AppColors.accent.withOpacity(0.55);
          textColor = Colors.white;
        } else {
          bg = AppColors.accentDark.withOpacity(0.8);
          textColor = Colors.white;
        }
      }
      if (d.year == preg.dueDate.year &&
          d.month == preg.dueDate.month &&
          d.day == preg.dueDate.day) {
        bg = AppColors.period;
        textColor = Colors.white;
      }
    }
    return Center(
      child: Container(
        margin: EdgeInsets.all(4),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: today
              ? Border.all(color: AppColors.primary, width: 2)
              : selected
                  ? Border.all(color: AppColors.accent, width: 2)
                  : Border.all(
                      color: AppColors.primaryLight.withOpacity(0.25),
                      width: 1),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (log != null && log.symptoms.isNotEmpty)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor == Colors.white
                        ? Colors.white
                        : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summary(CyclePrediction pred, TrackingMode mode) {
    final periodLabel = pred.predictedRangeDays > 0
        ? '${_fmt(pred.earliestPeriodStart)} - ${_fmt(pred.latestPeriodStart)}'
        : _fmt(pred.nextPeriodStart);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode == TrackingMode.conception
                ? 'Your high-chance days'
                : 'Coming up',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          if (mode != TrackingMode.conception)
            _row(
                Icons.water_drop_rounded,
                AppColors.period,
                pred.predictedRangeDays > 0 ? 'Likely period' : 'Next period',
                periodLabel),
          if (mode != TrackingMode.conception) SizedBox(height: 8),
          _row(
              Icons.eco_rounded,
              AppColors.fertile,
              mode == TrackingMode.conception
                  ? 'High-chance window'
                  : 'Fertile window',
              '${_fmt(pred.fertileWindowStart)} > ${_fmt(pred.fertileWindowEnd)}'),
          SizedBox(height: 8),
          _row(
              Icons.brightness_5_rounded,
              AppColors.ovulation,
              mode == TrackingMode.conception ? 'Peak day' : 'Ovulation day',
              _fmt(pred.ovulationDay)),
        ],
      ),
    );
  }

  Widget _pregnancySummary(PregnancyStatus status) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This pregnancy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${status.trimesterLabel} Â· week ${status.weeksAlong}',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          Text(
            'Due ${_fmt(status.dueDate)} Â· ${status.daysUntilDue} days to go',
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
