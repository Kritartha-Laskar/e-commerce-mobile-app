import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {

  static const String baseUrl = ApiConfig.baseUrl;

  // ✅ LOGIN
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
    [String userType = "user"]
  ) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {
        'email': email,
        'password': password,
        'user_type': userType,
      },
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      // ✅ SAVE TOKEN
      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        data['token'],
      );

      // ✅ SAVE USER ID
      await prefs.setInt(
        'user_id',
        data['user']['id'],
      );

      // ✅ SAVE USER TYPE
      await prefs.setString(
        'user_type',
        data['user']['user_type'],
      );

      // ✅ SAVE USER NAME
      if (data['user']['name'] != null) {
        await prefs.setString(
          'user_name',
          data['user']['name'],
        );
      }

      // ✅ SAVE USER EMAIL
      if (data['user']['email'] != null) {
        await prefs.setString(
          'user_email',
          data['user']['email'],
        );
      }

      print("TOKEN SAVED: ${data['token']}");

      return data;

    } else {

      return null;
    }
  }

  // ✅ REGISTER
  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String userType,
  ) async {

    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {
        'name': name,
        'email': email,
        'password': password,
        'user_type': userType,
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print("REGISTER ERROR: ${response.body}");
      return null;
    }
  }

  // ✅ GET SAVED TOKEN
  static Future<String?> getToken() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // ✅ GET USER ID
  static Future<int?> getUserId() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt('user_id');
  }

  // ✅ GET USER TYPE
  static Future<String?> getUserType() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('user_type');
  }

  // ✅ GET USER NAME
  static Future<String?> getUserName() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('user_name');
  }
}