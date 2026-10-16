import 'package:flutter/material.dart';

/// MRTap's palette.
///
/// One saturated brand green carries the whole interface. Everything else is a
/// neutral ramp so the green always reads as "the thing you tap or the thing you
/// selected". Status colours are reserved for genuine status: they are never
/// used decoratively.
abstract final class AppColors {
  /// Brand / primary. `#0A7A3B`.
  static const Color primary = Color(0xFF0A7A3B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6F1E0);
  static const Color onPrimaryContainer = Color(0xFF06421F);

  /// Canvas and surfaces.
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F6);

  /// Text.
  static const Color textPrimary = Color(0xFF17202B);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textDisabled = Color(0xFF98A2B3);

  /// Hairlines and separators.
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD0D5DD);

  /// Status.
  static const Color success = Color(0xFF1B7F4B);
  static const Color successContainer = Color(0xFFDCF3E6);
  static const Color warning = Color(0xFFB54708);
  static const Color warningContainer = Color(0xFFFFF0E0);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerContainer = Color(0xFFFDECEA);
}

/// Dark counterparts, used when the user picks dark or follows the system.
abstract final class AppDarkColors {
  static const Color primary = Color(0xFF6FD79B);
  static const Color onPrimary = Color(0xFF04240F);
  static const Color primaryContainer = Color(0xFF14502C);
  static const Color onPrimaryContainer = Color(0xFFD6F1E0);

  static const Color background = Color(0xFF0E1420);
  static const Color surface = Color(0xFF161D2A);
  static const Color surfaceVariant = Color(0xFF1E2735);

  static const Color textPrimary = Color(0xFFE6EAF2);
  static const Color textSecondary = Color(0xFF9AA7BC);
  static const Color textDisabled = Color(0xFF6B7789);

  static const Color border = Color(0xFF26303F);
  static const Color borderStrong = Color(0xFF35414F);

  static const Color success = Color(0xFF6FD79B);
  static const Color successContainer = Color(0xFF123524);
  static const Color warning = Color(0xFFF5B26A);
  static const Color warningContainer = Color(0xFF3A2712);
  static const Color danger = Color(0xFFF79A8E);
  static const Color dangerContainer = Color(0xFF3B1A16);
}
