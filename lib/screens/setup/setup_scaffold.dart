import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

/// Shared scaffold used by all three setup flows. Provides a soft gradient
/// background, progress dots, an animated PageView area, a step title, and
/// a primary "Continue" button.
class SetupScaffold extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String title;
  final String subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;
  final bool primaryLoading;
  final Color accent;

  const SetupScaffold({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onPrimary,
    this.primaryLabel = 'Continue',
    this.onBack,
    this.primaryLoading = false,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                const SizedBox(height: 8),
                _progressDots(),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: child,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: GradientButton(
                    label: primaryLabel,
                    icon: Icons.arrow_forward_rounded,
                    loading: primaryLoading,
                    onPressed: onPrimary,
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.85), accent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          const Spacer(),
          Text(
            'Step ${currentPage + 1} of $totalPages',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final active = i == currentPage;
        final done = i < currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active || done
                ? accent
                : accent.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
