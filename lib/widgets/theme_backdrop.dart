import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_look.dart';
import '../providers/theme_provider.dart';
import '../services/theme_background_store.dart';

/// Soft decorative motifs + optional user photo behind content.
class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final motif = theme.motif;
    final prefs = theme.prefs;
    final rawPath = prefs.backgroundImagePath;
    final cleanPath = ThemeBackgroundStore.stripCacheBust(rawPath);
    final hasImage =
        cleanPath != null && ThemeBackgroundStore.exists(rawPath);
    final strength = prefs.backgroundImageStrength.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.softGradient),
        ),
        if (hasImage)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              opacity: strength,
              child: Image.file(
                File(cleanPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (hasImage)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // High strength = vivid photo (light wash). Low = soft wash.
                    colors: [
                      AppColors.background
                          .withOpacity(0.10 + (1 - strength) * 0.72),
                      AppColors.background
                          .withOpacity(0.18 + (1 - strength) * 0.70),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Gentle top/bottom scrim so headers & nav stay readable even at
        // vivid photo strength — cards themselves are solid elsewhere.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(hasImage ? 0.18 : 0.0),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background.withOpacity(hasImage ? 0.28 : 0.0),
                  ],
                  stops: const [0, 0.18, 0.78, 1],
                ),
              ),
            ),
          ),
        ),
        if (motif != AppMotif.none)
          Positioned.fill(
            child: CustomPaint(
              painter: _MotifPainter(
                motif: motif,
                primary: AppColors.primary.withOpacity(hasImage ? 0.10 : 0.14),
                accent: AppColors.accent.withOpacity(hasImage ? 0.08 : 0.12),
                light: AppColors.primaryLight.withOpacity(hasImage ? 0.16 : 0.22),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _MotifPainter extends CustomPainter {
  _MotifPainter({
    required this.motif,
    required this.primary,
    required this.accent,
    required this.light,
  });

  final AppMotif motif;
  final Color primary;
  final Color accent;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    switch (motif) {
      case AppMotif.flowers:
        _flowers(canvas, size);
      case AppMotif.lavender:
        _lavender(canvas, size);
      case AppMotif.hearts:
        _hearts(canvas, size);
      case AppMotif.sparkles:
        _sparkles(canvas, size);
      case AppMotif.leaves:
        _leaves(canvas, size);
      case AppMotif.none:
        break;
    }
  }

  void _flowers(Canvas canvas, Size size) {
    final spots = [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.88, size.height * 0.22),
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.18, size.height * 0.78),
      Offset(size.width * 0.5, size.height * 0.12),
    ];
    for (var i = 0; i < spots.length; i++) {
      _drawFlower(
          canvas, spots[i], 18 + (i % 3) * 4, i.isEven ? primary : accent);
    }
  }

  void _drawFlower(Canvas canvas, Offset c, double r, Color color) {
    final petal = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final a = i * (2 * math.pi / 5) - math.pi / 2;
      final p = c + Offset(math.cos(a) * r * 0.55, math.sin(a) * r * 0.55);
      canvas.drawCircle(p, r * 0.42, petal);
    }
    canvas.drawCircle(c, r * 0.28, Paint()..color = light);
  }

  void _lavender(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final stems = [
      Offset(size.width * 0.1, size.height * 0.85),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.25),
    ];
    for (final base in stems) {
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
            base.dx + 8, base.dy - 60, base.dx - 4, base.dy - 110);
      canvas.drawPath(path, paint);
      for (var i = 0; i < 6; i++) {
        final t = 0.3 + i * 0.1;
        final y = base.dy - 110 * t;
        final x = base.dx + (i.isEven ? -6.0 : 6.0);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 10, height: 16),
          Paint()..color = i.isEven ? primary : accent,
        );
      }
    }
  }

  void _hearts(Canvas canvas, Size size) {
    final spots = [
      (Offset(size.width * 0.15, size.height * 0.2), 14.0),
      (Offset(size.width * 0.85, size.height * 0.28), 10.0),
      (Offset(size.width * 0.75, size.height * 0.75), 16.0),
      (Offset(size.width * 0.22, size.height * 0.7), 11.0),
      (Offset(size.width * 0.55, size.height * 0.15), 9.0),
    ];
    for (final s in spots) {
      _drawHeart(canvas, s.$1, s.$2, primary);
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Color color) {
    final path = Path();
    path.moveTo(c.dx, c.dy + s * 0.35);
    path.cubicTo(c.dx - s, c.dy - s * 0.2, c.dx - s * 0.9, c.dy - s, c.dx,
        c.dy - s * 0.45);
    path.cubicTo(c.dx + s * 0.9, c.dy - s, c.dx + s, c.dy - s * 0.2, c.dx,
        c.dy + s * 0.35);
    canvas.drawPath(path, Paint()..color = color);
  }

  void _sparkles(Canvas canvas, Size size) {
    final spots = [
      Offset(size.width * 0.2, size.height * 0.18),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.65),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.55),
    ];
    for (var i = 0; i < spots.length; i++) {
      _drawSparkle(
          canvas, spots[i], 8 + (i % 3) * 3, i.isEven ? primary : accent);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx - r * 0.7, c.dy - r * 0.7),
        Offset(c.dx + r * 0.7, c.dy + r * 0.7), paint);
    canvas.drawLine(Offset(c.dx + r * 0.7, c.dy - r * 0.7),
        Offset(c.dx - r * 0.7, c.dy + r * 0.7), paint);
  }

  void _leaves(Canvas canvas, Size size) {
    final spots = [
      Offset(size.width * 0.12, size.height * 0.2),
      Offset(size.width * 0.88, size.height * 0.25),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.75),
    ];
    for (var i = 0; i < spots.length; i++) {
      _drawLeaf(canvas, spots[i], 22, i.isEven ? primary : accent, i * 0.4);
    }
  }

  void _drawLeaf(Canvas canvas, Offset c, double s, Color color, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final path = Path()
      ..moveTo(0, -s)
      ..quadraticBezierTo(s * 0.7, -s * 0.2, 0, s)
      ..quadraticBezierTo(-s * 0.7, -s * 0.2, 0, -s);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.motif != motif || old.primary != primary;
}
