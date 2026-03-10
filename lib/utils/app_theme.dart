import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import '../viewmodels/theme_viewmodel.dart';

class AppTheme {
  // ── Font loader ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(AppFont font, Color base) {
    // Larger sizes + bolder weights across the board
    final base1 = TextStyle(color: base, fontWeight: FontWeight.w500);

    final raw = TextTheme(
      displayLarge:   TextStyle(color: base, fontWeight: FontWeight.w800, fontSize: 34),
      displayMedium:  TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 28),
      headlineLarge:  TextStyle(color: base, fontWeight: FontWeight.w800, fontSize: 26),
      headlineMedium: TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 22),
      headlineSmall:  TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 20),
      titleLarge:     TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium:    TextStyle(color: base, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall:     TextStyle(color: base, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge:      TextStyle(color: base, fontWeight: FontWeight.w500, fontSize: 16),
      bodyMedium:     TextStyle(color: base, fontWeight: FontWeight.w400, fontSize: 15),
      bodySmall:      TextStyle(color: base.withOpacity(0.80), fontWeight: FontWeight.w400, fontSize: 13),
      labelLarge:     TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
      labelMedium:    TextStyle(color: base, fontWeight: FontWeight.w600, fontSize: 13),
      labelSmall:     TextStyle(color: base.withOpacity(0.80), fontWeight: FontWeight.w500, fontSize: 12),
    );

    // Apply chosen Google Font
    return switch (font) {
      AppFont.spaceGrotesk  => GoogleFonts.spaceGroteskTextTheme(raw),
      AppFont.poppins       => GoogleFonts.poppinsTextTheme(raw),
      AppFont.roboto        => GoogleFonts.robotoTextTheme(raw),
      AppFont.nunito        => GoogleFonts.nunitoTextTheme(raw),
      AppFont.lato          => GoogleFonts.latoTextTheme(raw),
      AppFont.merriweather  => GoogleFonts.merriweatherTextTheme(raw),
    };
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData dark(AppFont font) => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.dark,
        scaffoldBackgroundColor: Constants.dsBlack,
        colorScheme: const ColorScheme.dark(
          surface:          Constants.dsSurface,
          primary:          Constants.dsCrimson,
          secondary:        Constants.dsTeal,
          onPrimary:        Colors.white,
          onSurface:        Colors.white,
          onSurfaceVariant: Color(0xFFDDDDDD), // ← darker variant text
        ),
        textTheme: _buildTextTheme(font, Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: Constants.dsBlack,
          foregroundColor: Colors.white,
          centerTitle:     true,
          elevation:       0,
          titleTextStyle: GoogleFonts.getFont(
            font.googleFontsKey,
            textStyle: const TextStyle(
              color:      Colors.white,
              fontSize:   18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:      true,
          fillColor:   Colors.white.withOpacity(0.08),
          // Darker hint/label text for readability
          labelStyle:  const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
          hintStyle:   const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Colors.white30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Constants.dsTeal, width: 2),
          ),
          prefixIconColor: const Color(0xFFCCCCCC),
          suffixIconColor: const Color(0xFFCCCCCC),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.dsCrimson,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.dsTeal,
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
            side:    const BorderSide(color: Constants.dsTeal, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          color:     Constants.dsSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Constants.dsCrimson,
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor:  Constants.dsSurface,
          contentTextStyle: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme:  const DividerThemeData(color: Colors.white12),
        iconTheme:     const IconThemeData(color: Color(0xFFDDDDDD), size: 24),
        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          subtitleTextStyle: TextStyle(
              color: Color(0xFFBBBBBB), fontSize: 13),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.dsTeal : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.dsTeal.withOpacity(0.4) : null,
          ),
        ),
        chipTheme: ChipThemeData(
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      );

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData light(AppFont font) => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.light,
        scaffoldBackgroundColor: Constants.lsBackground,
        colorScheme: const ColorScheme.light(
          surface:          Constants.lsSurface,
          primary:          Constants.lsPrimary,
          secondary:        Constants.lsAccent,
          onPrimary:        Colors.white,
          onSurface:        Color(0xFF0D0D0D), // near-black for max readability
          onSurfaceVariant: Color(0xFF2A2A2A), // dark grey, not washed out
        ),
        textTheme: _buildTextTheme(font, const Color(0xFF0D0D0D)),
        appBarTheme: AppBarTheme(
          backgroundColor: Constants.lsSurface,
          foregroundColor: const Color(0xFF0D0D0D),
          centerTitle:     true,
          elevation:       0,
          titleTextStyle: GoogleFonts.getFont(
            font.googleFontsKey,
            textStyle: const TextStyle(
              color:      Color(0xFF0D0D0D),
              fontSize:   18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:      true,
          fillColor:   const Color(0xFFF0F0F0),
          // Darker labels for light mode
          labelStyle:  const TextStyle(
              color: Color(0xFF333333), fontSize: 15),
          hintStyle:   const TextStyle(
              color: Color(0xFF777777), fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
                color: Constants.lsAccent, width: 2),
          ),
          prefixIconColor: const Color(0xFF444444),
          suffixIconColor: const Color(0xFF444444),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.lsPrimary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.lsAccent,
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
            side: const BorderSide(
                color: Constants.lsAccent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          color:       Constants.lsSurface,
          elevation:   1,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Constants.lsPrimary,
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor:  const Color(0xFF1A1A2E),
          contentTextStyle: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        iconTheme:     const IconThemeData(
            color: Color(0xFF222222), size: 24),
        dividerTheme:  const DividerThemeData(
            color: Color(0x1A000000)),
        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(
              color: Color(0xFF0D0D0D),
              fontSize: 15, fontWeight: FontWeight.w600),
          subtitleTextStyle: TextStyle(
              color: Color(0xFF444444), fontSize: 13),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.lsAccent : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.lsAccent.withOpacity(0.4) : null,
          ),
        ),
        chipTheme: ChipThemeData(
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      );
}