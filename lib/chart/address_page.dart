import 'package:flutter/material.dart';
import 'dart:ui';
import 'checkout_page.dart';
import '../profile/profile_page.dart';
import '../services/user_information.dart';
import '../profile/user_information.dart' as address_form;

class AddressPage extends StatefulWidget {
  final bool fromProfile;
  final bool isBuyNow;
  final int? buyNowProductId;
  final String? buyNowProductName;
  final double? buyNowPrice;
  final int? buyNowQuantity;

  const AddressPage({
    super.key, 
    this.fromProfile = false,
    this.isBuyNow = false,
    this.buyNowProductId,
    this.buyNowProductName,
    this.buyNowPrice,
    this.buyNowQuantity,
  });

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  bool _hasError = false;
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final addresses = await UserInformationService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
          // Auto-select first address
          if (_addresses.isNotEmpty) {
            _selectedAddressId = _addresses[0]['id'];
          }
        });
      }
    } catch (e) {
      print('ADDRESS LOAD ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _deleteAddress(int index) async {
    final item = _addresses[index];
    final int id = item['id'];

    // Optimistic removal
    setState(() => _addresses.removeAt(index));

    final success = await UserInformationService.deleteAddress(id);
    if (!success && mounted) {
      setState(() => _addresses.insert(index, item));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete address. Try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
  String _addressText(dynamic addr) {
    final parts = <String>[];
    if (addr['address_line'] != null) parts.add(addr['address_line'].toString());
    if (addr['city'] != null) parts.add(addr['city'].toString());
    if (addr['state'] != null) parts.add(addr['state'].toString());
    if (addr['pincode'] != null) parts.add(addr['pincode'].toString());
    if (addr['country'] != null) parts.add(addr['country'].toString());
    return parts.join(', ');
  }

  String _addressType(dynamic addr, int index) {
    // Try to get a type label from the data, else use index-based label
    if (addr['type'] != null) return addr['type'].toString();
    if (addr['label'] != null) return addr['label'].toString();
    return index == 0 ? 'Home' : 'Address ${index + 1}';
  }

  String _addressName(dynamic addr) {
    if (addr['user'] != null && addr['user']['name'] != null) {
      return addr['user']['name'].toString();
    }
    return addr['name']?.toString() ?? 'User';
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
          child: Column(
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.only(
                    top: 40, left: 20, right: 20, bottom: 20),
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
                      "My Addresses",
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6A5AE0),
                        ),
                      )
                    : _hasError
                        ? _buildError()
                        : RefreshIndicator(
                            color: const Color(0xFF6A5AE0),
                            onRefresh: _loadAddresses,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Address cards from API
                                  if (_addresses.isEmpty)
                                    _buildEmpty()
                                  else
                                    ...List.generate(_addresses.length, (index) {
                                      final addr = _addresses[index];
                                      final int addrId = addr['id'];
                                      final bool isSelected =
                                          _selectedAddressId == addrId;
                                      return _addressCard(
                                        index: index,
                                        addr: addr,
                                        isSelected: isSelected,
                                        onTap: () {
                                          setState(() {
                                            _selectedAddressId = addrId;
                                          });
                                        },
                                        onDelete: () => _deleteAddress(index),
                                      );
                                    }),

                                  const SizedBox(height: 10),

                                  // Add New Address
                                  _addNewAddressButton(),

                                  const SizedBox(height: 30),

                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _addresses.isEmpty
                                          ? null
                                          : () {
                                              if (widget.fromProfile) {
                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const ProfilePage()),
                                                  (route) => false,
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) => CheckoutPage(
                                                        isBuyNow: widget.isBuyNow,
                                                        buyNowProductId: widget.buyNowProductId,
                                                        buyNowProductName: widget.buyNowProductName,
                                                        buyNowPrice: widget.buyNowPrice,
                                                        buyNowQuantity: widget.buyNowQuantity,
                                                      )),
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6A5AE0),
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        "Continue",
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ADDRESS CARD ─────────────────────────────────────────────────────────
  Widget _addressCard({
    required int index,
    required dynamic addr,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final type = _addressType(addr, index);
    final name = _addressName(addr);
    final addressText = _addressText(addr);
    final bool isFirst = index == 0;

    // Badge colours
    final Color badgeBg =
        isFirst ? const Color(0xFFF1EEFF) : const Color(0xFFFDF0D5);
    final Color badgeText =
        isFirst ? const Color(0xFF6A5AE0) : const Color(0xFF9E651D);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF6A5AE0), width: 2)
              : null,
          boxShadow: isSelected
              ? []
              : [
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
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: const Text(
                        "Select",
                        style: TextStyle(
                          color: Color(0xFF6A5AE0),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (index != 0) ...[
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Address details
            Text(
              addressText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            // Selected indicator
            if (isSelected) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6A5AE0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Selected address",
                    style: TextStyle(
                      color: Color(0xFF6A5AE0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_outlined,
                size: 50, color: Color(0xFF6A5AE0)),
          ),
          const SizedBox(height: 20),
          const Text(
            "No addresses found",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a delivery address to continue",
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
          const Text("Failed to load addresses",
              style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadAddresses,
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

  // ─── ADD NEW BUTTON ───────────────────────────────────────────────────────
  Widget _addNewAddressButton() {
    return GestureDetector(
      onTap: () async {
        // Navigate to AddressFormScreen and reload addresses when done
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const address_form.AddressFormScreen(),
          ),
        );
        // Reload after returning (whether saved or cancelled)
        _loadAddresses();
      },
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFFB8AEFB),
          strokeWidth: 1.5,
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF6A5AE0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Add New Address",
                style: TextStyle(
                  color: Color(0xFF6A5AE0),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
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
