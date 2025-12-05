import 'package:flutter/material.dart';
import 'pref.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = Pref.isDarkMode;

  bool get isDark => _isDark;

  void toggleTheme(bool value) {
    _isDark = value;
    Pref.setDarkMode(value); 
    notifyListeners();
  }
}
