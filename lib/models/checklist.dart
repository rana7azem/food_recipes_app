class ChecklistItem {
  final String id;
  final String name;
  final String category;
  bool isChecked;
  final String quantity;
  final String unit;

  ChecklistItem({
    required this.id,
    required this.name,
    required this.category,
    this.isChecked = false,
    required this.quantity,
    required this.unit,
  });

  ChecklistItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isChecked,
    String? quantity,
    String? unit,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}

class Checklist {
  final String id;
  final String title;
  final String recipeId;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final DateTime? completedAt;

  Checklist({
    required this.id,
    required this.title,
    required this.recipeId,
    required this.items,
    required this.createdAt,
    this.completedAt,
  });

  static List<Checklist> sampleChecklists = [
    Checklist(
      id: '1',
      title: 'Chocolate Chip Cookies',
      recipeId: 'recipe_1',
      createdAt: DateTime.now(),
      items: [
        ChecklistItem(
          id: '1',
          name: 'All-purpose flour',
          category: 'Dry Ingredients',
          quantity: '2',
          unit: 'cups',
        ),
        ChecklistItem(
          id: '2',
          name: 'Butter',
          category: 'Dairy',
          quantity: '1',
          unit: 'cup',
        ),
        ChecklistItem(
          id: '3',
          name: 'Brown sugar',
          category: 'Sweeteners',
          quantity: '3/4',
          unit: 'cup',
        ),
        ChecklistItem(
          id: '4',
          name: 'Eggs',
          category: 'Dairy',
          quantity: '2',
          unit: 'pieces',
        ),
        ChecklistItem(
          id: '5',
          name: 'Vanilla extract',
          category: 'Flavoring',
          quantity: '1',
          unit: 'tsp',
        ),
        ChecklistItem(
          id: '6',
          name: 'Chocolate chips',
          category: 'Add-ons',
          quantity: '2',
          unit: 'cups',
        ),
      ],
    ),
    Checklist(
      id: '2',
      title: 'Caesar Salad',
      recipeId: 'recipe_2',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        ChecklistItem(
          id: '1',
          name: 'Romaine lettuce',
          category: 'Vegetables',
          quantity: '2',
          unit: 'heads',
          isChecked: true,
        ),
        ChecklistItem(
          id: '2',
          name: 'Parmesan cheese',
          category: 'Dairy',
          quantity: '1/2',
          unit: 'cup',
        ),
        ChecklistItem(
          id: '3',
          name: 'Croutons',
          category: 'Bread',
          quantity: '1',
          unit: 'cup',
          isChecked: true,
        ),
      ],
    ),
  ];
}
