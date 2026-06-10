import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Beautiful horizontally-scrolling number picker.
/// Used in period-setup pages: cycle length, period length, etc.
class NumberWheelPicker extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;
  final Color accent;

  const NumberWheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.unit = 'days',
    this.accent = AppColors.primary,
  });

  @override
  State<NumberWheelPicker> createState() => _NumberWheelPickerState();
}

class _NumberWheelPickerState extends State<NumberWheelPicker> {
  static const _itemWidth = 64.0;
  static const _itemHeight = 96.0;
  late final FixedExtentScrollController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value.clamp(widget.min, widget.max);
    _controller =
        FixedExtentScrollController(initialItem: _current - widget.min);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Big highlighted value
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accent.withOpacity(0.18),
                widget.accent.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              Text(
                '$_current',
                style: TextStyle(
                  color: widget.accent,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.unit,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Wheel
        SizedBox(
          height: _itemHeight,
          child: RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              physics: const FixedExtentScrollPhysics(),
              itemExtent: _itemWidth,
              perspective: 0.003,
              diameterRatio: 2.5,
              onSelectedItemChanged: (i) {
                final v = widget.min + i;
                setState(() => _current = v);
                widget.onChanged(v);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.max - widget.min + 1,
                builder: (_, i) {
                  final v = widget.min + i;
                  final isSelected = v == _current;
                  return RotatedBox(
                    quarterTurns: 1,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: isSelected
                              ? widget.accent
                              : AppColors.textTertiary,
                          fontSize: isSelected ? 28 : 20,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        child: Text('$v'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
