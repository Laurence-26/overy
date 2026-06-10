import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PhaseLegend extends StatelessWidget {
  const PhaseLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: const [
        _LegendDot(color: AppColors.period, label: 'Period'),
        _LegendDot(color: AppColors.predicted, label: 'Predicted'),
        _LegendDot(color: AppColors.fertile, label: 'Fertile'),
        _LegendDot(color: AppColors.ovulation, label: 'Ovulation'),
        _LegendDot(color: Colors.white, label: 'Safe', bordered: true),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool bordered;
  const _LegendDot({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: bordered
                ? Border.all(color: AppColors.primaryLight, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
