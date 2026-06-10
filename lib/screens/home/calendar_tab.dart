import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle_prediction.dart';
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Your calendar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
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
                headerStyle: const HeaderStyle(
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
                daysOfWeekStyle: const DaysOfWeekStyle(
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
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: PhaseLegend(),
            ),
            const SizedBox(height: 24),
            if (cycle.prediction != null) _summary(cycle.prediction!),
          ],
        ),
      ),
    );
  }

  Widget _buildDay(CycleProvider cycle, DateTime day, bool today,
      {bool selected = false}) {
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
        // Safe day — outside fertile/period windows.
        bg = Colors.white;
        isSafeDay = true;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(4),
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
                      ? Border.all(
                          color: AppColors.primaryLight.withOpacity(0.4),
                          width: 1)
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

  Widget _summary(p) {
    final pred = p as CyclePrediction;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coming up',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _row(Icons.water_drop_rounded, AppColors.period, 'Next period',
              _fmt(pred.nextPeriodStart)),
          const SizedBox(height: 8),
          _row(Icons.eco_rounded, AppColors.fertile, 'Fertile window',
              '${_fmt(pred.fertileWindowStart)} → ${_fmt(pred.fertileWindowEnd)}'),
          const SizedBox(height: 8),
          _row(Icons.brightness_5_rounded, AppColors.ovulation,
              'Ovulation day', _fmt(pred.ovulationDay)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Text(value,
            style: const TextStyle(
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
