class FormValidator {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateRecipeName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Recipe name is required';
    }
    if (value.length < 3) {
      return 'Recipe name must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Recipe name must not exceed 100 characters';
    }
    return null;
  }

  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    final num = int.parse(value);
    if (num <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? validateTime(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    final num = int.tryParse(value);
    if (num == null) {
      return '$fieldName must be a valid number';
    }
    if (num < 1 || num > 1440) {
      return '$fieldName must be between 1 and 1440 minutes (24 hours)';
    }
    return null;
  }

  static String? validateServings(String? value) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    final num = int.tryParse(value);
    if (num == null) {
      return 'Servings must be a valid number';
    }
    if (num < 1 || num > 100) {
      return 'Servings must be between 1 and 100';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }
    if (value.length < 2) {
      return 'Category must be at least 2 characters';
    }
    return null;
  }

  static String? validateDifficulty(String? value) {
    if (value == null || value.isEmpty) {
      return null; 
    }
    final validLevels = ['easy', 'medium', 'hard'];
    if (!validLevels.contains(value.toLowerCase())) {
      return 'Difficulty must be Easy, Medium, or Hard';
    }
    return null;
  }

  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isFormComplete({
    required String name,
    required String category,
    bool requireImage = false,
    bool hasImage = false,
  }) {
    if (name.isEmpty || category.isEmpty) return false;
    if (requireImage && !hasImage) return false;
    return true;
  }
}
