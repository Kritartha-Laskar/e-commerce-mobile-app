import 'dart:convert';

import '../config/api_config.dart';

class ProductModel {
  final int id;
  final String productName;
  final String price;
  final String image;
  final List images;
  final Map<String, dynamic>? category;
  final Map<String, dynamic> rawJson;

  ProductModel({
    required this.id,
    required this.productName,
    required this.price,
    required this.image,
    required this.images,
    this.category,
    required this.rawJson,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ??
          json['productName']?.toString() ??
          json['name']?.toString() ??
          '',
      price: json['price'].toString(),
      image: _extractMainImagePath(json),
      images: _normalizeImages(json),
      category:
          json['category'] is Map<String, dynamic> ? json['category'] : null,
      rawJson: json,
    );
  }

  static String buildImageUrl(String path) {
    if (path.isEmpty || path == 'NA') return "";
    if (path.startsWith('http')) return path;

    // Clean storageUrl trailing slash
    String cleanStorage = ApiConfig.storageUrl.trim();
    if (cleanStorage.endsWith('/')) {
      cleanStorage = cleanStorage.substring(0, cleanStorage.length - 1);
    }

    // Clean image path leading slash
    String cleanPath = path.trim();
    cleanPath = cleanPath.replaceAll('\\', '/');
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Keep path as-is for Laravel public disk URLs (encoding breaks some filenames).
    return "$cleanStorage/$cleanPath";
  }

  String get imageUrl {
    if (image.isNotEmpty && image != 'NA') {
      return buildImageUrl(image);
    } else if (images.isNotEmpty) {
      var firstImg = images[0];
      var imgPath = _imagePathFromEntry(firstImg);
      if (imgPath != null && imgPath.isNotEmpty && imgPath != 'NA') {
        return buildImageUrl(imgPath);
      }
    }
    return "";
  }

  List<String> get allImageUrls {
    final paths = <String>[];

    if (image.isNotEmpty && image != 'NA') {
      paths.add(image);
    }
    for (final img in images) {
      final imgPath = _imagePathFromEntry(img);
      if (imgPath != null && imgPath.isNotEmpty && imgPath != 'NA') {
        paths.add(imgPath);
      }
    }

    if (paths.isEmpty) {
      _collectImagePathsFromMap(rawJson, paths);
    }

    return paths
        .map(buildImageUrl)
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
  }

  static String _extractMainImagePath(Map<String, dynamic> json) {
    final candidates = [
      json['image'],
      json['image_url'],
      json['image_path'],
      json['imagePath'],
      json['thumbnail'],
      json['thumbnail_url'],
      json['product_image'],
      json['photo'],
      json['cover'],
    ];

    for (final candidate in candidates) {
      final path = _imagePathFromEntry(candidate);
      if (path != null && path.isNotEmpty && path != 'NA') {
        return path;
      }
    }

    return '';
  }

  static void _collectImagePathsFromMap(
    Map<String, dynamic> map,
    List<String> paths, [
    int depth = 0,
  ]) {
    if (depth > 5) return;

    for (final entry in map.entries) {
      final key = entry.key.toString().toLowerCase();
      final value = entry.value;

      if (key.contains('image') ||
          key.contains('photo') ||
          key.contains('thumbnail') ||
          key.contains('cover')) {
        final path = _imagePathFromEntry(value);
        if (path != null &&
            path.isNotEmpty &&
            path != 'NA' &&
            !path.startsWith('{')) {
          paths.add(path);
        }
      }

      if (value is Map) {
        _collectImagePathsFromMap(
          Map<String, dynamic>.from(value),
          paths,
          depth + 1,
        );
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            _collectImagePathsFromMap(
              Map<String, dynamic>.from(item),
              paths,
              depth + 1,
            );
          } else {
            final path = _imagePathFromEntry(item);
            if (path != null &&
                path.isNotEmpty &&
                path != 'NA' &&
                !path.startsWith('{')) {
              paths.add(path);
            }
          }
        }
      }
    }
  }

  static String? _imagePathFromEntry(dynamic imageEntry) {
    if (imageEntry is String) {
      return imageEntry;
    }

    if (imageEntry is Map) {
      return imageEntry['image']?.toString() ??
          imageEntry['image_url']?.toString() ??
          imageEntry['image_path']?.toString() ??
          imageEntry['imagePath']?.toString() ??
          imageEntry['path']?.toString() ??
          imageEntry['url']?.toString() ??
          imageEntry['file']?.toString() ??
          imageEntry['file_path']?.toString() ??
          imageEntry['filename']?.toString();
    }

    return null;
  }

  static List _normalizeImages(Map<String, dynamic> json) {
    final candidates = [
      json['images'],
      json['product_images'],
      json['productImages'],
      json['product_image'],
      json['productImage'],
      json['media'],
      json['files'],
      json['gallery'],
      json['photos'],
    ];

    for (final candidate in candidates) {
      final images = _imagesFromValue(candidate);
      if (images.isNotEmpty) return images;
    }

    return [];
  }

  static List _imagesFromValue(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is Map) return [value];

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'NA') return [];

      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        try {
          final decoded = jsonDecode(trimmed);
          return _imagesFromValue(decoded);
        } catch (_) {
          return [trimmed];
        }
      }

      return [trimmed];
    }

    return [];
  }
}
