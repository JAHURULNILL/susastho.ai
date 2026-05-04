import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double screenPadding = 16;
  static const double cardGap = 12;
}

class AppTextStyles {
  const AppTextStyles._();

  static final TextStyle screenTitle = GoogleFonts.notoSansBengali(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle cardTitle = GoogleFonts.notoSansBengali(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyLarge = GoogleFonts.notoSansBengali(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle body = GoogleFonts.notoSansBengali(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static final TextStyle caption = GoogleFonts.notoSansBengali(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static final TextStyle metric = GoogleFonts.dmSerifDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final TextStyle metricSmall = GoogleFonts.dmSerifDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

class AppCardStyles {
  const AppCardStyles._();

  static BoxDecoration base({
    Color backgroundColor = AppColors.white,
    Color borderColor = AppColors.border,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(13, 44, 28, 0.05),
          offset: Offset(0, 2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Color.fromRGBO(45, 106, 79, 0.09),
          offset: Offset(0, 10),
          blurRadius: 24,
          spreadRadius: -6,
        ),
        BoxShadow(
          color: Color.fromRGBO(255, 255, 255, 0.65),
          offset: Offset(0, 1),
          blurRadius: 0,
        ),
      ],
    );
  }
}
