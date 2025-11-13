
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  // Key for onboarding status
  static const String _keyShowOnboarding = 'show_onboarding';
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getter for showOnboarding
  static bool get showOnboarding {
    try {
      return _prefs?.getBool(_keyShowOnboarding) ?? true;
    } catch (e) {
      return true;
    }
  }

  // Setter for showOnboarding
  static Future<bool> setShowOnboarding(bool value) async {
    try {
      return await _prefs?.setBool(_keyShowOnboarding, value) ?? false;
    } catch (e) {
      return false;
    }
  }
}
