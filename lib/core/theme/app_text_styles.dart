import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(double size, FontWeight weight, Color color) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle display = _base(40, FontWeight.bold, AppColors.textPrimary);
  static TextStyle heading1 = _base(32, FontWeight.bold, AppColors.textPrimary);
  static TextStyle heading2 = _base(28, FontWeight.bold, AppColors.textPrimary);
  static TextStyle heading3 = _base(24, FontWeight.w600, AppColors.textPrimary);
  static TextStyle title = _base(20, FontWeight.w600, AppColors.textPrimary);
  static TextStyle subtitle = _base(18, FontWeight.w500, AppColors.textPrimary);
  static TextStyle body = _base(16, FontWeight.normal, AppColors.textPrimary);
  static TextStyle small = _base(
    14,
    FontWeight.normal,
    AppColors.textSecondary,
  );
  static TextStyle caption = _base(
    12,
    FontWeight.normal,
    AppColors.textSecondary,
  );
}
