import 'package:flutter/material.dart';

class AppCardDecoration {
  static BoxDecoration standard(
    BuildContext context, {
    Color? color,
    Color? borderColor,
    double radius = AppRadius.card,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color:
          color ??
          theme.cardTheme.color ??
          (isDark ? const Color(0xFF19191F) : const Color(0xFFECE8F2)),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            borderColor ??
            colors.outline.withValues(alpha: isDark ? 0.48 : 0.45),
        width: 1.35,
      ),
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
  static const card = 16.0;
  static const button = 12.0;
  static const pill = 999.0;
}

class AppTypography {
  static const pageTitle = 24.0;
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
