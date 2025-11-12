
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
  static bool get showOnboarding => _prefs?.getBool(_keyShowOnboarding) ?? true;

  // Setter for showOnboarding
  static Future<bool> setShowOnboarding(bool value) async {
    return await _prefs?.setBool(_keyShowOnboarding, value) ?? false;
  }
}
