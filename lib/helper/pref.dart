import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Pref {

  static const String _keyShowOnboarding = 'show_onboarding';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyUserRecipes = 'user_recipes';

  
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

  // ==================== Recipe Management ====================

  /// Get all user recipes from shared preferences
  static List<Map<String, dynamic>> getUserRecipes() {
    try {
      final recipesJson = _prefs?.getString(_keyUserRecipes);
      if (recipesJson == null || recipesJson.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(recipesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('ERROR: Failed to get user recipes from prefs: $e');
      return [];
    }
  }

  /// Add a single recipe to shared preferences
  static Future<bool> addUserRecipe({
    required String id,
    required String name,
    required String category,
    required String difficulty,
    required String prepTime,
    required String cookTime,
    required String servings,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final recipes = getUserRecipes();
      
      // Create new recipe object
      final newRecipe = {
        'id': id,
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Add to list
      recipes.add(newRecipe);
      
      // Save back to preferences
      final result = await _prefs?.setString(_keyUserRecipes, jsonEncode(recipes));
      print('✅ Recipe saved to shared preferences: $id');
      return result ?? false;
    } catch (e) {
      print('❌ ERROR: Failed to add recipe to shared preferences: $e');
      return false;
    }
  }

  /// Remove a recipe from shared preferences
  static Future<bool> removeUserRecipe(String recipeId) async {
    try {
      final recipes = getUserRecipes();
      recipes.removeWhere((recipe) => recipe['id'] == recipeId);
      final result = await _prefs?.setString(_keyUserRecipes, jsonEncode(recipes));
      print('✅ Recipe removed from shared preferences: $recipeId');
      return result ?? false;
    } catch (e) {
      print('❌ ERROR: Failed to remove recipe from shared preferences: $e');
      return false;
    }
  }

  /// Update a recipe in shared preferences
  static Future<bool> updateUserRecipe({
    required String id,
    required String name,
    required String category,
    required String difficulty,
    required String prepTime,
    required String cookTime,
    required String servings,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final recipes = getUserRecipes();
      final index = recipes.indexWhere((recipe) => recipe['id'] == id);
      
      if (index == -1) {
        print('❌ ERROR: Recipe not found: $id');
        return false;
      }
      
      // Update recipe
      recipes[index] = {
        'id': id,
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': recipes[index]['createdAt'],
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final result = await _prefs?.setString(_keyUserRecipes, jsonEncode(recipes));
      print('✅ Recipe updated in shared preferences: $id');
      return result ?? false;
    } catch (e) {
      print('❌ ERROR: Failed to update recipe in shared preferences: $e');
      return false;
    }
  }

  /// Get a specific recipe by ID
  static Map<String, dynamic>? getUserRecipeById(String recipeId) {
    try {
      final recipes = getUserRecipes();
      return recipes.firstWhere(
        (recipe) => recipe['id'] == recipeId,
        orElse: () => {},
      );
    } catch (e) {
      print('ERROR: Failed to get recipe by ID: $e');
      return null;
    }
  }

  /// Clear all user recipes from shared preferences
  static Future<bool> clearUserRecipes() async {
    try {
      final result = await _prefs?.remove(_keyUserRecipes);
      print('✅ All user recipes cleared from shared preferences');
      return result ?? false;
    } catch (e) {
      print('❌ ERROR: Failed to clear user recipes: $e');
      return false;
    }
  }
}
