import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'auth/get_started_screen.dart';
import 'auth/sign_in_screen.dart';

/// First screen new users see after the splash. Marketing-style hero with
/// "Get started" and "I already have an account".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Soft gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
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
          // Decorative blobs
          Positioned(
            top: -60,
            right: -40,
            child: _blob(180, AppColors.primaryLight.withOpacity(0.55)),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _blob(140, AppColors.accentLight.withOpacity(0.55)),
          ),
          Positioned(
            bottom: 220,
            right: -50,
            child: _blob(160, AppColors.fertile.withOpacity(0.35)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.spa_rounded,
                          color: Colors.white, size: 56),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Your body,\nbeautifully understood',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Track your period, plan a pregnancy, or follow your journey week by week — all in one calm, private space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const Spacer(),
                  GradientButton(
                    label: 'Get started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.of(context).push(
                      _fadeRoute(const GetStartedScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      _fadeRoute(const SignInScreen()),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Partner sign-in entry — opens the same sign-in flow but
                  // routes to PartnerHomeScreen after success.
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      _fadeRoute(const SignInScreen(asPartner: true)),
                    ),
                    icon: const Icon(Icons.favorite_rounded,
                        color: AppColors.accent, size: 18),
                    label: const Text(
                      'Sign in as a partner',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Route _fadeRoute(Widget child) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      );
}
