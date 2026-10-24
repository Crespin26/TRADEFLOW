import 'package:flutter/material.dart';

abstract final class FlowColors {
  static const ink = Color(0xFF142C38);
  static const primary = Color(0xFF007F73);
  static const background = Color(0xFFF4F7F8);
  static const muted = Color(0xFF526773);
  static const border = Color(0xFFD5E1E3);
  static const warning = Color(0xFF8F5500);
  static const success = Color(0xFF176B43);
  static const error = Color(0xFFB3261E);
}

abstract final class FlowSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class FlowLayout {
  static const railBreakpoint = 900.0;
  static const contentWidth = 1120.0;
  static const radius = 16.0;
}

ThemeData buildTradeFlowTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: FlowColors.primary).copyWith(
    primary: FlowColors.primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: FlowColors.ink,
    onSurfaceVariant: FlowColors.muted,
    outline: FlowColors.border,
    error: FlowColors.error,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: FlowColors.background,
    textTheme: base.textTheme
        .apply(bodyColor: FlowColors.ink, displayColor: FlowColors.ink)
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          headlineSmall: const TextStyle(
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FlowColors.background,
      foregroundColor: FlowColors.ink,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(FlowSpace.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlowColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlowColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FlowColors.primary, width: 2),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlowLayout.radius),
        side: const BorderSide(color: FlowColors.border),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
