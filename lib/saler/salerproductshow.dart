import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/show_product_api.dart';
import '../services/product_api.dart';
import 'salerfirstpage.dart';
import '../topbotam/topbar.dart';
import '../topbotam/seller_bottombar.dart';
import '../widgets/ngrok_image.dart';

class SalerProductShow extends StatefulWidget {
  const SalerProductShow({super.key});

  @override
  State<SalerProductShow> createState() =>
      _SalerProductShowState();
}

class _SalerProductShowState
    extends State<SalerProductShow> {

  List<ProductModel> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    products = await ShowProductApi.getProducts();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      bottomNavigationBar: const SellerBottomBar(selectedIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TopBar(),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "My Products",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      // ── EMPTY STATE: show Add Product card prominently ──
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddProductScreen(),
                                    ),
                                  );
                                  loadProducts();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 30, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF6A5AE0)
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Color(0xFFF1EEFF),
                                        child: Icon(
                                          Icons.add,
                                          size: 40,
                                          color: Color(0xFF6A5AE0),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Add Product",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: Color(0xFF6A5AE0),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Tap to add your first product",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "No Products Found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      // ── HAS PRODUCTS: grid with Add card as first item ──
                      : GridView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: products.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            // ✅ ADD PRODUCT CARD (always first)
                            if (index == 0) {
                              return GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddProductScreen(),
                                    ),
                                  );
                                  loadProducts();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF6A5AE0)
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Color(0xFFF1EEFF),
                                        child: Icon(
                                          Icons.add,
                                          size: 35,
                                          color: Color(0xFF6A5AE0),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        "Add Product",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // ✅ PRODUCT ITEM
                            final product = products[index - 1];
                            List<String> imageUrls = product.allImageUrls;
                            if (imageUrls.isEmpty) {
                              final fallback =
                                  ProductApi.getImageUrl(product.rawJson);
                              if (fallback.isNotEmpty &&
                                  !fallback.contains('dummyimage.com')) {
                                imageUrls = [fallback];
                              }
                            }

                            return Container(
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
                                  // ✅ IMAGE
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
                                                  itemBuilder:
                                                      (context, imgIndex) {
                                                    return NgrokImage(
                                                      imageUrl: imageUrls[
                                                          imgIndex],
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
                                  // ✅ PRODUCT NAME
                                  Text(
                                    product.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // ✅ PRICE
                                  Text(
                                    "₹${product.price}",
                                    style: const TextStyle(
                                      color: Color(0xFF6A5AE0),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  // ✅ EDIT BUTTON
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1EEFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Color(0xFF6A5AE0),
                                      ),
                                    ),
                                  ),
                                ],
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