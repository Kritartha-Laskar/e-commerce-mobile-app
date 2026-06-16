import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ProductStoreApi {

  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> addProduct({

    required String productName,
    required String categoryId,
    required String price,
    required String discount,
    required String quantity,

    List<File>? imageFiles,
    List<Uint8List>? webImages,

  }) async {

    try {

      // ✅ GET TOKEN
      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String token = prefs.getString('token') ?? '';

      // ✅ REQUEST
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      // ✅ BEARER TOKEN
      request.headers['Authorization'] = 'Bearer $token';

      request.headers['Accept'] = 'application/json';

      // ✅ FIELDS
      request.fields['product_name'] = productName;
      request.fields['category_id'] = categoryId;
      request.fields['price'] = price;
      request.fields['discount'] = discount;
      request.fields['avail_count'] = quantity;

      // ✅ WEB IMAGES
      if (kIsWeb) {

        if (webImages != null) {

          for (int i = 0; i < webImages.length; i++) {

            request.files.add(
              http.MultipartFile.fromBytes(
                'images[]',
                webImages[i],
                filename: 'image_$i.jpg',
              ),
            );
          }
        }
      }

      // ✅ MOBILE IMAGES
      else {

        if (imageFiles != null) {

          for (int i = 0; i < imageFiles.length; i++) {

            request.files.add(
              await http.MultipartFile.fromPath(
                'images[]',
                imageFiles[i].path,
              ),
            );
          }
        }
      }

      // ✅ SEND
      var response = await request.send();

      var res =
          await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $res");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        return {
          "success": true,
          "message": "Product Added"
        };

      } else {

        return {
          "success": false,
          "message": res
        };
      }

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}