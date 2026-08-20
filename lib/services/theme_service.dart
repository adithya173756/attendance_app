import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _darkModeKey = 'dark_mode';

  static final ValueNotifier<bool> modeNotifier = ValueNotifier<bool>(false);

  static bool get isDarkMode => modeNotifier.value;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getBool(_darkModeKey) ?? false;

    modeNotifier.value = savedMode;
  }

  // ============================================================
  // SET DARK MODE
  // ============================================================

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_darkModeKey, value);

    modeNotifier.value = value;
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  static Future<void> toggle() async {
    await setDarkMode(!isDarkMode);
  }
}
