import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class UserInformationService {
  static const String baseUrl = ApiConfig.baseUrl;

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

  // ✅ GET CURRENT USER PROFILE
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _headers(),
      );
      print('PROFILE GET STATUS: ${response.statusCode}');
      print('PROFILE GET BODY: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        if (data is Map && data.containsKey('data')) return Map<String, dynamic>.from(data['data']);
        return null;
      }
      return null;
    } catch (e) {
      print('PROFILE GET ERROR: $e');
      return null;
    }
  }

  // ✅ UPDATE CURRENT USER PROFILE
  static Future<bool> updateProfile({
    required String name,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
        }),
      );
      print('PROFILE UPDATE STATUS: ${response.statusCode}');
      print('PROFILE UPDATE BODY: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('PROFILE UPDATE ERROR: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: await _headers(),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      print('CHANGE PASSWORD STATUS: ${response.statusCode}');
      print('CHANGE PASSWORD BODY: ${response.body}');

      final data = jsonDecode(response.body);
      final message = data is Map
          ? data['message']?.toString() ?? 'Something went wrong'
          : 'Something went wrong';

      return {
        'success': response.statusCode == 200,
        'message': message,
      };
    } catch (e) {
      print('CHANGE PASSWORD ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getAddresses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: await _headers(),
      );

      print('ADDRESS GET STATUS: ${response.statusCode}');
      print('ADDRESS GET BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('data')) return data['data'] ?? [];
        if (data is Map && data.containsKey('addresses')) return data['addresses'] ?? [];
        return [];
      } else {
        throw Exception('Failed to fetch addresses: ${response.statusCode}');
      }
    } catch (e) {
      print('ADDRESS GET ERROR: $e');
      rethrow;
    }
  }

  // ✅ DELETE ADDRESS
  static Future<bool> deleteAddress(int addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$addressId'),
        headers: await _headers(),
      );
      print('ADDRESS DELETE STATUS: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ADDRESS DELETE ERROR: $e');
      return false;
    }
  }

  // ✅ ADD ADDRESS
  static Future<bool> addAddress({
    required String token,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    required String country,
    String? latitude,
    String? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "address_line": addressLine,
        "city": city,
        "state": state,
        "pincode": pincode,
        "country": country,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print(response.body);
      return false;
    }
  }
}