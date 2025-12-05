class UserRecipe {
  final String name;
  final String category;
  final String difficulty;
  final String prepTime;
  final String cookTime;
  final String servings;
  final String imagePath; // local image path

  UserRecipe({
    required this.name,
    required this.category,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.imagePath,
  });
}
