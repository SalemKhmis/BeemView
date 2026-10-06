import 'package:flutter/material.dart';

/// Application theme configuration using Material 3 (Light & Dark themes).
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF1E96BE); // BeemView Teal/Blue
  static const Color secondaryColor = Color(0xFFFAAA3C); // BeemView Amber/Orange
  static const Color darkTeal = Color(0xFF0E5A73);
  static const Color mintGreen = Color(0xFF52B79A);
  static const Color _errorColor = Color(0xFFD32F2F);

  // ── Status Colors ─────────────────────────────────────────────
  static const Color statusToDo = Color(0xFF9E9E9E);
  static const Color statusInProgress = Color(0xFF1E96BE);
  static const Color statusOnHold = Color(0xFFFAAA3C);
  static const Color statusReview = Color(0xFF9C27B0);
  static const Color statusChangesRequested = Color(0xFFFF5722);
  static const Color statusBlocked = Color(0xFFF44336);
  static const Color statusDone = Color(0xFF4CAF50);
  static const Color statusCanceled = Color(0xFF607D8B);

  // ── Priority Colors ───────────────────────────────────────────
  static const Color priorityLow = Color(0xFF8BC34A);
  static const Color priorityMedium = Color(0xFFFAAA3C);
  static const Color priorityHigh = Color(0xFFFF7043);
  static const Color priorityUrgent = Color(0xFFF44336);

  // ── Light Theme ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
      error: _errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: const Color(0xFF38BDF8), // Vibrant cyan for dark mode
      secondary: secondaryColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B), // Slate 800
      surfaceContainerLowest: const Color(0xFF0B1120), // Darker slate
      surfaceContainerLow: const Color(0xFF0F172A), // Slate 900
      surfaceContainer: const Color(0xFF1E293B),
      surfaceContainerHigh: const Color(0xFF27354A),
      surfaceContainerHighest: const Color(0xFF334155), // Slate 700
      onSurface: const Color(0xFFF1F5F9), // Slate 100
      onSurfaceVariant: const Color(0xFF94A3B8), // Slate 400
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF334155),
      error: const Color(0xFFEF4444),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
        modalBackgroundColor: Color(0xFF1E293B),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF141E30),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.black, // High contrast text on bright cyan
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
    );
  }

  /// Returns the color associated with a given task status API value.
  static Color statusColor(String status) {
    return switch (status) {
      'to_do' => statusToDo,
      'in_progress' => statusInProgress,
      'on_hold' => statusOnHold,
      'review' => statusReview,
      'changes_requested' => statusChangesRequested,
      'blocked' => statusBlocked,
      'done' => statusDone,
      'canceled' => statusCanceled,
      _ => statusToDo,
    };
  }

  /// Returns the color associated with a given task priority value.
  static Color priorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'low' => priorityLow,
      'medium' => priorityMedium,
      'high' => priorityHigh,
      'urgent' => priorityUrgent,
      _ => priorityMedium,
    };
  }
}
