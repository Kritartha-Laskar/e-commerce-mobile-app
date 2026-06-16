import 'package:flutter/material.dart';
import '../frontpage/product_details_page.dart';
import '../services/product_api.dart';
import '../widgets/ngrok_image.dart';

class FilterCategoryPage extends StatelessWidget {
  final String categoryName;
  final List allProducts;

  const FilterCategoryPage({
    super.key,
    required this.categoryName,
    required this.allProducts,
  });

  @override
  Widget build(BuildContext context) {
    // Filter the products based on the category name
    final filteredProducts = categoryName == "All"
        ? allProducts
        : allProducts.where((p) {
            String? catName = p['category']?['name']?.toString();
            return catName != null && catName.toLowerCase() == categoryName.toLowerCase();
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  Text(
                    "No products found in $categoryName",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Adjust this ratio to fit your images properly
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                String name = product['product_name']?.toString() ?? 'No Name';
                String price = product['price']?.toString() ?? '0';
                String image = ProductApi.getImageUrl(product);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(
                          name: name,
                          brand: product['category']?['name']?.toString() ?? "",
                          price: price,
                          imageColor: Colors.grey,
                          productId: int.tryParse(product['id']?.toString() ?? '0') ?? 0,
                          imageUrl: image.contains('dummyimage.com') ? '' : image,
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
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey.shade200,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: image.isNotEmpty
                                  ? NgrokImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // NAME
                        Text(
                          name, 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // PRICE
                        Text(
                          "₹$price",
                          style: const TextStyle(
                            color: Color(0xFF6A5AE0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
