import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/tracking_mode.dart';
import 'surface_panel.dart';

class PhaseLegend extends StatelessWidget {
  final TrackingMode mode;
  const PhaseLegend({super.key, this.mode = TrackingMode.period});

  @override
  Widget build(BuildContext context) {
    final dots = switch (mode) {
      TrackingMode.pregnancy => [
          _LegendDot(color: AppColors.accentLight, label: '1st trimester'),
          _LegendDot(color: AppColors.accent, label: '2nd'),
          _LegendDot(color: AppColors.accentDark, label: '3rd'),
        ],
      TrackingMode.conception => [
          _LegendDot(color: AppColors.period, label: 'Period'),
          _LegendDot(color: AppColors.fertile, label: 'High chance'),
          _LegendDot(color: AppColors.ovulation, label: 'Peak'),
          _LegendDot(color: AppColors.safe, label: 'Waiting'),
        ],
      TrackingMode.period => [
          _LegendDot(color: AppColors.period, label: 'Period'),
          _LegendDot(color: AppColors.predicted, label: 'Predicted'),
          _LegendDot(color: AppColors.fertile, label: 'Fertile'),
          _LegendDot(color: AppColors.ovulation, label: 'Ovulation'),
          _LegendDot(color: AppColors.safe, label: 'Safe'),
        ],
    };

    return SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      elevated: false,
      opacity: 0.55,
      tint: AppColors.accent,
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: dots,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
