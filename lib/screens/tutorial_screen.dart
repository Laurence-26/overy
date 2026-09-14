import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/tracking_mode.dart';
import '../providers/cycle_provider.dart';
import '../widgets/gradient_button.dart';

/// First-run tutorial. Shows mode-aware pages explaining the home, calendar,
/// log, insights, partner sharing - with a Skip in the top-right.
///
/// When the user taps Skip or finishes, `profile.hasSeenTutorial` is set to
/// true so it never auto-shows again. They can replay it from Profile.
class TutorialScreen extends StatefulWidget {
  /// True when the user opened the tutorial manually (so the X / Skip should
  /// just pop, not mark the flag - flag is already true).
  final bool replay;

  const TutorialScreen({super.key, this.replay = false});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  List<_TutorialStep> _stepsForMode(TrackingMode? mode) {
    final m = mode ?? TrackingMode.period;
    return [
      _TutorialStep(
        icon: Icons.spa_rounded,
        color: AppColors.primary,
        title: 'Welcome to Cyclus',
        body:
            'A calm space to track your cycle, plan a pregnancy, or follow your journey week by week - all private to you.',
      ),
      switch (m) {
        TrackingMode.period => _TutorialStep(
            icon: Icons.water_drop_rounded,
            color: AppColors.period,
            title: 'Log your period in one tap',
            body:
                'On the Today screen, tap "Period started today" the moment your period begins. We close the previous cycle and start a fresh one automatically.',
          ),
        TrackingMode.conception => _TutorialStep(
            icon: Icons.eco_rounded,
            color: AppColors.fertile,
            title: 'See your high-chance days',
            body:
                'Today and Calendar both highlight your high-chance window. Days marked green are your most fertile.',
          ),
        TrackingMode.pregnancy => _TutorialStep(
            icon: Icons.child_friendly_rounded,
            color: AppColors.accent,
            title: 'Follow your pregnancy week by week',
            body:
                'The Today ring shows your progress to your due date. Log baby kicks anytime - they\'re saved to your daily log.',
          ),
      },
      _TutorialStep(
        icon: Icons.calendar_month_rounded,
        color: AppColors.accent,
        title: 'Calendar at a glance',
        body:
            'Tap any day to see or edit that day\'s flow, symptoms, mood, and notes. White circles are safe days; green is fertile; red is your period.',
      ),
      _TutorialStep(
        icon: Icons.notifications_active_rounded,
        color: AppColors.warning,
        title: 'Gentle reminders 3, 2 & 1 day ahead',
        body:
            'We send you a heads-up before your period and your fertile window. Adjust the time in Profile > Preferences.',
      ),
      _TutorialStep(
        icon: Icons.favorite_rounded,
        color: AppColors.primary,
        title: 'Share with a partner (optional)',
        body:
            'Generate a 6-digit code in Profile > Partner sharing. Your partner connects with it and sees your current phase - read-only.',
      ),
    ];
  }

  Future<void> _finish() async {
    if (!widget.replay) {
      // Persist the dismissal so we don't show it again on next launch.
      final cycle = context.read<CycleProvider>();
      final p = cycle.profile;
      if (p != null) {
        await cycle.updateProfile(p.copyWith(hasSeenTutorial: true));
      }
    }
    if (!mounted) return;
    if (widget.replay) {
      Navigator.of(context).pop();
    } else {
      // _Root will see hasSeenTutorial=true and render HomeShell.
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<CycleProvider>().profile?.trackingMode;
    final steps = _stepsForMode(mode);
    final isLast = _page == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip on the right (or X if replaying).
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_page + 1} / ${steps.length}',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(widget.replay ? 'Close' : 'Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _TutorialPage(step: steps[i]),
              ),
            ),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: GradientButton(
                label: isLast ? 'Get started' : 'Next',
                icon: isLast
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _TutorialStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _TutorialPage extends StatelessWidget {
  final _TutorialStep step;
  const _TutorialPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  step.color.withOpacity(0.12),
                  step.color.withOpacity(0.35),
                ],
              ),
            ),
            child: Icon(step.icon, size: 80, color: step.color),
          ),
          SizedBox(height: 36),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
