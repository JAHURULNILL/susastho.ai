import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_design.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.pageBg,
        surfaceColor: AppColors.white,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        border: AppColors.border,
        isDark: false,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07120D),
        surfaceColor: const Color(0xFF0E1B15),
        textPrimary: const Color(0xFFF3FBF6),
        textSecondary: const Color(0xFFB8D2C1),
        border: const Color(0xFF1C342A),
        isDark: true,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    required bool isDark,
  }) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      useMaterial3: true,
    );

    final textTheme = TextTheme(
      headlineLarge: AppTextStyles.screenTitle.copyWith(fontSize: 28, color: textPrimary),
      headlineMedium: AppTextStyles.screenTitle.copyWith(color: textPrimary),
      headlineSmall: AppTextStyles.cardTitle.copyWith(fontSize: 20, color: textPrimary),
      titleLarge: AppTextStyles.cardTitle.copyWith(color: textPrimary),
      titleMedium: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: textPrimary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
      bodyMedium: AppTextStyles.body.copyWith(color: textSecondary),
      bodySmall: AppTextStyles.caption.copyWith(color: textSecondary.withValues(alpha: 0.88)),
      labelLarge: GoogleFonts.notoSansBengali(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: AppTextStyles.screenTitle.copyWith(fontSize: 24, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF102119) : AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.body.copyWith(color: isDark ? textSecondary.withValues(alpha: 0.7) : AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: border,
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        subtitleTextStyle: AppTextStyles.caption.copyWith(color: textSecondary),
      ),
    );
  }
}
