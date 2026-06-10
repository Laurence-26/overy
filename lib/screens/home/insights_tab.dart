import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/stat_card.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final completed = cycle.cycles
        .where((c) => c.cycleLength != null)
        .toList()
        .reversed
        .toList(); // oldest → newest for chart

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${cycle.cycles.length} cycles tracked',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (cycle.prediction != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Avg cycle',
                      value: '${cycle.prediction!.averageCycleLength} d',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Avg period',
                      value: '${cycle.prediction!.averagePeriodLength} d',
                      color: AppColors.period,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: cycle.prediction!.isIrregular
                          ? Icons.timeline_rounded
                          : Icons.check_circle_rounded,
                      label: 'Pattern',
                      value: cycle.prediction!.isIrregular
                          ? 'Irregular'
                          : 'Regular',
                      color: cycle.prediction!.isIrregular
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (completed.length >= 2) ...[
              _ChartCard(cycles: completed),
              const SizedBox(height: 24),
            ],
            _historySection(cycle.cycles),
          ],
        ),
      ),
    );
  }

  Widget _historySection(List<Cycle> cycles) {
    if (cycles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.insights_outlined,
                color: AppColors.primary, size: 36),
            SizedBox(height: 12),
            Text(
              'No cycles logged yet. Once you log a few, charts and patterns will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cycle history',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...cycles.take(10).map((c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.period.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        color: AppColors.period),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmtFull(c.startDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Period: ${c.periodLength} days'
                          '${c.cycleLength != null ? "  •  Cycle: ${c.cycleLength} days" : "  •  Active"}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  static String _fmtFull(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ChartCard extends StatelessWidget {
  final List<Cycle> cycles; // oldest → newest, all have cycleLength
  const _ChartCard({required this.cycles});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < cycles.length; i++) {
      spots.add(FlSpot(i.toDouble(), cycles[i].cycleLength!.toDouble()));
    }
    final avg = cycles.map((c) => c.cycleLength!).reduce((a, b) => a + b) /
        cycles.length;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cycle length over time',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Average: ${avg.toStringAsFixed(1)} days',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 7,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text(
                        '#${v.toInt() + 1}',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
