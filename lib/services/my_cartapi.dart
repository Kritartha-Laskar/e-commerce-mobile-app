import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class MyCartApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── GET ALL CART ITEMS ───────────────────────────────────────────────────
  /// GET /api/carts
  static Future<List<dynamic>> getCartItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/carts'),
        headers: await _headers(),
      );

      print('CART GET STATUS: ${response.statusCode}');
      print('CART GET BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        // Backend may return all carts — keep only the logged-in user's items.
        final prefs = await SharedPreferences.getInstance();
        final int? userId = prefs.getInt('user_id');
        if (userId != null) {
          return items
              .where((item) =>
                  item is Map &&
                  item['user_id']?.toString() == userId.toString())
              .toList();
        }
        return items;
      } else {
        throw Exception('Failed to fetch cart items: ${response.statusCode}');
      }
    } catch (e) {
      print('CART GET ERROR: $e');
      rethrow;
    }
  }

  // ─── ADD ITEM TO CART ─────────────────────────────────────────────────────
  /// POST /api/carts
  static Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carts'),
        headers: await _headers(),
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      print('CART POST STATUS: ${response.statusCode}');
      print('CART POST BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to add to cart'};
      }
    } catch (e) {
      print('CART POST ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── SHOW SINGLE CART ITEM ────────────────────────────────────────────────
  /// GET /api/carts/{id}
  static Future<Map<String, dynamic>?> getCartItem(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/carts/$id'),
        headers: await _headers(),
      );

      print('CART SHOW STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('CART SHOW ERROR: $e');
      return null;
    }
  }

  // ─── UPDATE CART ITEM QUANTITY ────────────────────────────────────────────
  /// PUT /api/carts/{id}
  static Future<Map<String, dynamic>> updateCartItem({
    required int cartId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/carts/$cartId'),
        headers: await _headers(),
        body: jsonEncode({'quantity': quantity}),
      );

      print('CART UPDATE STATUS: ${response.statusCode}');
      print('CART UPDATE BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'], 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update cart'};
      }
    } catch (e) {
      print('CART UPDATE ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── DELETE CART ITEM ─────────────────────────────────────────────────────
  /// DELETE /api/carts/{id}
  static Future<bool> deleteCartItem(int cartId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/carts/$cartId'),
        headers: await _headers(),
      );

      print('CART DELETE STATUS: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('CART DELETE ERROR: $e');
      return false;
    }
  }
}
