import 'package:flutter/material.dart';
import 'product_details_page.dart';
import '../services/product_api.dart';
import '../widgets/ngrok_image.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;
  final List<dynamic> allProducts;

  const CategoryProductsPage({
    super.key,
    required this.categoryName,
    this.allProducts = const [],
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (widget.allProducts.isNotEmpty) {
      setState(() {
        products = _filterProducts(widget.allProducts);
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      final fetched = await ProductApi.getProducts();
      if (!mounted) return;
      setState(() {
        products = _filterProducts(fetched);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _filterProducts(List<dynamic> source) {
    if (widget.categoryName == "All" ||
        widget.categoryName == "All Categories") {
      return source;
    }

    final target = widget.categoryName.toLowerCase().trim();
    return source.where((p) {
      if (p is! Map) return false;
      final category = p['category'];
      if (category is Map) {
        final name = category['name']?.toString().toLowerCase().trim();
        if (name == target) return true;
      }
      return p['category_name']?.toString().toLowerCase().trim() == target;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName == "All"
        ? "All Products"
        : widget.categoryName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 20,
                left: 15,
                right: 15,
                bottom: 15,
              ),
              decoration: const BoxDecoration(color: Colors.white),
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
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "${products.length} items",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No products in $title",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final name =
                                product['product_name']?.toString() ??
                                    'No Name';
                            final price =
                                product['price']?.toString() ?? '0';
                            final brand =
                                product['category']?['name']?.toString() ??
                                    '';
                            final image = ProductApi.getImageUrl(product);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsPage(
                                      name: name,
                                      brand: brand,
                                      price: price,
                                      imageColor: Colors.grey,
                                      productId: int.tryParse(
                                            product['id']?.toString() ?? '0',
                                          ) ??
                                          0,
                                      imageUrl: image.contains('dummyimage.com')
                                          ? ''
                                          : image,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
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
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: Colors.grey.shade200,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: image.isNotEmpty &&
                                                  !image.contains(
                                                      'dummyimage.com')
                                              ? NgrokImage(
                                                  imageUrl: image,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                )
                                              : const Center(
                                                  child: Icon(Icons.image),
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (brand.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        brand,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹$price",
                                          style: const TextStyle(
                                            color: Color(0xFF6A5AE0),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF6A5AE0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
