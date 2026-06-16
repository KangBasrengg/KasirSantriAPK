import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF2563EB),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      primary: const Color(0xFF2563EB),
      background: const Color(0xFFF1F5F9),
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFF475569)),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF2563EB),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF020617),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF2563EB),
      primary: const Color(0xFF2563EB),
      background: const Color(0xFF0F172A),
      surface: const Color(0xFF1E293B),
      onSurface: const Color(0xFFF8FAFC),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
    ),
  );
}
