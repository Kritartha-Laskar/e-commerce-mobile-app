import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SellerOrdersApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers(String? token) => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// GET /api/recent-orders — fetch all pending/recent orders for the seller
  static Future<List<dynamic>> getRecentOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/recent-orders'),
      headers: _headers(token),
    );
    print("RECENT ORDERS STATUS: ${response.statusCode}");
    print("RECENT ORDERS BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
      if (data is Map && data['orders'] is List) return data['orders'];
    }
    return [];
  }

  /// GET /api/my-order-saler — fetch seller's confirmed/accepted orders
  static Future<List<dynamic>> getMyOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/my-order-saler'),
      headers: _headers(token),
    );
    print("MY ORDERS STATUS: ${response.statusCode}");
    print("MY ORDERS BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
      if (data is Map && data['orders'] is List) return data['orders'];
    }
    return [];
  }

  /// POST /api/orders/{id}/confirm — seller confirms an order
  static Future<bool> confirmOrder(int orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/confirm'),
      headers: _headers(token),
    );
    print("CONFIRM ORDER STATUS: ${response.statusCode}");
    print("CONFIRM ORDER BODY: ${response.body}");
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// POST /api/orders/{id}/delivered — seller marks an order as delivered
  static Future<bool> deliverOrder(int orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/delivered'),
      headers: _headers(token),
    );
    print("DELIVER ORDER STATUS: ${response.statusCode}");
    print("DELIVER ORDER BODY: ${response.body}");
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
