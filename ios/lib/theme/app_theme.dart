import 'package:flutter/material.dart';

class ArcticPalette {
  static const lightBackground = Color(0xFFF4F7FF);
  static const lightSurface = Color(0xFFFCFDFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFF0F3FF);

  static const darkBackground = Color(0xFF090B16);
  static const darkSurface = Color(0xFF0E1020);
  static const darkCard = Color(0xFF14172A);
  static const darkRaised = Color(0xFF1B1E35);

  static const purple = Color(0xFF6E50F5);
  static const lavender = Color(0xFFA98CFF);
  static const ice = Color(0xFF64CCFF);
  static const glacier = Color(0xFFB9ECFF);

  static LinearGradient headerGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF24204A), Color(0xFF141C39), Color(0xFF10283A)]
          : const [Color(0xFFE9E4FF), Color(0xFFEAF2FF), Color(0xFFE5F8FF)],
    );
  }

  static LinearGradient accentGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFFA98CFF), Color(0xFF6F8FFF), Color(0xFF64CCFF)]
          : const [Color(0xFF6848E8), Color(0xFF617AF2), Color(0xFF38AEE8)],
    );
  }
}

class AppCardDecoration {
  static BoxDecoration standard(
    BuildContext context, {
    Color? color,
    Color? borderColor,
    double radius = AppRadius.card,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: color ?? theme.cardTheme.color ??
          (isDark ? ArcticPalette.darkCard : ArcticPalette.lightCard),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? ArcticPalette.lavender.withValues(alpha: 0.18)
                : ArcticPalette.purple.withValues(alpha: 0.14)),
        width: 1.15,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.22)
              : const Color(0xFF41357A).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
}

class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const card = 18.0;
  static const button = 13.0;
  static const pill = 999.0;
}

class AppTypography {
  static const pageTitle = 25.0;
  static const title = 18.0;
  static const primary = 16.0;
  static const body = 14.0;
  static const caption = 12.0;
  static const micro = 11.0;
}

class AppIcon {
  static const xs = 16.0;
  static const sm = 18.0;
  static const md = 22.0;
  static const lg = 26.0;
}
