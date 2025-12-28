import '/models/recipe.dart';
import '/helper/pref.dart';

class RecipeLoader {
  /// Load all user recipes from SharedPreferences and populate Recipe model
  static Future<void> loadUserRecipes() async {
    try {
      print('=== RECIPE LOADER: Loading user recipes from SharedPreferences ===');
      
      final userRecipesData = Pref.getUserRecipes();
      print('RECIPE LOADER: Found ${userRecipesData.length} recipes in SharedPreferences');
      
      // Clear existing user recipes
      Recipe.userRecipes.clear();
      
      // Load each recipe from SharedPreferences
      for (final recipeData in userRecipesData) {
        try {
          final recipe = Recipe.fromJson(recipeData);
          Recipe.userRecipes.add(recipe);
          print('RECIPE LOADER: Loaded recipe - ${recipe.title}');
        } catch (e) {
          print('RECIPE LOADER ERROR: Failed to parse recipe data: $e');
        }
      }
      
      print('RECIPE LOADER: Successfully loaded ${Recipe.userRecipes.length} user recipes');
    } catch (e) {
      print('RECIPE LOADER ERROR: Failed to load user recipes - $e');
    }
  }

  /// Sync recipes - ensure Recipe model matches SharedPreferences
  static Future<void> syncRecipes() async {
    try {
      print('=== RECIPE LOADER: Syncing recipes ===');
      
      // First load from shared preferences
      await loadUserRecipes();
      
      print('RECIPE LOADER: Recipes synced successfully');
    } catch (e) {
      print('RECIPE LOADER ERROR: Failed to sync recipes - $e');
    }
  }
}
