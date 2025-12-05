import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_recipes_app/helper/api_service.dart';
import 'package:food_recipes_app/screens/Add.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _searchController.addListener(() => setState(() {}));
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            )
          : Column(
              children: [
                // Search Bar
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
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),

                // Category Filter
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
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
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

                // Recipes Grid (Firebase + API)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recipes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userRecipes = snapshot.hasData
                          ? snapshot.data!.docs
                          : <QueryDocumentSnapshot>[];

                      if (_filteredRecipes.isEmpty &&
                          (userRecipes.isEmpty || !snapshot.hasData)) {
                        return const Center(
                            child: Text('No recipes found 😔'));
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
                            final recipe = userRecipes[index].data()
                                as Map<String, dynamic>;
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

  // Recipe from API
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
      ),
    );
  }

  // Recipe from Firebase
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
      ),
    );
  }

  Widget _buildCard({
    required String image,
    required String name,
    required String category,
    required String prepTime,
  }) {
    return Card(
      elevation: 4,
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
                      color: Colors.grey[200],
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
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text("Category: $category"),
                  Text("Prep: $prepTime"),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name']),
        backgroundColor: Colors.orangeAccent,
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Category: ${recipe['mealType']?.join(', ') ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name'] ?? 'Recipe'),
        backgroundColor: Colors.orangeAccent,
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Category: ${recipe['category'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Prep Time: ${recipe['prepTime'] ?? '--'}",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            Text("Cook Time: ${recipe['cookTime'] ?? '--'}",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Servings: ${recipe['servings'] ?? '--'}",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
