import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/choice_tile.dart';
import '../home/home_shell.dart';
import 'setup_scaffold.dart';

class ConceptionSetupFlow extends StatefulWidget {
  const ConceptionSetupFlow({super.key});

  @override
  State<ConceptionSetupFlow> createState() => _ConceptionSetupFlowState();
}

class _ConceptionSetupFlowState extends State<ConceptionSetupFlow> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _saving = false;

  static const _accent = Color(0xFF5BB4A0);

  // Page 1
  bool? _hasIrregularCycles;
  // Page 2
  final Set<String> _conditions = {};
  bool? _takingVitamins;
  // Page 3
  DateTime? _lastPeriodDate;

  bool get _canContinue {
    switch (_page) {
      case 0:
        return _hasIrregularCycles != null;
      case 1:
        return _takingVitamins != null;
      case 2:
        return _lastPeriodDate != null;
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

    try {
      await cycle
          .startPeriod(_lastPeriodDate!)
          .timeout(const Duration(seconds: 15));
      if (profile != null) {
        await cycle
            .updateProfile(profile.copyWith(
              hasIrregularCycles: _hasIrregularCycles,
              hasMedicalConditions: _conditions.isNotEmpty,
              medicalConditions: _conditions.toList(),
              takingPrenatalVitamins: _takingVitamins,
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
      ('How are your cycles, usually?',
          'This helps us tailor your high-chance days more accurately.'),
      ('A bit about your health',
          'Optional info — we use this only to personalize your guidance.'),
      ('When did your last period start?',
          'We need this to estimate your next high-chance window.'),
    ];

    return SetupScaffold(
      currentPage: _page,
      totalPages: 3,
      title: titles[_page].$1,
      subtitle: titles[_page].$2,
      primaryLabel: _page == 2 ? 'Start journey' : 'Continue',
      primaryLoading: _saving,
      accent: _accent,
      onBack: _back,
      onPrimary: !_canContinue || _saving ? null : _next,
      child: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _page1Cycles(),
          _page2Health(),
          _page3LastPeriod(),
        ],
      ),
    );
  }

  Widget _page1Cycles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'Regular',
          subtitle: 'My cycles are usually predictable',
          accent: _accent,
          selected: _hasIrregularCycles == false,
          onTap: () => setState(() => _hasIrregularCycles = false),
        ),
        const SizedBox(height: 12),
        ChoiceTile(
          icon: Icons.timeline_rounded,
          label: 'Irregular',
          subtitle: 'My cycles vary by more than a week',
          accent: _accent,
          selected: _hasIrregularCycles == true,
          onTap: () => setState(() => _hasIrregularCycles = true),
        ),
      ],
    );
  }

  Widget _page2Health() {
    final commonConditions = const [
      'PCOS',
      'Endometriosis',
      'Thyroid',
      'Diabetes',
      'High blood pressure',
      'None',
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Any conditions we should know about?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 24),
          const Text(
            'Are you taking prenatal vitamins?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ChoiceTile(
            icon: Icons.medication_rounded,
            label: 'Yes, daily',
            accent: _accent,
            selected: _takingVitamins == true,
            onTap: () => setState(() => _takingVitamins = true),
          ),
          const SizedBox(height: 10),
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

  Widget _page3LastPeriod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _lastPeriodDate ?? DateTime.now(),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _lastPeriodDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _lastPeriodDate != null
                    ? _accent.withOpacity(0.10)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _lastPeriodDate != null
                      ? _accent
                      : _accent.withOpacity(0.25),
                  width: _lastPeriodDate != null ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _accent, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    _lastPeriodDate == null
                        ? 'Tap to pick a date'
                        : DateFormat('EEEE, MMM d, yyyy')
                            .format(_lastPeriodDate!),
                    style: const TextStyle(
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
}
