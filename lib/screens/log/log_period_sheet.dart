import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/gradient_button.dart';

Future<void> showLogPeriodSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogPeriodSheet(),
  );
}

class _LogPeriodSheet extends StatefulWidget {
  const _LogPeriodSheet();

  @override
  State<_LogPeriodSheet> createState() => _LogPeriodSheetState();
}

class _LogPeriodSheetState extends State<_LogPeriodSheet> {
  DateTime _startDate = DateTime.now();
  bool _isEnding = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final active =
        cycle.currentCycle != null && cycle.currentCycle!.cycleLength == null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 18),
            Text(
              _isEnding ? 'End your period' : 'Log your period',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _isEnding
                  ? 'When did your period end?'
                  : 'When did your period start?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            // Date picker tile
            Material(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d').format(_startDate),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
            if (active) ...[
              SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isEnding,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isEnding = v),
                title: Text("I'm ending this period"),
                subtitle: Text(
                  'Started ${DateFormat('MMM d').format(cycle.currentCycle!.startDate)}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
            SizedBox(height: 20),
            GradientButton(
              label: _isEnding ? 'End period' : 'Start new period',
              loading: _saving,
              icon: _isEnding
                  ? Icons.check_circle_outline
                  : Icons.water_drop_rounded,
              onPressed: _saving ? null : () => _submit(active),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(bool hasActive) async {
    setState(() => _saving = true);
    final cycle = context.read<CycleProvider>();
    try {
      if (_isEnding && hasActive) {
        await cycle.endPeriod(_startDate);
      } else {
        await cycle.startPeriod(_startDate);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
