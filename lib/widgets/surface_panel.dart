import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Soft frosted glass panel — tinted by theme, slightly see-through so the
/// background peeks through while text stays readable.
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.tint,
    this.onTap,
    this.borderColor,
    this.elevated = true,
    this.opacity = 0.62,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? tint;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool elevated;

  /// How opaque the glass fill is (0.45–0.75 feels best over photos).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppColors.cornerRadius.clamp(16, 28);
    final radius = BorderRadius.circular(r);
    final accent = tint ?? AppColors.primary;
    final o = opacity.clamp(0.45, 0.78);
    final fill = Color.alphaBlend(
      accent.withOpacity(0.12),
      Colors.white.withOpacity(o),
    );
    final fillEnd = Color.alphaBlend(
      accent.withOpacity(0.06),
      Colors.white.withOpacity((o - 0.08).clamp(0.4, 0.7)),
    );

    final glass = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [fill, fillEnd],
              ),
              border: Border.all(
                color: borderColor ??
                    Color.alphaBlend(
                      accent.withOpacity(0.32),
                      Colors.white.withOpacity(0.55),
                    ),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return glass;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: accent.withOpacity(0.12),
        highlightColor: accent.withOpacity(0.06),
        child: glass,
      ),
    );
  }
}

/// Soft frosted disc behind ring center text.
class RingCenterPlate extends StatelessWidget {
  const RingCenterPlate({super.key, required this.child, this.size = 168});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.86),
                  Color.alphaBlend(
                    AppColors.primary.withOpacity(0.10),
                    Colors.white.withOpacity(0.68),
                  ),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.92),
                width: 2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
