import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF101820);
  static const Color surfaceRaised = Color(0xFF151F29);
  static const Color primary = Color(0xFF00F0FF);
  static const Color accent = Color(0xFF00F0FF);
  static const Color inactive = Color(0xFF66717C);
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFFA8B5C0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: _SystemCardBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: AppColors.textSub),
        hintStyle: const TextStyle(color: AppColors.inactive),
        prefixIconColor: AppColors.primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AppColors.textMain),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFF27313A),
      ),
    );
  }
}

class _SystemCardBorder extends ShapeBorder {
  const _SystemCardBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _systemCardPath(rect.deflate(1));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _systemCardPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _systemCardPath(rect.deflate(0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primary.withValues(alpha: 0.22),
    );
  }

  @override
  ShapeBorder scale(double t) => this;

  Path _systemCardPath(Rect rect) => Path()
    ..moveTo(rect.left + 12, rect.top)
    ..lineTo(rect.right - 12, rect.top)
    ..lineTo(rect.right, rect.top + 12)
    ..lineTo(rect.right, rect.bottom - 12)
    ..lineTo(rect.right - 12, rect.bottom)
    ..lineTo(rect.left + 12, rect.bottom)
    ..lineTo(rect.left, rect.bottom - 12)
    ..lineTo(rect.left, rect.top + 12)
    ..close();
}
