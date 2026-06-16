import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ProductApi {
  // 🔥 CHANGE THIS BASED ON PLATFORM
  static const String baseUrl = ApiConfig.baseUrl;
  // static const String imageBaseUrl = 'http://127.0.0.1:8000/storage/';
  // static const String imageBaseUrl = 'http://localhost:8000/storage/';
  static const String imageBaseUrl = '${ApiConfig.storageUrl}/';

  /// Loads products for the home page and ensures image data when possible.
  static Future<List<dynamic>> getStorefrontProducts() async {
    final headers = await _authHeaders();

    // Prefer public catalog with images (backend: getProduct uses with images).
    for (final url in [
      '$baseUrl/get-product',
      '$baseUrl/get-product?with=images&include=images',
    ]) {
      final list = await _fetchProductListFromUrl(url, headers);
      if (list.isNotEmpty && _productsHaveImages(list)) {
        print('STOREFRONT: loaded ${list.length} products with images');
        return list;
      }
    }

    var products = await getProducts();
    if (products.isEmpty) return products;

    if (_productsHaveImages(products)) return products;

    products = await _mergeImagesFromUserProducts(products);
    if (_productsHaveImages(products)) {
      print('STOREFRONT: merged images from user-products');
      return products;
    }

    return products;
  }

  static Future<List<dynamic>> _fetchProductListFromUrl(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return _extractProductList(jsonDecode(response.body));
      }
    } catch (e) {
      print('FETCH PRODUCTS FROM $url FAILED: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getProducts() async {
    List<dynamic>? fallbackProducts;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 1. Try listing products via standard REST /products endpoint (usually has full images relation)
      try {
        final response = await http.get(
          Uri.parse("$baseUrl/products"),
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        print("STANDARD PRODUCTS API STATUS: ${response.statusCode}");
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = _extractProductList(data);
          if (list.isNotEmpty) {
            if (_productsHaveImages(list)) return list;
            fallbackProducts = list;
          }
        }
      } catch (e) {
        print("STANDARD PRODUCTS API FAILED: $e");
      }

      // 2. Try calling /get-product with relation query params to trigger eager loading (e.g. ?with=images)
      try {
        final response = await http.get(
          Uri.parse("$baseUrl/get-product?with=images&include=images"),
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        print("GET-PRODUCT WITH RELATION API STATUS: ${response.statusCode}");
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = _extractProductList(data);

          if (list.isNotEmpty && _productsHaveImages(list)) {
            print("SUCCESSFULLY LOADED RELATIONSHIPS DYNAMICALLY!");
            return list;
          }
        }
      } catch (e) {
        print("GET-PRODUCT WITH RELATION FAILED: $e");
      }

      // 3. Fallback to default /get-product custom endpoint
      final response = await http.get(
        Uri.parse("$baseUrl/get-product"),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("GET-PRODUCT API STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = _extractProductList(data);
        return list.isNotEmpty ? list : fallbackProducts ?? [];
      } else {
        if (fallbackProducts != null) return fallbackProducts;
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      print("API ERROR: $e");
      if (fallbackProducts != null) return fallbackProducts;
      throw Exception("API Error");
    }
  }

  // ✅ HELPER FUNCTION FOR IMAGE URL
  // static String getImageUrl(dynamic product) {
  //   if (product['images'] != null && product['images'].isNotEmpty) {
  //     return imageBaseUrl + product['images'][0]['image'];
  //   }
  //   return "";
  // }
  static List<dynamic> _extractProductList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['products'] is List) {
      return List<dynamic>.from(data['products']);
    }
    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    return [];
  }

  static bool _productsHaveImages(List<dynamic> products) {
    return products.any((product) {
      if (product is! Map) return false;

      final image =
          product['image'] ?? product['image_url'] ?? product['image_path'];
      if (image != null &&
          image.toString().isNotEmpty &&
          image.toString() != 'NA') {
        return true;
      }

      final imageLists = [
        product['images'],
        product['product_images'],
        product['productImages'],
        product['media'],
        product['gallery'],
      ];

      return imageLists.any((images) {
        if (images is List) return images.isNotEmpty;
        if (images is Map) return images.isNotEmpty;
        if (images is String) {
          return images.trim().isNotEmpty && images.trim() != 'NA';
        }
        return false;
      });
    });
  }

  static String getImageUrl(dynamic product) {
    try {
      if (product['image'] != null &&
          product['image'].toString().isNotEmpty &&
          product['image'].toString() != 'NA') {
        return imageBaseUrl + product['image'].toString();
      } else if (product['images'] != null &&
          product['images'] is List &&
          product['images'].isNotEmpty) {
        // Sometimes it's 'image' or 'image_path' or 'image_url'
        var firstImg = product['images'][0];
        if (firstImg['image'] != null) {
          return imageBaseUrl + firstImg['image'].toString();
        } else if (firstImg['image_url'] != null) {
          // If the backend already returns a full URL
          if (firstImg['image_url'].toString().startsWith('http')) {
            return firstImg['image_url'].toString();
          }
          return imageBaseUrl + firstImg['image_url'].toString();
        }
      }
    } catch (e) {
      print("IMAGE ERROR: $e");
    }

    return "";
  }

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static bool _productHasImages(Map product) {
    return _productsHaveImages([product]);
  }

  /// Copies `images` arrays from /user-products onto matching storefront products.
  static Future<List<dynamic>> _mergeImagesFromUserProducts(
    List<dynamic> products,
  ) async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return products;

      final response = await http.get(
        Uri.parse('$baseUrl/user-products'),
        headers: headers,
      );

      if (response.statusCode != 200) return products;

      final userProducts = jsonDecode(response.body);
      if (userProducts is! List) return products;

      final imagesById = <int, List<dynamic>>{};
      for (final item in userProducts) {
        if (item is! Map) continue;
        final images = item['images'];
        if (images is! List || images.isEmpty) continue;

        final id = item['id'] is int
            ? item['id'] as int
            : int.tryParse(item['id']?.toString() ?? '');
        if (id != null) imagesById[id] = List<dynamic>.from(images);
      }

      return products.map((product) {
        if (product is! Map) return product;
        final id = product['id'] is int
            ? product['id'] as int
            : int.tryParse(product['id']?.toString() ?? '');
        if (id == null || !imagesById.containsKey(id)) return product;

        final merged = Map<String, dynamic>.from(product);
        merged['images'] = imagesById[id];
        return merged;
      }).toList();
    } catch (e) {
      print('MERGE USER-PRODUCT IMAGES ERROR: $e');
      return products;
    }
  }

  /// Fetches single-product details when list endpoint omits images.
  static Future<List<dynamic>> _enrichEachProductWithImages(
    List<dynamic> products,
  ) async {
    final headers = await _authHeaders();
    final enriched = <dynamic>[];

    for (final product in products) {
      if (product is! Map) {
        enriched.add(product);
        continue;
      }

      if (_productHasImages(product)) {
        enriched.add(product);
        continue;
      }

      final id = product['id'] is int
          ? product['id'] as int
          : int.tryParse(product['id']?.toString() ?? '');

      if (id == null) {
        enriched.add(product);
        continue;
      }

      Map<String, dynamic>? detail;
      for (final url in [
        '$baseUrl/products/$id?with=images',
        '$baseUrl/products/$id',
        '$baseUrl/get-product/$id',
      ]) {
        detail = await _fetchProductMap(url, headers);
        if (detail != null && _productHasImages(detail)) break;
      }

      enriched.add(detail ?? product);
    }

    return enriched;
  }

  static Future<Map<String, dynamic>?> _fetchProductMap(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      if (data is Map && data['product'] is Map) {
        return Map<String, dynamic>.from(data['product'] as Map);
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      print('FETCH PRODUCT DETAIL ERROR ($url): $e');
    }
    return null;
  }
}
