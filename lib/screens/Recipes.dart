import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_recipes_app/helper/api_service.dart';
import 'package:food_recipes_app/screens/Add.dart';
import '/services/recipe_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allRecipes = [];
  List<dynamic> _filteredRecipes = [];
  String selectedCategory = 'All';
  List<String> categories = ['All'];
  bool _isLoading = true;
  late Stream<List<Map<String, dynamic>>> _recipesStream;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _searchController.addListener(() => setState(() {}));
    _recipesStream = RecipeService().getAllRecipesStream();
  }

  Future<void> _fetchRecipes() async {
    try {
      final data = await ApiService.fetchRecipes();
      final categoryList = <String>{'All'};

      for (var recipe in data) {
        if (recipe['mealType'] != null) {
          for (var type in recipe['mealType']) {
            categoryList.add(type.toString());
          }
        }
      }

      setState(() {
        _allRecipes = data;
        _filteredRecipes = data;
        categories = categoryList.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching API recipes: $e");
    }
  }

  void _filterRecipes() {
    final query = _searchController.text.toLowerCase();
    List<dynamic> filtered = _allRecipes;

    if (selectedCategory != 'All') {
      filtered = filtered
          .where((r) => (r['mealType'] as List).contains(selectedCategory))
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where((r) => r['name'].toString().toLowerCase().contains(query))
          .toList();
    }

    setState(() => _filteredRecipes = filtered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "debug",
            backgroundColor: Colors.blue,
            mini: true,
            onPressed: () async {
              await RecipeService().debugPrintDatabaseContents();
            },
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "add",
            backgroundColor: Colors.orangeAccent,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.secondary,
              ),
            )
          : Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _filterRecipes(),
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterRecipes();
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                  ),
                ),

                // 🍽️ Category Filter
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                            _filterRecipes();
                          },
                          selectedColor: Colors.orangeAccent,
                          backgroundColor: theme.cardColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // 🧾 Recipes Grid (Firebase + API)
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _recipesStream,
                    builder: (context, snapshot) {
                      final userRecipes = snapshot.data ?? [];
                      if (_filteredRecipes.isEmpty && userRecipes.isEmpty) {
                        return Center(
                          child: Text(
                            'No recipes found 😔',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        );
                      }

                      final totalRecipes =
                          _filteredRecipes.length + userRecipes.length;

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: totalRecipes,
                        itemBuilder: (context, index) {
                          if (index < userRecipes.length) {
                            final recipe = userRecipes[index];
                            return _buildFirebaseRecipeCard(recipe, context);
                          } else {
                            final recipe = _filteredRecipes[
                                index - userRecipes.length];
                            return _buildApiRecipeCard(recipe, context);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // 🔹 Recipe from API
  Widget _buildApiRecipeCard(dynamic recipe, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(recipe: recipe),
          ),
        );
      },
      child: _buildCard(
        image: recipe['image'],
        name: recipe['name'],
        category: recipe['mealType']?.first ?? "General",
        prepTime: "${recipe['prepTimeMinutes']} min",
        context: context,
      ),
    );
  }

  // 🔹 Recipe from Firebase
  Widget _buildFirebaseRecipeCard(
      Map<String, dynamic> recipe, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FirebaseRecipeDetailsScreen(recipe: recipe),
          ),
        );
      },
      child: _buildCard(
        image: recipe['image'] ?? '',
        name: recipe['name'] ?? 'No Name',
        category: recipe['category'] ?? 'N/A',
        prepTime: recipe['prepTime'] ?? '--',
        context: context,
      ),
    );
  }

  // 🧱 Reusable Card Widget
  Widget _buildCard({
    required String image,
    required String name,
    required String category,
    required String prepTime,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: image.isNotEmpty
                  ? Image.network(image,
                      width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      color: theme.dividerColor.withOpacity(0.1),
                      child: const Icon(Icons.image, size: 50),
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text("Category: $category",
                      style: theme.textTheme.bodyMedium),
                  Text("Prep: $prepTime", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name']),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe['image'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(recipe['name'],
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Category: ${recipe['mealType']?.join(', ') ?? 'N/A'}",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text("Ingredients:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...List.generate(
              (recipe['ingredients'] as List).length,
              (index) => Text("• ${recipe['ingredients'][index]}"),
            ),
            const SizedBox(height: 16),
            const Text("Instructions:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(recipe['instructions'].join('\n')),
          ],
        ),
      ),
    );
  }
}

class FirebaseRecipeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const FirebaseRecipeDetailsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name'] ?? 'Recipe'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe['image'] != null && recipe['image'] != '')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipe['image'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(recipe['name'] ?? '',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Category: ${recipe['category'] ?? 'N/A'}",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Prep Time: ${recipe['prepTime'] ?? '--'}",
                style: theme.textTheme.bodyMedium),
            Text("Cook Time: ${recipe['cookTime'] ?? '--'}",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text("Servings: ${recipe['servings'] ?? '--'}",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            const Text("🧾 Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(recipe['description'] ?? 'No details provided'),
          ],
        ),
      ),
    );
  }
}
