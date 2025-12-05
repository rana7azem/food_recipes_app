import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://dummyjson.com/recipes';

  // fetch recipes list
  static Future<List<dynamic>> fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['recipes']; // قائمة الوصفات
      } else {
        throw Exception('Failed to load recipes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
