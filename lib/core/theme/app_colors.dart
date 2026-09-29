import 'package:flutter/material.dart';

/// MediFlow HMS colour palette.
/// All colours are defined here — no ad-hoc color literals elsewhere.
class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);        // Medical blue
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primaryContainer = Color(0xFFD2E3FC);

  // ── Secondary / Accent ─────────────────────────────────────────
  static const Color secondary = Color(0xFF00BCD4);      // Teal accent
  static const Color secondaryDark = Color(0xFF00838F);
  static const Color secondaryLight = Color(0xFFE0F7FA);

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF34A853);
  static const Color successLight = Color(0xFFE6F4EA);
  static const Color warning = Color(0xFFFBBC04);
  static const Color warningLight = Color(0xFFFEF7E0);
  static const Color error = Color(0xFFEA4335);
  static const Color errorLight = Color(0xFFFCE8E6);
  static const Color info = Color(0xFF4285F4);
  static const Color infoLight = Color(0xFFE8F0FE);

  // ── Emergency / Priority ───────────────────────────────────────
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyLight = Color(0xFFFFEBEE);
  static const Color regular = Color(0xFF1A73E8);
  static const Color regularLight = Color(0xFFE8F0FE);

  // ── Queue Status ───────────────────────────────────────────────
  static const Color queueWaiting = Color(0xFFFBBC04);
  static const Color queueCalled = Color(0xFF4285F4);
  static const Color queueInProgress = Color(0xFF34A853);
  static const Color queueCompleted = Color(0xFF9E9E9E);
  static const Color queueNoShow = Color(0xFFD32F2F);
  static const Color queueSkipped = Color(0xFFFF9800);
  static const Color queueCancelled = Color(0xFF757575);
  static const Color queueTransferred = Color(0xFF7B1FA2);

  // ── Backgrounds ────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFF);
  static const Color scaffoldBackground = background;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Sidebar ────────────────────────────────────────────────────
  static const Color sidebarBackground = Color(0xFF0A1628);
  static const Color sidebarActive = Color(0xFF1A73E8);
  static const Color sidebarHover = Color(0xFF1C2E4A);
  static const Color sidebarText = Color(0xFFB0BEC5);
  static const Color sidebarActiveText = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Border / Divider ───────────────────────────────────────────
  static const Color border = Color(0xFFE0E4EB);
  static const Color divider = Color(0xFFEEF0F4);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
  );

  // ── Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];
}
