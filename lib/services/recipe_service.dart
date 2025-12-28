import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class RecipeService {
  // Use lazy initialization to avoid "no instance" error
  FirebaseDatabase get _database => FirebaseDatabase.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Check if Firebase is initialized
  bool get _isFirebaseInitialized => Firebase.apps.isNotEmpty;

  // Reference to recipes in Realtime Database
  DatabaseReference get _recipesRef => _database.ref().child('recipes');

  // Reference to user recipes
  DatabaseReference _userRecipesRef(String userId) =>
      _database.ref().child('users/$userId/recipes');

  // Add a new recipe to Firebase Realtime Database
  Future<String> addRecipe({
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
      print('=== RECIPE SERVICE: Starting addRecipe ===');
      
      // Check if Firebase is initialized
      if (!_isFirebaseInitialized) {
        print('RECIPE SERVICE ERROR: Firebase not initialized');
        throw Exception('Firebase not initialized. Please restart the app.');
      }
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('RECIPE SERVICE ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }
      print('RECIPE SERVICE: User authenticated: $userId');

      final recipeRef = _recipesRef.push();
      final recipeId = recipeRef.key!;
      print('RECIPE SERVICE: Generated recipe ID: $recipeId');

      final recipeData = {
        'id': recipeId,
        'userId': userId,
        'name': name,
        'category': category,
        'difficulty': difficulty,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'rating': 0.0,
      };
      print('RECIPE SERVICE: Recipe data prepared: $recipeData');

      // Save to general recipes collection
      print('RECIPE SERVICE: Saving to /recipes/$recipeId');
      await recipeRef.set(recipeData);
      print('RECIPE SERVICE: Successfully saved to general recipes collection');

      // Also save to user's recipes for quick access
      print('RECIPE SERVICE: Saving to /users/$userId/recipes/$recipeId');
      await _userRecipesRef(userId).child(recipeId).set(recipeData);
      print('RECIPE SERVICE: Successfully saved to user recipes collection');

      print('RECIPE SERVICE: Recipe saved successfully with ID: $recipeId');
      return recipeId;
    } catch (e) {
      print('RECIPE SERVICE ERROR: Failed to add recipe - $e');
      throw Exception('Failed to add recipe: $e');
    }
  }

  // Get all recipes
  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    try {
      final snapshot = await _recipesRef.get();
      if (!snapshot.exists) {
        return [];
      }

      final recipes = <Map<String, dynamic>>[];
      for (var child in snapshot.children) {
        recipes.add(Map<String, dynamic>.from(child.value as Map));
      }
      return recipes;
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  // Get recipes by category
  Future<List<Map<String, dynamic>>> getRecipesByCategory(
      String category) async {
    try {
      final snapshot = await _recipesRef
          .orderByChild('category')
          .equalTo(category)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final recipes = <Map<String, dynamic>>[];
      for (var child in snapshot.children) {
        recipes.add(Map<String, dynamic>.from(child.value as Map));
      }
      return recipes;
    } catch (e) {
      throw Exception('Failed to fetch recipes by category: $e');
    }
  }

  // Get user's recipes
  Future<List<Map<String, dynamic>>> getUserRecipes(String userId) async {
    try {
      final snapshot = await _userRecipesRef(userId).get();
      if (!snapshot.exists) {
        return [];
      }

      final recipes = <Map<String, dynamic>>[];
      for (var child in snapshot.children) {
        recipes.add(Map<String, dynamic>.from(child.value as Map));
      }
      return recipes;
    } catch (e) {
      throw Exception('Failed to fetch user recipes: $e');
    }
  }

  // Stream of all recipes (real-time updates)
  Stream<List<Map<String, dynamic>>> getAllRecipesStream() {
    // Return empty stream if Firebase is not initialized
    if (!_isFirebaseInitialized) {
      print('RECIPE SERVICE: Firebase not initialized, returning empty stream');
      return Stream.value([]);
    }
    
    return _recipesRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final recipes = <Map<String, dynamic>>[];
      for (var child in event.snapshot.children) {
        recipes.add(Map<String, dynamic>.from(child.value as Map));
      }
      return recipes;
    });
  }

  // Stream of user's recipes (real-time updates)
  Stream<List<Map<String, dynamic>>> getUserRecipesStream(String userId) {
    return _userRecipesRef(userId).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      final recipes = <Map<String, dynamic>>[];
      for (var child in event.snapshot.children) {
        recipes.add(Map<String, dynamic>.from(child.value as Map));
      }
      return recipes;
    });
  }

  // Update recipe
  Future<void> updateRecipe({
    required String recipeId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      updates['updatedAt'] = DateTime.now().toIso8601String();

      // Update in general recipes collection
      await _recipesRef.child(recipeId).update(updates);

      // Update in user's recipes
      await _userRecipesRef(userId).child(recipeId).update(updates);
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete from general recipes collection
      await _recipesRef.child(recipeId).remove();

      // Delete from user's recipes
      await _userRecipesRef(userId).child(recipeId).remove();
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  // Rate a recipe
  Future<void> rateRecipe({
    required String recipeId,
    required double rating,
  }) async {
    try {
      await _recipesRef.child(recipeId).update({
        'rating': rating,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to rate recipe: $e');
    }
  }

  // Debug method to check database contents
  Future<void> debugPrintDatabaseContents() async {
    try {
      final snapshot = await _recipesRef.get();
      if (snapshot.exists) {
        print('=== DATABASE CONTENTS ===');
        print('Total recipes: ${snapshot.children.length}');
        for (var child in snapshot.children) {
          final recipe = Map<String, dynamic>.from(child.value as Map);
          print('Recipe ID: ${child.key}');
          print('Name: ${recipe['name']}');
          print('Category: ${recipe['category']}');
          print('------------------------');
        }
      } else {
        print('No recipes found in database');
      }
    } catch (e) {
      print('Error checking database: $e');
    }
  }
}
