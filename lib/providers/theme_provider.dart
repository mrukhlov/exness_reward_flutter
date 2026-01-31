import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDark = false;
  bool _useCustomMapStyle = true; // Default to custom style
  bool _useAppleMaps = false; // Default to Google Maps on iOS

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _isDark;
  bool get useCustomMapStyle => _useCustomMapStyle;
  bool get useAppleMaps => _useAppleMaps;

  ThemeProvider() {
    _loadTheme();
    _loadMapStyle();
    _loadMapProvider();
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

  Future<void> _loadMapStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useCustomMapStyle = prefs.getBool('exness_map_style_custom') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading map style: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    _themeMode = _isDark ? ThemeMode.dark : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exness_theme', _isDark ? 'dark' : 'light');
    
    notifyListeners();
  }

  Future<void> _loadMapProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useAppleMaps = prefs.getBool('exness_map_provider_apple') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading map provider: $e');
    }
  }

  Future<void> toggleMapStyle() async {
    _useCustomMapStyle = !_useCustomMapStyle;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exness_map_style_custom', _useCustomMapStyle);
    
    notifyListeners();
  }

  Future<void> toggleMapProvider() async {
    _useAppleMaps = !_useAppleMaps;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exness_map_provider_apple', _useAppleMaps);
    
    notifyListeners();
  }
}

