import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CategoryApi {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Fetches all categories.
  /// Note: This uses the `/get-category` endpoint which returns JSON.
  static Future<List<dynamic>> getCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$baseUrl/get-category"),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("GET CATEGORIES STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'] ?? [];
        } else if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception("Failed to load categories: ${response.statusCode}");
      }
    } catch (e) {
      print("CATEGORY API ERROR: $e");
      return [];
    }
  }

  /// Creates a new category.
  static Future<bool> addCategory(String name, String status) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("$baseUrl/categories"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'status': status,
        }),
      );

      print("ADD CATEGORY STATUS: ${response.statusCode}");
      
      // Usually successful creation returns 200 or 201
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302;
    } catch (e) {
      print("ADD CATEGORY ERROR: $e");
      return false;
    }
  }

  /// Updates an existing category.
  static Future<bool> updateCategory(int id, String name, String status) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse("$baseUrl/categories/$id"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'status': status,
        }),
      );

      print("UPDATE CATEGORY STATUS: ${response.statusCode}");
      
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print("UPDATE CATEGORY ERROR: $e");
      return false;
    }
  }

  /// Deletes a category.
  static Future<bool> deleteCategory(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse("$baseUrl/categories/$id"),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("DELETE CATEGORY STATUS: ${response.statusCode}");
      
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print("DELETE CATEGORY ERROR: $e");
      return false;
    }
  }
}
