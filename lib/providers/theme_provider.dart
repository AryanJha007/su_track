import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  final String key = "theme";

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Base Colors
  Color get backgroundColor => _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F3EE);
  Color get cardColor => _isDarkMode ? Color(0xFF2C2C2E) : Color(0xFFE6DFD7);
  Color get primaryColor => _isDarkMode ? Colors.blue : Color(0xFFB85C38);
  Color get textColor => _isDarkMode ? Colors.white : Color(0xFF2C2C2E);
  Color get secondaryTextColor => _isDarkMode ? Colors.grey[400]! : Color(0xFF666666);
  Color get cursorColor => isDarkMode ? Colors.blue : Color(0xFF2C2C2E);
  // Additional Theme Colors
  Color get appBarColor => _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F3EE);
  Color get bottomNavBarColor => _isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF5F3EE);
  Color get dividerColor => _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  Color get inputFillColor => _isDarkMode ? Color(0xFF2C2C2E) : Colors.white;
  Color get inputBorderColor => _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  Color get buttonColor => primaryColor;
  Color get buttonColor2 =>  Colors.white ;
  Color get iconColor => _isDarkMode ? Colors.white : Color(0xFF2C2C2E);
  Color get switchActiveColor => primaryColor;
  Color get switchInactiveColor => _isDarkMode ? Colors.grey : Colors.grey[400]!;
  Color get errorColor => Colors.red;
  Color get successColor => Colors.green;
  Color get warningColor => Colors.orange;
  Color get bottomBarSelectedColor => isDarkMode ? Colors.blue : Colors.black;
  Color get bottomBarUnselectedColor => isDarkMode ? Colors.white : Colors.grey[400]!;
  Color get lionColor =>isDarkMode ? Colors.white : Color(0xFFB85C38);
  // Status Colors (Consistent in both themes)
  Color get approvedColor => Colors.green;
  Color get pendingColor => Colors.orange;
  Color get rejectedColor => Colors.red;

  // Input Decoration Theme
  InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: inputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: inputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor),
    ),
    labelStyle: TextStyle(color: secondaryTextColor),
    hintStyle: TextStyle(color: secondaryTextColor),
  );

  // Button Theme
  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: buttonColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(key) ?? true;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, _isDarkMode);
  }
} 