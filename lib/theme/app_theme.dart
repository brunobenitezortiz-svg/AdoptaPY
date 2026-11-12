import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// IDENTIDAD VISUAL DE ADOPTAPY
// ==========================================

abstract final class AppColors {
  // Colores principales
  static const primary = Color(0xFF1D6FB8);
  static const primaryDark = Color(0xFF164E86);
  static const celeste = Color(0xFF56B8F2);
  static const azulPastel = Color(0xFFD9EDFF);

  // Colores secundarios
  static const azulClaro = Color(0xFFE5F7FF);
  static const azulSuave = Color(0xFFEEF7FF);

  // Superficies y fondos
  static const background = Color(0xFFF5FAFF);
  static const surface = Colors.white;

  // Textos
  static const ink = Color(0xFF193A59);
  static const muted = Color(0xFF667F96);

  // Bordes
  static const border = Color(0xFFE1EDF7);

  // Estados
  static const success = Color(0xFF27856A);
  static const warning = Color(0xFFE9A34B);
  static const error = Color(0xFFCF5366);

  // Compatibilidad con las pantallas existentes.
  // Conservamos estos nombres para no romper
  // las referencias actuales del proyecto.
  static const mint = azulPastel;
  static const coral = celeste;
  static const coralLight = azulClaro;
}

// ==========================================
// TEMA GLOBAL DE LA APLICACION
// ==========================================

abstract final class AppTheme {
  static ThemeData get light {
    final temaBase = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.azulPastel,
        secondary: AppColors.celeste,
        secondaryContainer: AppColors.azulClaro,
        tertiary: Color(0xFF5E92CE),
        tertiaryContainer: Color(0xFFE0ECFF),
      ),
      scaffoldBackground: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      subThemesData: const FlexSubThemesData(defaultRadius: 20),
      useMaterial3: true,
    );

    // Tipografia Quicksand para toda la app
    final textos = GoogleFonts.quicksandTextTheme(temaBase.textTheme);

    final bordesRedondeados = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return temaBase.copyWith(
      scaffoldBackgroundColor: AppColors.background,

      // ====================================
      // TIPOGRAFIA
      // ====================================
      textTheme: textos.copyWith(
        headlineLarge: textos.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: AppColors.ink,
        ),
        headlineMedium: textos.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: AppColors.ink,
        ),
        titleLarge: textos.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleMedium: textos.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: textos.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.45,
          color: AppColors.ink,
        ),
        bodyMedium: textos.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
          color: AppColors.ink,
        ),
      ),

      // ====================================
      // BARRA SUPERIOR
      // ====================================
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
      ),

      // ====================================
      // TARJETAS
      // ====================================
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ====================================
      // BOTONES PRINCIPALES
      // ====================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.azulPastel,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: bordesRedondeados,
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: bordesRedondeados,
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ====================================
      // BOTONES CON BORDE
      // ====================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: bordesRedondeados,
          textStyle: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ====================================
      // BOTONES DE TEXTO
      // ====================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w800),
        ),
      ),

      // ====================================
      // CAMPOS DE TEXTO
      // ====================================
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 19,
          vertical: 18,
        ),

        hintStyle: GoogleFonts.quicksand(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
        ),

        labelStyle: GoogleFonts.quicksand(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),

        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.muted,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),

      // ====================================
      // FILTROS Y CHIPS
      // ====================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.azulClaro,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.quicksand(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      ),

      // ====================================
      // DIVISORES
      // ====================================
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      // ====================================
      // MENSAJES INFORMATIVOS
      // ====================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: GoogleFonts.quicksand(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ====================================
      // VENTANAS EMERGENTES
      // ====================================
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),

      // ====================================
      // BARRA DE NAVEGACION
      // ====================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.azulPastel,
        elevation: 0,
        height: 72,
      ),

      // ====================================
      // INDICADORES DE CARGA
      // ====================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.azulPastel,
      ),
    );
  }
}
