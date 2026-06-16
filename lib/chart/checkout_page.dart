import 'package:flutter/material.dart';
import 'dart:ui';
import 'payment_page.dart';
import 'address_page.dart';
import '../services/user_information.dart';
import '../services/my_cartapi.dart';
import '../profile/user_information.dart' as address_form;

class CheckoutPage extends StatefulWidget {
  final bool isBuyNow;
  final int? buyNowProductId;
  final String? buyNowProductName;
  final double? buyNowPrice;
  final int? buyNowQuantity;

  const CheckoutPage({
    super.key,
    this.isBuyNow = false,
    this.buyNowProductId,
    this.buyNowProductName,
    this.buyNowPrice,
    this.buyNowQuantity,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // ── Address state ──
  List<dynamic> _addresses = [];
  bool _addressLoading = true;
  int? _selectedAddressId;

  // ── Cart state ──
  List<dynamic> _cartItems = [];
  bool _cartLoading = true;
  int _buyNowQty = 1;

  static const double _deliveryFee = 8.0;

  @override
  void initState() {
    super.initState();
    if (widget.isBuyNow) {
      _buyNowQty = widget.buyNowQuantity ?? 1;
    }
    _loadData();
  }

  Future<void> _updateCartQuantity(int cartId, int currentQty, int delta) async {
    final newQty = currentQty + delta;
    if (newQty < 1) return;
    
    // Optimistic update
    setState(() {
      final index = _cartItems.indexWhere((item) => item['id'] == cartId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQty;
      }
    });

    final res = await MyCartApiService.updateCartItem(cartId: cartId, quantity: newQty);
    if (res['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to update quantity')),
        );
      }
    }
    _loadCart();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadAddresses(), _loadCart()]);
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await UserInformationService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _addressLoading = false;
          if (_addresses.isNotEmpty) {
            _selectedAddressId = _addresses[0]['id'];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _addressLoading = false);
    }
  }

  Future<void> _loadCart() async {
    if (widget.isBuyNow) {
      if (mounted) {
        setState(() {
          _cartLoading = false;
        });
      }
      return;
    }
    
    try {
      final items = await MyCartApiService.getCartItems();
      if (mounted) {
        setState(() {
          _cartItems = items;
          _cartLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cartLoading = false);
    }
  }

  // ── Computed totals ──
  double get _subtotal {
    if (widget.isBuyNow) {
      return (widget.buyNowPrice ?? 0) * _buyNowQty;
    }
    double total = 0;
    for (final item in _cartItems) {
      final price =
          double.tryParse(item['product']?['price']?.toString() ?? '0') ?? 0;
      final qty =
          int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      total += price * qty;
    }
    return total;
  }

  double get _total => _subtotal + _deliveryFee;

  // ── Address helpers ──
  String _addressText(dynamic addr) {
    final parts = <String>[];
    if (addr['address_line'] != null) parts.add(addr['address_line'].toString());
    if (addr['city'] != null) parts.add(addr['city'].toString());
    if (addr['state'] != null) parts.add(addr['state'].toString());
    if (addr['pincode'] != null) parts.add(addr['pincode'].toString());
    if (addr['country'] != null) parts.add(addr['country'].toString());
    return parts.join(', ');
  }

  String _addressName(dynamic addr) {
    if (addr['user'] != null && addr['user']['name'] != null) {
      return addr['user']['name'].toString();
    }
    return addr['name']?.toString() ?? 'User';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF6A5AE0), size: 20),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Checkout",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Stepper
                    _buildStepper(),
                    const SizedBox(height: 30),

                    // ── Addresses ──
                    _addressLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF6A5AE0)))
                        : _addresses.isEmpty
                            ? _buildNoAddress()
                            : Column(
                                children: _addresses
                                    .asMap()
                                    .entries
                                    .map((e) => _addressCard(
                                          index: e.key,
                                          addr: e.value,
                                        ))
                                    .toList(),
                                ),

                    const SizedBox(height: 15),

                    // Add new address
                    _addNewAddressButton(),
                    const SizedBox(height: 25),

                    // ── Order Summary ──
                    _cartLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF6A5AE0)))
                        : _orderSummary(),

                    const SizedBox(height: 25),

                    // ── Continue Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addresses.isEmpty
                            ? null
                            : () {
                                final selectedAddr = _addresses.firstWhere(
                                    (addr) => addr['id'] == _selectedAddressId,
                                    orElse: () => _addresses.first);
                                final addrText = _addressText(selectedAddr);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PaymentPage(
                                        productId: widget.isBuyNow ? widget.buyNowProductId : null,
                                        quantity: widget.isBuyNow ? _buyNowQty : null,
                                        deliveryAddress: addrText,
                                        totalAmount: _total,
                                      )),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A5AE0),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Continue to Payment",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEPPER ───────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(isActive: true, isCompleted: true, label: "Address", number: "1"),
        _stepLine(isActive: true),
        _stepCircle(isActive: true, isCompleted: false, label: "Payment", number: "2"),
        _stepLine(isActive: false),
        _stepCircle(isActive: false, isCompleted: false, label: "Confirm", number: "3"),
      ],
    );
  }

  Widget _stepCircle({
    required bool isActive,
    required bool isCompleted,
    required String label,
    required String number,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF6A5AE0)
                : const Color(0xFFEAE8FA),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    number,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF6A5AE0) : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _stepLine({required bool isActive}) {
    return Container(
      width: 40,
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? const Color(0xFF6A5AE0) : const Color(0xFFEAE8FA),
    );
  }

  // ── ADDRESS CARD ──────────────────────────────────────────────────────────
  Widget _addressCard({required int index, required dynamic addr}) {
    final int addrId = addr['id'];
    final bool isSelected = _selectedAddressId == addrId;
    final String name = _addressName(addr);
    final String addressText = _addressText(addr);
    final String type = addr['type']?.toString() ??
        addr['label']?.toString() ??
        (index == 0 ? 'Home' : 'Address ${index + 1}');

    final Color badgeBg =
        index == 0 ? const Color(0xFFF1EEFF) : const Color(0xFFFDF0D5);
    final Color badgeText =
        index == 0 ? const Color(0xFF6A5AE0) : const Color(0xFF9E651D);

    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addrId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF6A5AE0), width: 2)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              addressText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6A5AE0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Deliver here",
                    style: TextStyle(
                      color: Color(0xFF6A5AE0),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── NO ADDRESS STATE ──────────────────────────────────────────────────────
  Widget _buildNoAddress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined,
              size: 40, color: Color(0xFF6A5AE0)),
          const SizedBox(height: 10),
          const Text("No address found",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text("Please add a delivery address",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  // ── ADD NEW ADDRESS ───────────────────────────────────────────────────────
  Widget _addNewAddressButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const address_form.AddressFormScreen(),
          ),
        );
        _loadAddresses();
      },
      child: CustomPaint(
        painter: DashedBorderPainter(
            color: const Color(0xFFB8AEFB), strokeWidth: 1.5, radius: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF6A5AE0)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add,
                    color: Color(0xFF6A5AE0), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                "Add new address",
                style: TextStyle(
                  color: Color(0xFF6A5AE0),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ORDER SUMMARY ─────────────────────────────────────────────────────────
  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order summary",
            style: TextStyle(
              color: Color(0xFF3B2E92),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 15),

          // Items
          if (widget.isBuyNow)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.buyNowProductName ?? 'Product',
                      style: const TextStyle(
                          color: Color(0xFF6A5AE0), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_buyNowQty > 1) {
                            setState(() => _buyNowQty--);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A5AE0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove, size: 16, color: Color(0xFF6A5AE0)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text("$_buyNowQty", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A5AE0))),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _buyNowQty++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A5AE0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: Color(0xFF6A5AE0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "₹${((widget.buyNowPrice ?? 0) * _buyNowQty).toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Color(0xFF6A5AE0), fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ..._cartItems.map((item) {
              final name =
                  item['product']?['product_name']?.toString() ?? 'Product';
              final price =
                  double.tryParse(item['product']?['price']?.toString() ?? '0') ?? 0;
              final qty =
                  int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
              final lineTotal = price * qty;
              final cartId = item['id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: Color(0xFF6A5AE0), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _updateCartQuantity(cartId, qty, -1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A5AE0).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 16, color: Color(0xFF6A5AE0)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A5AE0))),
                        ),
                        GestureDetector(
                          onTap: () => _updateCartQuantity(cartId, qty, 1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A5AE0).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 16, color: Color(0xFF6A5AE0)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${lineTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Color(0xFF6A5AE0), fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),

          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Delivery",
                  style:
                      TextStyle(color: Color(0xFF6A5AE0), fontSize: 13)),
              Text("₹${_deliveryFee.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Color(0xFF6A5AE0), fontSize: 13)),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFB8AEFB), thickness: 1),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  color: Color(0xFF3B2E92),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "₹${_total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Color(0xFF3B2E92),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── DASHED BORDER PAINTER ────────────────────────────────────────────────────
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rRect);

    const double dashWidth = 8.0;
    const double dashSpace = 8.0;

    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
