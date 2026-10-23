import 'package:flutter/material.dart';

const kFont = 'PlusJakartaSans';

class AppColors {
  static const bg = Color(0xFFF6F7FB);
  static const card = Colors.white;
  static const ink = Color(0xFF14141C);
  static const border = Color(0xFFE8EAF1);
  static const muted = Color(0xFF8B90A3);
  static const subtle = Color(0xFFF0F1F6);
  static const purple = Color(0xFF7B5CE6);
  static const purpleBg = Color(0xFFEFEAFD);
  static const green = Color(0xFF16A34A);
  static const greenBg = Color(0xFFE6F6EC);
  static const orange = Color(0xFFF97316);
  static const orangeBg = Color(0xFFFFF1E6);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFDECEC);
  static const teal = Color(0xFF0F9F8F);
  static const tealBg = Color(0xFFE3F5F2);
  static const amberBg = Color(0xFFFFF3D6);
  static const amberText = Color(0xFFB45309);

  // alias nama lama (supaya file lama tidak error)
  static const surface = card;
  static const surfaceLight = subtle;
  static const pink = red;
  static const violet = purple;
  static const cyan = teal;
  static const gradient = LinearGradient(colors: [purple, teal]);
}

class AppTheme {
  static OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light {
    final base = ThemeData(
        useMaterial3: true, brightness: Brightness.light, fontFamily: kFont);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ink,
        onPrimary: Colors.white,
        secondary: AppColors.purple,
        surface: Colors.white,
        onSurface: AppColors.ink,
      ),
      textTheme: base.textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          fontFamily: kFont),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
            fontFamily: kFont,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        border: _b(AppColors.border),
        enabledBorder: _b(AppColors.border),
        focusedBorder: _b(AppColors.ink, 1.5),
        errorBorder: _b(AppColors.red),
        focusedErrorBorder: _b(AppColors.red, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(
              fontFamily: kFont, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(
              fontFamily: kFont, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(fontFamily: kFont, color: Colors.white),
      ),
    );
  }

  // nama lama, tetap tersedia
  static ThemeData get dark => light;
}
