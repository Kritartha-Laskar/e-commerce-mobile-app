import 'package:flutter/material.dart';
import 'address_page.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';
import '../services/my_cartapi.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Track pending quantity-update calls per cart item id
  final Set<int> _updatingIds = {};

  static const double _deliveryFee = 8.0;
  static const double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ─── LOAD ─────────────────────────────────────────────────────────────────
  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final items = await MyCartApiService.getCartItems();
      if (mounted) {
        setState(() {
          _cartItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('CART LOAD ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // ─── COMPUTED TOTALS ──────────────────────────────────────────────────────
  double get _subtotal {
    double total = 0;
    for (final item in _cartItems) {
      final price = double.tryParse(
              item['product']?['price']?.toString() ?? '0') ??
          0;
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      total += price * qty;
    }
    return total;
  }

  double get _total => _subtotal + _deliveryFee - _discount;

  // ─── UPDATE QUANTITY ──────────────────────────────────────────────────────
  Future<void> _changeQty(int cartItemIndex, int delta) async {
    final item = _cartItems[cartItemIndex];
    final int cartId = item['id'];
    final int currentQty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final int newQty = currentQty + delta;

    if (newQty < 1) {
      _deleteItem(cartItemIndex);
      return;
    }

    if (_updatingIds.contains(cartId)) return;
    setState(() => _updatingIds.add(cartId));

    // Optimistic local update
    setState(() {
      _cartItems[cartItemIndex]['quantity'] = newQty;
    });

    final result = await MyCartApiService.updateCartItem(
      cartId: cartId,
      quantity: newQty,
    );

    if (mounted) {
      setState(() => _updatingIds.remove(cartId));
      if (result['success'] != true) {
        // Revert on failure
        setState(() {
          _cartItems[cartItemIndex]['quantity'] = currentQty;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Update failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── DELETE ITEM ──────────────────────────────────────────────────────────
  Future<void> _deleteItem(int index) async {
    final item = _cartItems[index];
    final int cartId = item['id'];

    // Optimistic removal
    setState(() => _cartItems.removeAt(index));

    final success = await MyCartApiService.deleteCartItem(cartId);
    if (!success && mounted) {
      // Re-insert on failure
      setState(() => _cartItems.insert(index, item));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove item. Try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  String _productName(dynamic item) =>
      item['product']?['product_name']?.toString() ?? 'Product';

  String _productPrice(dynamic item) =>
      item['product']?['price']?.toString() ?? '0';

  int _itemQty(dynamic item) =>
      int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

  double _itemTotal(dynamic item) {
    final price = double.tryParse(_productPrice(item)) ?? 0;
    return price * _itemQty(item);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: Color(0xFFF8F8FB)),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // ── TopBar ──
                const Padding(
                  padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: TopBar(),
                ),

                // ── Header ──
                Container(
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 20),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Cart",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6A5AE0),
                          ),
                        )
                      : _hasError
                          ? _buildError()
                          : _cartItems.isEmpty
                              ? _buildEmpty()
                              : RefreshIndicator(
                                  color: const Color(0xFF6A5AE0),
                                  onRefresh: _loadCart,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: _cartItems.length,
                                    itemBuilder: (context, index) {
                                      return _buildCartCard(index);
                                    },
                                  ),
                                ),
                ),

                // ── Summary ──
                if (!_isLoading && !_hasError && _cartItems.isNotEmpty)
                  _buildSummary(),
              ],
            ),
            bottomNavigationBar: const CustomBottomBar(selectedIndex: 2),
          ),
        ),
      ),
    );
  }

  // ─── CART ITEM CARD ───────────────────────────────────────────────────────
  Widget _buildCartCard(int index) {
    final item = _cartItems[index];
    final int cartId = item['id'];
    final bool isUpdating = _updatingIds.contains(cartId);

    return Dismissible(
      key: Key('cart_$cartId'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteItem(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product colour block (placeholder)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE8FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF6A5AE0), size: 32),
            ),
            const SizedBox(width: 15),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    _productName(item),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Price per unit
                  Text(
                    "₹${_productPrice(item)} each",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Item total
                      Text(
                        "₹${_itemTotal(item).toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFF6A5AE0),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      // Qty controls
                      isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6A5AE0),
                              ),
                            )
                          : Row(
                              children: [
                                _qtyButton(
                                  icon: Icons.remove,
                                  onTap: () => _changeQty(index, -1),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _itemQty(item).toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _qtyButton(
                                  icon: Icons.add,
                                  onTap: () => _changeQty(index, 1),
                                ),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHECKOUT SUMMARY ─────────────────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow("Subtotal", "₹${_subtotal.toStringAsFixed(2)}",
              Colors.grey, Colors.grey),
          const SizedBox(height: 8),
          _summaryRow("Delivery", "₹${_deliveryFee.toStringAsFixed(2)}",
              Colors.grey, Colors.grey),
          const SizedBox(height: 8),
          _summaryRow("Discount", "-₹${_discount.toStringAsFixed(2)}",
              const Color(0xFF4C8C2A), const Color(0xFF4C8C2A)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEAE8FA), thickness: 1.5),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressPage()),
              );
            },
            child: _summaryRow(
              "Total",
              "₹${_total.toStringAsFixed(2)}",
              Colors.black87,
              const Color(0xFF6A5AE0),
              isBold: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                "Proceed to Checkout  ₹${_total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Color(0xFF6A5AE0),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items from the shop to get started",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── ERROR STATE ──────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Failed to load cart",
              style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5AE0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── SMALL WIDGETS ────────────────────────────────────────────────────────
  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFF1EEFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF6A5AE0), size: 16),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 13,
          ),
        ),
      ],
    );
  }
}
