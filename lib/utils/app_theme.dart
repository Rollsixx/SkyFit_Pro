import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static TextTheme _textTheme(Color base) =>
      GoogleFonts.spaceGroteskTextTheme(
        TextTheme(
          displayLarge:   TextStyle(color: base, fontWeight: FontWeight.w800),
          displayMedium:  TextStyle(color: base, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: base, fontWeight: FontWeight.w700, fontSize: 22),
          titleLarge:     TextStyle(color: base, fontWeight: FontWeight.w700),
          titleMedium:    TextStyle(color: base, fontWeight: FontWeight.w600),
          bodyLarge:      TextStyle(color: base),
          bodyMedium:     TextStyle(color: base.withOpacity(0.8)),
          labelLarge:     TextStyle(color: base, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      );

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.dark,
        scaffoldBackgroundColor: Constants.dsBlack,
        colorScheme: const ColorScheme.dark(
          surface:   Constants.dsSurface,
          primary:   Constants.dsCrimson,
          secondary: Constants.dsTeal,
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        textTheme: _textTheme(Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Constants.dsBlack,
          foregroundColor: Colors.white,
          centerTitle:     true,
          elevation:       0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:     true,
          fillColor:  Colors.white.withOpacity(0.07),
          labelStyle: const TextStyle(color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Constants.dsTeal, width: 2),
          ),
          prefixIconColor: Colors.white54,
          suffixIconColor: Colors.white54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.dsCrimson,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.dsTeal,
            side:    const BorderSide(color: Constants.dsTeal),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          color:     Constants.dsSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Constants.dsCrimson,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor:  Constants.dsSurface,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(color: Colors.white12),
        iconTheme:    const IconThemeData(color: Colors.white70),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Constants.dsTeal : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.dsTeal.withOpacity(0.4)
                : null,
          ),
        ),
      );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness:   Brightness.light,
        scaffoldBackgroundColor: Constants.lsBackground,
        colorScheme: const ColorScheme.light(
          surface:   Constants.lsSurface,
          primary:   Constants.lsPrimary,
          secondary: Constants.lsAccent,
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A2E),
        ),
        textTheme: _textTheme(const Color(0xFF1A1A2E)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Constants.lsSurface,
          foregroundColor: Color(0xFF1A1A2E),
          centerTitle:     true,
          elevation:       0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:     true,
          fillColor:  const Color(0xFFF1F1F1),
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:   const BorderSide(color: Constants.lsAccent, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.lsPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.lsAccent,
            side:    const BorderSide(color: Constants.lsAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        cardTheme: CardThemeData(
          color:       Constants.lsSurface,
          elevation:   1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Constants.lsPrimary,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor:  const Color(0xFF1A1A2E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        iconTheme:    const IconThemeData(color: Color(0xFF444466)),
        dividerTheme: const DividerThemeData(color: Color(0x1A000000)),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Constants.lsAccent : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Constants.lsAccent.withOpacity(0.4)
                : null,
          ),
        ),
      );
}
