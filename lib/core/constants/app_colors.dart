import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primarySurface = Color(0xFFE0F2FE);
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF22D3EE);

  // ── Light theme ────────────────────────────────────
  static const Color background = Color(0xFFF0F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Dark theme ─────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF131C2E);
  static const Color darkSurfaceVariant = Color(0xFF1A2540);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  static const Color darkBorder = Color(0xFF1E2D4A);
  static const Color darkDivider = Color(0xFF162032);

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // ── Cards (same in both themes) ────────────────────
  static const Color card1 = Color(0xFF0EA5E9);
  static const Color card2 = Color(0xFF8B5CF6);
  static const Color card3 = Color(0xFF10B981);
  static const Color card4 = Color(0xFFF43F5E);
  static const Color card5 = Color(0xFFF59E0B);
  static const Color card6 = Color(0xFF06B6D4);

  // ── Gradient constants ─────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  );

  static const LinearGradient primaryDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF0284C7),
      Color(0xFF0369A1),
      Color(0xFF0EA5E9),
    ],
  );

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF38BDF8),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131C2E), Color(0xFF1A2540)],
  );

  // ── Dynamic helpers (use these in widgets) ─────────
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : background;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : surface;

  static Color surfaceVariantColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceVariant
          : surfaceVariant;

  static Color textPri(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : textPrimary;

  static Color textSec(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : textSecondary;

  static Color textHi(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextHint
          : textHint;

  static Color borderC(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorder
          : border;

  static Color dividerC(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkDivider
          : divider;
}
