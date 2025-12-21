import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDark = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('exness_theme');
      
      if (stored == 'dark') {
        _themeMode = ThemeMode.dark;
        _isDark = true;
      } else if (stored == 'light') {
        _themeMode = ThemeMode.light;
        _isDark = false;
      } else {
        // Default to light theme
        _themeMode = ThemeMode.light;
        _isDark = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    _themeMode = _isDark ? ThemeMode.dark : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exness_theme', _isDark ? 'dark' : 'light');
    
    notifyListeners();
  }
}

