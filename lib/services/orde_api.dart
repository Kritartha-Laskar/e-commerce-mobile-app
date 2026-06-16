import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class OrderApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> placeOrder({
    required int productId,
    required int quantity,
    required String deliveryAddress,
    required String deliveryPhoneNo,
    required String paymentMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: {
        'product_id': productId.toString(),
        'quantity': quantity.toString(),
        'delivery_address': deliveryAddress,
        'delivery_phone_no': deliveryPhoneNo,
        'payment_mode': paymentMode,
      },
    );

    print("PLACE ORDER STATUS: ${response.statusCode}");
    print("PLACE ORDER BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to place order'
        };
      } catch (e) {
        return {'success': false, 'message': 'An error occurred'};
      }
    }
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/my-orders — logged-in user's orders
  static Future<List<dynamic>> getMyOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders'),
        headers: await _headers(),
      );

      print('MY ORDERS STATUS: ${response.statusCode}');
      print('MY ORDERS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data['data'] is List) {
          return List<dynamic>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('MY ORDERS ERROR: $e');
      return [];
    }
  }
}
