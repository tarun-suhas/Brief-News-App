import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Headers (Outfit - Sharp & Modern)
  static TextStyle h1 = GoogleFonts.outfit(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );

  static TextStyle h2 = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Feed Item Styles (Optimized for Editorial Layout)
  static TextStyle feedTitle = GoogleFonts.outfit(
    fontSize: 27, // Slightly smaller for better balance
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.6,
  );

  static TextStyle feedContent = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary.withValues(alpha: 0.9),
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Body Styles
  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500, // Medium weight for better readability in light mode
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  // Buttons, Labels & Badges
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.4,
  );

  static TextStyle badge = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 1.4,
  );
}
