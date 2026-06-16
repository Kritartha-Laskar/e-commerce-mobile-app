import 'package:flutter/material.dart';

import 'categories_page.dart';
import 'product_details_page.dart';
import 'search_page.dart';
import '../services/product_api.dart';
import '../services/cataegori_api.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';
import '../widgets/ngrok_image.dart';
import '../models/product_model.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}
class _FrontPageState extends State<FrontPage> {
  List<ProductModel> products = [];
  bool isLoading = true;

  List categories = [];
  bool isCategoriesLoading = true;
  String selectedCategory = "All";

  // ✅ CHANGE BASE URL IF NEEDED
  // final String baseUrl = "http://10.0.2.2:8000/api";
  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCategories();
  }

  Future<void> fetchProducts() async {
    try {
      final fetchedProducts = await ProductApi.getStorefrontProducts();

      final loadedProducts = fetchedProducts
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await CategoryApi.getCategories();
      setState(() {
        categories = fetchedCategories;
        isCategoriesLoading = false;
      });
    } catch (e) {
      print("CATEGORY FETCH ERROR: $e");
      setState(() {
        isCategoriesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 HEADER
              const TopBar(),

              const SizedBox(height: 20),

              // 🔍 SEARCH
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: "Search products...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📌 CATEGORY (API)
              isCategoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _categoryChip("All"),
                          ...categories.map((category) {
                            return _categoryChip(category['name']?.toString() ?? "Unknown");
                          }).toList(),
                        ],
                      ),
                    ),

              const SizedBox(height: 20),

              // 🎟️ BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFF7F6CF2)],
                  ),
                ),
                child: const Text(
                  "Summer Sale!",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 25),

              // ✨ FEATURED TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Featured",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Color(0xFF6A5AE0)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // 🛍️ PRODUCTS FROM API
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        List<ProductModel> filteredProducts = selectedCategory == "All"
                            ? products
                            : products.where((p) {
                                String? catName = p.category?['name']?.toString();
                                return catName != null && catName.toLowerCase() == selectedCategory.toLowerCase();
                              }).toList();

                        if (filteredProducts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                "No products found for this category.",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: filteredProducts.map((product) {
                              return _productCardApi(product);
                            }).toList(),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // 🔻 NAV BAR
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 0),
    );
  }

  // CATEGORY CHIP
  Widget _categoryChip(String title) {
    bool active = selectedCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6A5AE0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF6A5AE0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _productCardApi(ProductModel product) {
    // ✅ SAFE DATA EXTRACTION FROM MODEL
    String name = product.productName;
    String price = product.price;

    List<String> imageUrls = product.allImageUrls;
    if (imageUrls.isEmpty) {
      final fallbackUrl = ProductApi.getImageUrl(product.rawJson);
      if (fallbackUrl.isNotEmpty &&
          !fallbackUrl.contains('dummyimage.com')) {
        imageUrls = [fallbackUrl];
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              name: name,
              brand: product.category?['name']?.toString() ?? "",
              price: price,
              imageColor: Colors.grey,
              productId: product.id,
              imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrls.isNotEmpty
                    ? imageUrls.length == 1
                        ? NgrokImage(
                            imageUrl: imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          )
                        : PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, imgIndex) {
                              return NgrokImage(
                                imageUrl: imageUrls[imgIndex],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 120,
                              );
                            },
                          )
                    : const Center(
                        child: Icon(
                          Icons.image,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ SAFE TEXT
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 5),

            Text(
              "₹$price",
              style: const TextStyle(
                color: Color(0xFF6A5AE0),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
