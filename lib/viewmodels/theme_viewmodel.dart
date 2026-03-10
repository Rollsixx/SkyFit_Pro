import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Available font options ─────────────────────────────────────────────────────

enum AppFont {
  spaceGrotesk,
  poppins,
  roboto,
  nunito,
  lato,
  merriweather,
}

extension AppFontExt on AppFont {
  String get label => switch (this) {
        AppFont.spaceGrotesk  => 'Space Grotesk',
        AppFont.poppins       => 'Poppins',
        AppFont.roboto        => 'Roboto',
        AppFont.nunito        => 'Nunito',
        AppFont.lato          => 'Lato',
        AppFont.merriweather  => 'Merriweather',
      };

  String get googleFontsKey => switch (this) {
        AppFont.spaceGrotesk  => 'Space Grotesk',
        AppFont.poppins       => 'Poppins',
        AppFont.roboto        => 'Roboto',
        AppFont.nunito        => 'Nunito',
        AppFont.lato          => 'Lato',
        AppFont.merriweather  => 'Merriweather',
      };

  String get description => switch (this) {
        AppFont.spaceGrotesk  => 'Modern & geometric',
        AppFont.poppins       => 'Rounded & friendly',
        AppFont.roboto        => 'Clean & familiar',
        AppFont.nunito        => 'Soft & legible',
        AppFont.lato          => 'Elegant & clear',
        AppFont.merriweather  => 'Classic serif',
      };

  IconData get icon => switch (this) {
        AppFont.merriweather  => Icons.menu_book_rounded,
        _                     => Icons.text_fields_rounded,
      };
}

// ── ViewModel ──────────────────────────────────────────────────────────────────

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  AppFont   _font = AppFont.spaceGrotesk;

  static const _modeKey = 'theme_mode';
  static const _fontKey = 'app_font';

  ThemeMode get mode   => _mode;
  AppFont   get font   => _font;
  bool      get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs   = await SharedPreferences.getInstance();
    final isDark  = prefs.getBool(_modeKey) ?? true;
    final fontIdx = prefs.getInt(_fontKey)  ?? 0;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    _font = AppFont.values[fontIdx.clamp(0, AppFont.values.length - 1)];
    notifyListeners();
  }

  void toggle() => setDark(!isDark);

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modeKey, dark);
  }

  Future<void> setFont(AppFont font) async {
    _font = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontKey, font.index);
    // ignore: avoid_print
    print('[ThemeViewModel] Font changed to: ${font.label}');
  }
}