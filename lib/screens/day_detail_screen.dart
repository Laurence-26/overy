import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme/app_colors.dart';
import '../models/cycle_prediction.dart';
import '../models/daily_log.dart';
import '../models/tracking_mode.dart';
import '../providers/cycle_provider.dart';
import '../widgets/gradient_button.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;
  const DayDetailScreen({super.key, required this.date});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  String? _flow;
  Set<String> _symptoms = {};
  Set<String> _moods = {};
  late final TextEditingController _notesCtrl;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController();
  }

  void _hydrate(DailyLog? log) {
    if (_loaded || log == null) {
      _loaded = true;
      return;
    }
    _flow = log.flow;
    _symptoms = log.symptoms.toSet();
    _moods = log.moods.toSet();
    _notesCtrl.text = log.notes ?? '';
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final existing = cycle.logForDay(widget.date);
    _hydrate(existing);

    final phase = cycle.phaseFor(widget.date);
    final mode = cycle.trackingMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEE, MMM d').format(widget.date)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _phaseBanner(phase),
              SizedBox(height: 24),
              if (Symptoms.showsFlow(mode)) ...[
                _sectionLabel('Flow'),
                _flowSelector(),
                SizedBox(height: 24),
              ],
              _sectionLabel(
                  mode == TrackingMode.pregnancy ? 'How you feel' : 'Symptoms'),
              _chipGroup(Symptoms.physicalFor(mode), _symptoms),
              SizedBox(height: 24),
              _sectionLabel('Mood'),
              _chipGroup(Symptoms.moods, _moods),
              SizedBox(height: 24),
              _sectionLabel('Notes'),
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'How are you feeling today?',
                ),
              ),
              SizedBox(height: 28),
              GradientButton(
                label: 'Save',
                loading: _saving,
                icon: Icons.check_rounded,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _flowSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: Symptoms.flowLevels.map((level) {
        final selected = _flow == level;
        return ChoiceChip(
          label: Text(level),
          selected: selected,
          onSelected: (v) =>
              setState(() => _flow = (v && _flow != level) ? level : null),
          selectedColor: AppColors.period.withOpacity(0.25),
          backgroundColor: AppColors.surfaceAlt,
          labelStyle: TextStyle(
            color: selected ? AppColors.period : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? AppColors.period : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _chipGroup(List<String> items, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((s) {
        final selected = selectedSet.contains(s);
        return FilterChip(
          label: Text(s),
          selected: selected,
          onSelected: (v) {
            setState(() {
              if (v) {
                selectedSet.add(s);
              } else {
                selectedSet.remove(s);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _phaseBanner(CyclePhase phase) {
    final (color, label, icon) = switch (phase) {
      CyclePhase.period => (
          AppColors.period,
          'Period day',
          Icons.water_drop_rounded
        ),
      CyclePhase.fertile => (
          AppColors.fertile,
          'Fertile window',
          Icons.eco_rounded
        ),
      CyclePhase.ovulation => (
          AppColors.ovulation,
          'Ovulation',
          Icons.brightness_5_rounded
        ),
      CyclePhase.predicted => (
          AppColors.predicted,
          'Predicted period',
          Icons.calendar_today_rounded
        ),
      CyclePhase.follicular => (
          AppColors.accent,
          'Follicular phase',
          Icons.eco_outlined
        ),
      CyclePhase.luteal => (
          AppColors.accentDark,
          'Luteal phase',
          Icons.nights_stay_rounded
        ),
      CyclePhase.unknown => (
          AppColors.textTertiary,
          '-',
          Icons.help_outline_rounded
        ),
    };
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final log = DailyLog(
      date: widget.date,
      flow: _flow,
      symptoms: _symptoms.toList(),
      moods: _moods.toList(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await context.read<CycleProvider>().saveDailyLog(log);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }
}
