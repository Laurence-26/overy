import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/choice_tile.dart';
import 'setup_scaffold.dart';

class PregnancySetupFlow extends StatefulWidget {
  const PregnancySetupFlow({super.key});

  @override
  State<PregnancySetupFlow> createState() => _PregnancySetupFlowState();
}

class _PregnancySetupFlowState extends State<PregnancySetupFlow> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _saving = false;

  static const _accent = Color(0xFFA78BFA);

  // Page 1 - pregnancy history
  int? _previousPregnancies;
  // Page 2 - health
  final Set<String> _conditions = {};
  bool? _takingVitamins;
  // Page 3 - LMP or due date
  bool _useDueDate = false;
  DateTime? _lastPeriodDate;
  DateTime? _dueDate;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _previousPregnancies != null;
      case 1:
        return _takingVitamins != null;
      case 2:
        return _useDueDate ? _dueDate != null : _lastPeriodDate != null;
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
    final profile = cycle.profile;

    try {
      if (profile != null) {
        await cycle
            .updateProfile(profile.copyWith(
              previousPregnancies: _previousPregnancies,
              hasMedicalConditions: _conditions.isNotEmpty,
              medicalConditions: _conditions.toList(),
              takingPrenatalVitamins: _takingVitamins,
              dueDate: _dueDate,
              lastMenstrualPeriod: _lastPeriodDate,
              setupComplete: true,
            ))
            .timeout(const Duration(seconds: 15));
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
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
      (
        'Is this your first pregnancy?',
        'Knowing this helps us give you the right kind of guidance.'
      ),
      (
        'A bit about your health',
        'Optional info - used only to personalize your journey.'
      ),
      (
        'When did your last period start?',
        'Or share your due date if you already know it.'
      ),
    ];

    return SetupScaffold(
      currentPage: _page,
      totalPages: 3,
      title: titles[_page].$1,
      subtitle: titles[_page].$2,
      primaryLabel: _page == 2 ? 'Begin journey' : 'Continue',
      primaryLoading: _saving,
      accent: _accent,
      onBack: _back,
      onPrimary: !_canContinue || _saving ? null : _next,
      child: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _page1History(),
          _page2Health(),
          _page3LmpOrDue(),
        ],
      ),
    );
  }

  Widget _page1History() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceTile(
          icon: Icons.favorite_rounded,
          label: 'Yes, this is my first',
          accent: _accent,
          selected: _previousPregnancies == 0,
          onTap: () => setState(() => _previousPregnancies = 0),
        ),
        SizedBox(height: 12),
        ChoiceTile(
          icon: Icons.child_friendly_rounded,
          label: 'I have one child',
          accent: _accent,
          selected: _previousPregnancies == 1,
          onTap: () => setState(() => _previousPregnancies = 1),
        ),
        SizedBox(height: 12),
        ChoiceTile(
          icon: Icons.family_restroom_rounded,
          label: 'Two or more',
          accent: _accent,
          selected: (_previousPregnancies ?? 0) >= 2,
          onTap: () => setState(() => _previousPregnancies = 2),
        ),
      ],
    );
  }

  Widget _page2Health() {
    const commonConditions = [
      'Gestational diabetes',
      'High blood pressure',
      'Thyroid',
      'Anemia',
      'Twin / multiple',
      'None',
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Any conditions we should know about?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commonConditions.map((c) {
              final selected = _conditions.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                selectedColor: _accent.withOpacity(0.20),
                checkmarkColor: _accent,
                onSelected: (v) => setState(() {
                  if (c == 'None') {
                    _conditions.clear();
                    if (v) _conditions.add('None');
                  } else {
                    _conditions.remove('None');
                    v ? _conditions.add(c) : _conditions.remove(c);
                  }
                }),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Are you taking prenatal vitamins?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          ChoiceTile(
            icon: Icons.medication_rounded,
            label: 'Yes, daily',
            accent: _accent,
            selected: _takingVitamins == true,
            onTap: () => setState(() => _takingVitamins = true),
          ),
          SizedBox(height: 10),
          ChoiceTile(
            icon: Icons.close_rounded,
            label: 'Not yet',
            accent: _accent,
            selected: _takingVitamins == false,
            onTap: () => setState(() => _takingVitamins = false),
          ),
        ],
      ),
    );
  }

  Widget _page3LmpOrDue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle row
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _toggle('Last period', !_useDueDate, () {
                setState(() => _useDueDate = false);
              })),
              Expanded(
                  child: _toggle('Due date', _useDueDate, () {
                setState(() => _useDueDate = true);
              })),
            ],
          ),
        ),
        SizedBox(height: 24),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final now = DateTime.now();
              final picked = _useDueDate
                  ? await showDatePicker(
                      context: context,
                      initialDate:
                          _dueDate ?? now.add(const Duration(days: 200)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 300)),
                    )
                  : await showDatePicker(
                      context: context,
                      initialDate: _lastPeriodDate ??
                          now.subtract(const Duration(days: 90)),
                      firstDate: now.subtract(const Duration(days: 300)),
                      lastDate: now,
                    );
              if (picked != null) {
                setState(() {
                  if (_useDueDate) {
                    _dueDate = picked;
                  } else {
                    _lastPeriodDate = picked;
                  }
                });
              }
            },
            child: Container(
              padding: EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _picked != null
                    ? _accent.withOpacity(0.10)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _picked != null ? _accent : _accent.withOpacity(0.25),
                  width: _picked != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                      _useDueDate
                          ? Icons.event_available_rounded
                          : Icons.calendar_today_rounded,
                      color: _accent,
                      size: 36),
                  SizedBox(height: 12),
                  Text(
                    _picked == null
                        ? 'Tap to pick a date'
                        : DateFormat('EEEE, MMM d, yyyy').format(_picked!),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime? get _picked => _useDueDate ? _dueDate : _lastPeriodDate;

  Widget _toggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
