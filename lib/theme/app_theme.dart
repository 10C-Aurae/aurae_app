import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,

      colorScheme: const ColorScheme.dark(
        surface:         AppColors.bg,
        primary:         AppColors.primary,
        secondary:       AppColors.secondary,
        tertiary:        AppColors.accent,
        onPrimary:       Colors.white,
        onSurface:       AppColors.ink,
        surfaceContainer: AppColors.card,
        outline:         AppColors.border,
        error:           Color(0xFFFF5C5C),
      ),

      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.ink,
        displayColor: AppColors.ink,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:    AppColors.nav,
        surfaceTintColor:   Colors.transparent,
        elevation:          0,
        scrolledUnderElevation: 0,
        centerTitle:        true,
        titleTextStyle: GoogleFonts.inter(
          color:      AppColors.ink,
          fontSize:   17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:        AppColors.nav,
        surfaceTintColor:       Colors.transparent,
        indicatorColor:         AppColors.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize:   11,
            fontWeight: FontWeight.w500,
            color:      isSelected ? AppColors.primary : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.primary : AppColors.muted,
            size:  22,
          );
        }),
      ),

      cardTheme: CardThemeData(
        color:        AppColors.card,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   AppColors.surface,
        hintStyle:   const TextStyle(color: AppColors.faint),
        labelStyle:  const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5C5C)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:   AppColors.primary,
          foregroundColor:   Colors.white,
          disabledBackgroundColor: AppColors.faint,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 1,
        space:     1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.surface,
        selectedColor:      AppColors.primary.withOpacity(0.18),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.ink, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      iconTheme: const IconThemeData(color: AppColors.muted),
    );
  }
}