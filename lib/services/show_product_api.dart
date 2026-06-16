import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

import '../config/api_config.dart';

class ShowProductApi {

  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<ProductModel>> getProducts() async {

    // ✅ GET TOKEN
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    print("TOKEN: $token");

    final response = await http.get(
      Uri.parse('$baseUrl/user-products'),

      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      },
    );

    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);

      return data
          .map((e) => ProductModel.fromJson(e))
          .toList();

    } else {

      return [];
    }
  }
}