import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0B0C10); // أسود عميق
  static const Color surface = Color(0xFF1A0B2E); // بنفسجي داكن للبطاقات
  static const Color primary = Color(0xFFC026D3); // بنفسجي نيون
  static const Color accent = Color(0xFF00FFFF); // سماوي نيون
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFFB3B3B3);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      // استخدام خط Cairo
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),

      // لون الأزرار الأساسي
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),

      // تخصيص البطاقات (تم إصلاح الخطوط الحمراء هنا)
      cardTheme: CardThemeData(
        // 👈 تغيرت إلى CardThemeData
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primary
                .withValues(alpha: 0.3), // 👈 تغيرت to withValues
            width: 1,
          ),
        ),
      ),

      // تخصيص شريط التطبيق العلوي
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
    );
  }
}
