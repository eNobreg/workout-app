import 'package:flutter/material.dart';

/// Provider for managing app theme mode (light/dark/system).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Default to light if system preference can't be determined
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Set the theme mode and notify listeners.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggle between light and dark mode.
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
