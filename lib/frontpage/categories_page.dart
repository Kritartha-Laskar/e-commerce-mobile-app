import 'package:flutter/material.dart';
import 'category_products_page.dart';
import '../services/cataegori_api.dart';
import '../services/product_api.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  bool isLoading = true;

  static const _iconPalette = [
    (Icons.remove_red_eye_outlined, Color(0xFFF1EEFF), Color(0xFF6A5AE0)),
    (Icons.desktop_windows_outlined, Color(0xFFE5F1D5), Color(0xFF4C8C2A)),
    (Icons.shopping_bag_outlined, Color(0xFFFAE0E4), Color(0xFFB5445A)),
    (Icons.radio_button_unchecked, Color(0xFFFDF0D5), Color(0xFF9E651D)),
    (Icons.favorite_border, Color(0xFFE0F4E8), Color(0xFF1E7A53)),
    (Icons.category_outlined, Color(0xFFE8EAF6), Color(0xFF3949AB)),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        CategoryApi.getCategories(),
        ProductApi.getStorefrontProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        categories = results[0];
        products = results[1];
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  int _productCountForCategory(dynamic category) {
    return products.where((p) => _productMatchesCategory(p, category)).length;
  }

  bool _productMatchesCategory(dynamic product, dynamic category) {
    if (product is! Map) return false;

    final categoryId = category['id']?.toString();
    final categoryName =
        category['name']?.toString().toLowerCase().trim() ?? '';

    final productCategory = product['category'];
    if (productCategory is Map) {
      if (categoryId != null &&
          productCategory['id']?.toString() == categoryId) {
        return true;
      }
      final productCatName =
          productCategory['name']?.toString().toLowerCase().trim();
      if (categoryName.isNotEmpty && productCatName == categoryName) {
        return true;
      }
    }

    if (categoryId != null &&
        product['category_id']?.toString() == categoryId) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8FB),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 15, right: 15),
                child: TopBar(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 15,
                  right: 15,
                  bottom: 15,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1EEFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF6A5AE0),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Categories",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No categories found",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadData,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == categories.length) {
                                  return _allCategoriesCard(context);
                                }

                                final category = categories[index];
                                final palette =
                                    _iconPalette[index % _iconPalette.length];

                                return _categoryCard(
                                  context,
                                  icon: palette.$1,
                                  title: category['name']?.toString() ??
                                      'Unknown',
                                  items:
                                      "${_productCountForCategory(category)} items",
                                  iconBgColor: palette.$2,
                                  iconColor: palette.$3,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 0),
    );
  }

  Widget _categoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String items,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsPage(
              categoryName: title,
              allProducts: products,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              items,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _allCategoriesCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsPage(
              categoryName: "All",
              allProducts: products,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF6A5AE0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A5AE0).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 28),
            ),
            const Spacer(),
            const Text(
              "All Categories",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "${products.length} items",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
