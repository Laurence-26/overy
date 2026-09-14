import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/tracking_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/cycle_provider.dart';
import 'setup/conception_setup_flow.dart';
import 'setup/period_setup_flow.dart';
import 'setup/pregnancy_setup_flow.dart';

/// "Welcome [username] you're ready to track" + three animated mode cards.
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _cardAnims;
  late final Animation<double> _greetingFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _greetingFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _cardAnims = List.generate(3, (i) {
      final start = 0.30 + i * 0.18;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, (start + 0.40).clamp(0, 1),
            curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(TrackingMode mode) async {
    await context.read<CycleProvider>().setTrackingMode(mode);
    if (!mounted) return;
    final next = switch (mode) {
      TrackingMode.period => const PeriodSetupFlow(),
      TrackingMode.conception => const ConceptionSetupFlow(),
      TrackingMode.pregnancy => const PregnancySetupFlow(),
    };
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, c) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));
          return SlideTransition(
            position: offset,
            child: FadeTransition(opacity: a, child: c),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final auth = context.watch<AuthProvider>();
    final name = cycle.profile?.username ??
        cycle.profile?.displayName?.split('').first ??
        auth.user?.displayName?.split('').first ??
        'there';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE5EC),
                    Color(0xFFFFF5F7),
                    Color(0xFFF3E8FF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -30,
            child: _blob(160, AppColors.primaryLight.withOpacity(0.55)),
          ),
          Positioned(
            top: 40,
            right: -40,
            child: _blob(120, AppColors.accentLight.withOpacity(0.55)),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16),
                  FadeTransition(
                    opacity: _greetingFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(_greetingFade),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 12),
                          Text(
                            'Welcome, $name',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "you're ready to track.",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'What would you like to focus on today?',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 36),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _animatedCard(
                          anim: _cardAnims[0],
                          card: _ModeCard(
                            icon: Icons.water_drop_rounded,
                            title: 'Period',
                            subtitle: 'Track your monthly cycle',
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8FA3), Color(0xFFFF6B9D)],
                            ),
                            onTap: () => _select(TrackingMode.period),
                          ),
                        ),
                        SizedBox(height: 16),
                        _animatedCard(
                          anim: _cardAnims[1],
                          card: _ModeCard(
                            icon: Icons.favorite_rounded,
                            title: 'Get pregnant',
                            subtitle: 'Plan your conception journey',
                            gradient: LinearGradient(
                              colors: [Color(0xFF8AC8B8), Color(0xFF5BB4A0)],
                            ),
                            onTap: () => _select(TrackingMode.conception),
                          ),
                        ),
                        SizedBox(height: 16),
                        _animatedCard(
                          anim: _cardAnims[2],
                          card: _ModeCard(
                            icon: Icons.pregnant_woman_rounded,
                            title: 'Pregnancy',
                            subtitle: 'Follow your weekly journey',
                            gradient: LinearGradient(
                              colors: [Color(0xFFBFA9FF), Color(0xFFA78BFA)],
                            ),
                            onTap: () => _select(TrackingMode.pregnancy),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'You can switch modes anytime in Profile.',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCard(
      {required Animation<double> anim, required Widget card}) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final v = anim.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 32),
            child: Transform.scale(
              scale: 0.92 + 0.08 * v,
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 110,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (gradient.colors.last).withOpacity(0.30),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
