import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chart/cart_page.dart';
import '../chart/address_page.dart';
import '../services/my_cartapi.dart';
import '../services/wishlist_service.dart';
import '../widgets/ngrok_image.dart';
import '../topbotam/bottombar.dart';
import '../topbotam/seller_bottombar.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String brand;
  final String price;
  final Color imageColor;
  final int productId;
  final String imageUrl;

  const ProductDetailsPage({
    super.key,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageColor,
    this.productId = 0,
    this.imageUrl = '',
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int selectedSize = 40;
  bool _isAddingToCart = false;
  bool _isWishlisted = false;
  bool _wishlistLoading = true;
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadWishlistState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userType = prefs.getString('user_type') ?? '';
      });
    }
  }

  Future<void> _loadWishlistState() async {
    if (widget.productId <= 0) {
      setState(() => _wishlistLoading = false);
      return;
    }
    final saved = await WishlistService.isInWishlist(widget.productId);
    if (mounted) {
      setState(() {
        _isWishlisted = saved;
        _wishlistLoading = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (widget.productId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save this product to wishlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('user_id') == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save to wishlist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final added = await WishlistService.toggleItem(
      WishlistItem(
        productId: widget.productId,
        productName: widget.name,
        brand: widget.brand,
        price: widget.price,
        imageUrl: widget.imageUrl,
      ),
    );

    if (!mounted) return;

    setState(() => _isWishlisted = added);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'Added to wishlist' : 'Removed from wishlist',
        ),
        backgroundColor: const Color(0xFF6A5AE0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── ADD TO CART ──────────────────────────────────────────────────────────
  Future<void> _addToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      // Read saved user_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to add items to cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (widget.productId == 0) {
        // Demo / static card — no real product ID
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Added to cart!'),
              backgroundColor: const Color(0xFF6A5AE0),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const CartPage()),
          // );
        }
        return;
      }

      final result = await MyCartApiService.addToCart(
        userId: userId,
        productId: widget.productId,
        quantity: 1,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Added to cart!'),
            backgroundColor: const Color(0xFF6A5AE0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Navigate to cart page
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const CartPage()),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add to cart'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
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
          decoration: BoxDecoration(
            color: widget.imageColor,
          ),
          child: Column(
            children: [
              // 🔵 Top Image Section
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF6A5AE0),
                              size: 24,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                _wishlistLoading ? null : _toggleWishlist,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isWishlisted
                                    ? Colors.redAccent
                                    : const Color(0xFF6A5AE0),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    widget.imageUrl.isNotEmpty
                        ? Positioned.fill(
                            child: NgrokImage(
                              imageUrl: widget.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A5AE0).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6A5AE0)
                                        .withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6A5AE0),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                    // Pagination Dots
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A5AE0),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔽 Bottom Details Section
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand Name
                        Text(
                          widget.brand,
                          style: const TextStyle(
                            color: Color(0xFF6A5AE0),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Product Name
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price and Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "₹${widget.price}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A5AE0),
                              ),
                            ),
                            // Row(
                            //   children: [
                            //     const Icon(Icons.star, color: Colors.amber, size: 16),
                            //     const Icon(Icons.star, color: Colors.amber, size: 16),
                            //     const Icon(Icons.star, color: Colors.amber, size: 16),
                            //     const Icon(Icons.star, color: Colors.amber, size: 16),
                            //     const Icon(Icons.star, color: Colors.amber, size: 16),
                            //     const SizedBox(width: 5),
                            //     Text(
                            //       "4.9 (2.3k)",
                            //       style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // // Select Size
                        // const Text(
                        //   "Select Size",
                        //   style: TextStyle(
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.black87,
                        //   ),
                        // ),
                        // const SizedBox(height: 10),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     _sizeCircle(38),
                        //     _sizeCircle(39),
                        //     _sizeCircle(40),
                        //     _sizeCircle(41),
                        //     _sizeCircle(42),
                        //   ],
                        // ),
                        // const SizedBox(height: 20),

                        // Description
                        Text(
                          "Lightweight, breathable upper with responsive foam sole. Built for speed and all-day comfort.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Action Buttons ───────────────────────────────
                        Row(
                          children: [
                            // Add to Cart Icon Button
                            GestureDetector(
                              onTap: _isAddingToCart ? null : _addToCart,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _isAddingToCart
                                      ? const Color(0xFF6A5AE0).withOpacity(0.15)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: const Color(0xFF6A5AE0), width: 2),
                                  boxShadow: _isAddingToCart
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF6A5AE0)
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: _isAddingToCart
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF6A5AE0),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Color(0xFF6A5AE0),
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Buy Now Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddressPage(
                                        isBuyNow: true,
                                        buyNowProductId: widget.productId,
                                        buyNowProductName: widget.name,
                                        buyNowPrice: double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
                                        buyNowQuantity: 1, // Default to 1, or add a quantity selector later
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A5AE0),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Buy Now",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                       ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _userType == 'seller'
          ? const SellerBottomBar(selectedIndex: 0)
          : const CustomBottomBar(selectedIndex: 0),
    );
  }

  Widget _sizeCircle(int size) {
    bool isSelected = selectedSize == size;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1EEFF) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            size.toString(),
            style: TextStyle(
              color: isSelected ? const Color(0xFF6A5AE0) : Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
