
class FormHandler {
  final Map<String, String> _formData = {};

  String getFieldValue(String fieldName) {
    return _formData[fieldName] ?? '';
  }

  void setFieldValue(String fieldName, String value) {
    _formData[fieldName] = value;
  }

  Map<String, String> getAllFormData() {
    return Map.from(_formData);
  }

  void clearField(String fieldName) {
    _formData.remove(fieldName);
  }

  void clearAllData() {
    _formData.clear();
  }

  bool isFieldEmpty(String fieldName) {
    return _formData[fieldName]?.isEmpty ?? true;
  }

  int getFilledFieldCount() {
    return _formData.values.where((value) => value.isNotEmpty).length;
  }

  Map<String, dynamic> buildRecipeData({
    required String imageUrl,
    required List<String> ingredients,
    required List<String> instructions,
  }) {
    return {
      'name': _formData['name']?.trim() ?? '',
      'category': _formData['category']?.trim() ?? '',
      'difficulty': _formData['difficulty']?.trim() ?? '',
      'prepTime': _formData['prepTime']?.trim() ?? '',
      'cookTime': _formData['cookTime']?.trim() ?? '',
      'servings': _formData['servings']?.trim() ?? '',
      'description': _formData['description']?.trim() ?? '',
      'image': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
