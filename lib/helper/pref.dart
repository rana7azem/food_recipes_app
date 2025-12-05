import 'package:shared_preferences/shared_preferences.dart';

class Pref {

  static const String _keyShowOnboarding = 'show_onboarding';
  static const String _keyDarkMode = 'dark_mode';

  
  static SharedPreferences? _prefs;

  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  
  static bool get showOnboarding =>
      _prefs?.getBool(_keyShowOnboarding) ?? true;

  static Future<bool> setShowOnboarding(bool value) async {
    return await _prefs?.setBool(_keyShowOnboarding, value) ?? false;
  }


  static bool get isDarkMode =>
      _prefs?.getBool(_keyDarkMode) ?? false;

  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_keyDarkMode, value);
  }
}
