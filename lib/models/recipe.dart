class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final int prepTime; // in minutes
  final double rating;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.prepTime,
    this.rating = 0.0,
  });

  // Sample data
  static List<Recipe> sampleRecipes = [
    Recipe(
      id: '1',
      title: 'Pasta Carbonara',
      imageUrl: 'assets/images/pasta.jpg',
      category: 'Italian',
      prepTime: 25,
      rating: 4.7,
    ),
    Recipe(
      id: '2',
      title: 'Chicken Tikka Masala',
      imageUrl: 'assets/images/tikka.jpg',
      category: 'Indian',
      prepTime: 45,
      rating: 4.8,
    ),
    Recipe(
      id: '3',
      title: 'Caesar Salad',
      imageUrl: 'assets/images/salad.jpg',
      category: 'Salad',
      prepTime: 15,
      rating: 4.5,
    ),
    Recipe(
      id: '4',
      title: 'Beef Burger',
      imageUrl: 'assets/images/burger.jpg',
      category: 'Fast Food',
      prepTime: 20,
      rating: 4.6,
    ),
  ];

  // Get unique categories from recipes
  static List<String> get categories {
    final categories = sampleRecipes.map((r) => r.category).toSet().toList();
    return ['All'] + categories;
  }
}
