import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Persists and exposes the app-wide theme mode.
class ThemeViewModel extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool      get isDark => _mode == ThemeMode.dark;

  // ── Initialise from storage ───────────────────────────────────────────────

  Future<void> load() async {
    final prefs  = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(Constants.prefThemeKey) ?? true;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ── Toggle ────────────────────────────────────────────────────────────────

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefThemeKey, isDark);
  }

  Future<void> setDark(bool value) async {
    _mode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.prefThemeKey, value);
  }
}
