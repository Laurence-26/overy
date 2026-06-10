import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/number_wheel_picker.dart';
import '../home/home_shell.dart';
import 'setup_scaffold.dart';

class PeriodSetupFlow extends StatefulWidget {
  const PeriodSetupFlow({super.key});

  @override
  State<PeriodSetupFlow> createState() => _PeriodSetupFlowState();
}

class _PeriodSetupFlowState extends State<PeriodSetupFlow> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _saving = false;

  DateTime? _lastPeriodDate;
  DateTimeRange? _notSureRange;
  int _cycleLength = 28;
  int _periodLength = 5;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _lastPeriodDate != null || _notSureRange != null;
      case 1:
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_page < 2) {
      setState(() => _page++);
      _pc.animateToPage(_page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    } else {
      await _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() => _page--);
      _pc.animateToPage(_page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic);
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final cycle = context.read<CycleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profile = cycle.profile;

    final start = _lastPeriodDate ??
        _notSureRange?.start ??
        DateTime.now().subtract(const Duration(days: 14));

    try {
      await cycle.startPeriod(start).timeout(const Duration(seconds: 15));
      if (profile != null) {
        await cycle
            .updateProfile(profile.copyWith(
              averageCycleLength: _cycleLength,
              averagePeriodLength: _periodLength,
              setupComplete: true,
            ))
            .timeout(const Duration(seconds: 15));
      }
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Couldn\'t save: $e'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      ('When did your last period start?',
          'Pick a date — or let us know if you\'re unsure.'),
      ('How long is your cycle, usually?',
          'Cycle length is the number of days from one period\'s start to the next.'),
      ('How many days does your period last?',
          'A typical period lasts 3 to 7 days.'),
    ];

    return SetupScaffold(
      currentPage: _page,
      totalPages: 3,
      title: titles[_page].$1,
      subtitle: titles[_page].$2,
      primaryLabel: _page == 2 ? 'Start tracking' : 'Continue',
      primaryLoading: _saving,
      onBack: _back,
      onPrimary: !_canContinue || _saving ? null : _next,
      accent: AppColors.primary,
      child: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _page1LastPeriod(),
          _page2CycleLength(),
          _page3PeriodLength(),
        ],
      ),
    );
  }

  // --- Page 1: last period date or "not sure" range ---
  Widget _page1LastPeriod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateTile(
          icon: Icons.calendar_today_rounded,
          label: 'I know the exact date',
          value: _lastPeriodDate == null
              ? 'Tap to pick a date'
              : DateFormat('EEE, MMM d, yyyy').format(_lastPeriodDate!),
          selected: _lastPeriodDate != null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _lastPeriodDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _lastPeriodDate = picked;
                _notSureRange = null;
              });
            }
          },
        ),
        const SizedBox(height: 14),
        _DateTile(
          icon: Icons.help_outline_rounded,
          label: 'I\'m not sure — give me a range',
          value: _notSureRange == null
              ? 'Tap to pick a date range'
              : '${DateFormat('MMM d').format(_notSureRange!.start)} → ${DateFormat('MMM d').format(_notSureRange!.end)}',
          selected: _notSureRange != null,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: now.subtract(const Duration(days: 365)),
              lastDate: now,
              initialDateRange: _notSureRange ??
                  DateTimeRange(
                    start: now.subtract(const Duration(days: 21)),
                    end: now.subtract(const Duration(days: 14)),
                  ),
            );
            if (picked != null) {
              setState(() {
                _notSureRange = picked;
                _lastPeriodDate = null;
              });
            }
          },
        ),
      ],
    );
  }

  // --- Page 2: cycle length wheel picker ---
  Widget _page2CycleLength() {
    return Center(
      child: NumberWheelPicker(
        min: AppConstants.minCycleLength,
        max: AppConstants.maxCycleLength,
        value: _cycleLength,
        unit: 'days',
        accent: AppColors.primary,
        onChanged: (v) => setState(() => _cycleLength = v),
      ),
    );
  }

  // --- Page 3: period length ---
  Widget _page3PeriodLength() {
    return Center(
      child: NumberWheelPicker(
        min: AppConstants.minPeriodLength,
        max: AppConstants.maxPeriodLength,
        value: _periodLength,
        unit: 'days bleeding',
        accent: AppColors.period,
        onChanged: (v) => setState(() => _periodLength = v),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.10)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primaryLight.withOpacity(0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
