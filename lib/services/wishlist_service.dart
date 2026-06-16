import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistItem {
  final int productId;
  final String productName;
  final String brand;
  final String price;
  final String imageUrl;

  const WishlistItem({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.price,
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'brand': brand,
        'price': price,
        'image_url': imageUrl,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['product_id'] is int
          ? json['product_id'] as int
          : int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class WishlistService {
  static const _storageKey = 'wishlist_items';

  static Future<List<WishlistItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => WishlistItem.fromJson(Map<String, dynamic>.from(e)))
          .where((item) => item.productId > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isInWishlist(int productId) async {
    if (productId <= 0) return false;
    final items = await getItems();
    return items.any((item) => item.productId == productId);
  }

  static Future<bool> addItem(WishlistItem item) async {
    if (item.productId <= 0) return false;

    final items = await getItems();
    if (items.any((i) => i.productId == item.productId)) return true;

    items.add(item);
    return _save(items);
  }

  static Future<bool> removeItem(int productId) async {
    final items = await getItems();
    items.removeWhere((item) => item.productId == productId);
    return _save(items);
  }

  static Future<bool> toggleItem(WishlistItem item) async {
    if (item.productId <= 0) return false;

    final exists = await isInWishlist(item.productId);
    if (exists) {
      await removeItem(item.productId);
      return false;
    }
    await addItem(item);
    return true;
  }

  static Future<int> getCount() async {
    final items = await getItems();
    return items.length;
  }

  static Future<bool> _save(List<WishlistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    return prefs.setString(_storageKey, encoded);
  }
}
