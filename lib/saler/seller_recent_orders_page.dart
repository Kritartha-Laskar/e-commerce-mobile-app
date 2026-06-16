import 'package:flutter/material.dart';
import '../services/seller_orders_api.dart';
import '../topbotam/seller_bottombar.dart';
import '../topbotam/topbar.dart';

class SellerRecentOrdersPage extends StatefulWidget {
  const SellerRecentOrdersPage({super.key});

  @override
  State<SellerRecentOrdersPage> createState() => _SellerRecentOrdersPageState();
}

class _SellerRecentOrdersPageState extends State<SellerRecentOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  // Track which order IDs are being confirmed/delivered
  Set<int> _confirmingIds = {};
  Set<int> _deliveringIds = {};

  Future<void> _deliverOrder(int orderId) async {
    setState(() => _deliveringIds.add(orderId));
    final success = await SellerOrdersApiService.deliverOrder(orderId);
    if (!mounted) return;
    setState(() => _deliveringIds.remove(orderId));
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order marked as delivered!"), backgroundColor: Colors.green),
      );
      _loadOrders(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mark order as delivered"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await SellerOrdersApiService.getRecentOrders();
    if (mounted) setState(() { _orders = orders; _isLoading = false; });
  }

  Future<void> _confirmOrder(int orderId) async {
    setState(() => _confirmingIds.add(orderId));
    final success = await SellerOrdersApiService.confirmOrder(orderId);
    if (!mounted) return;
    setState(() => _confirmingIds.remove(orderId));
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order confirmed!"), backgroundColor: Colors.green),
      );
      _loadOrders(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to confirm order"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      bottomNavigationBar: const SellerBottomBar(selectedIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TopBar(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Orders",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: _loadOrders,
                    child: const Icon(Icons.refresh, color: Color(0xFF6A5AE0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A5AE0)))
                  : _orders.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: const Color(0xFF6A5AE0),
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) =>
                                _buildOrderCard(_orders[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderId = order['id'] is int ? order['id'] as int : int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final status = order['status']?.toString() ?? 'Pending';
    final productName = order['product']?['product_name']?.toString() ??
        order['product_name']?.toString() ?? 'Product';
    final quantity = order['quantity']?.toString() ?? '1';
    
    // Calculate total price
    final priceStr = order['product']?['price']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;
    final qty = int.tryParse(quantity) ?? 1;
    final totalPrice = (price * qty) + 8.0; // Including standard delivery fee

    final address = order['delivery_address']?.toString() ?? '-';
    final phone = order['delivery_phone_no']?.toString() ?? '-';
    final paymentMode = order['payment_mode']?.toString() ?? 'COD';
    final isConfirming = _confirmingIds.contains(orderId);
    final isDelivering = _deliveringIds.contains(orderId);

    Color statusColor;
    IconData statusIcon;
    if (status.toLowerCase() == 'delivered') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.toLowerCase() == 'confirmed') {
      statusColor = const Color(0xFF4CAF50); // Lighter green/blue for confirmed
      statusIcon = Icons.check_circle_outline;
    } else if (status.toLowerCase() == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = const Color(0xFF6A5AE0);
      statusIcon = Icons.hourglass_empty_outlined;
    }

    final bool isPending = status.toLowerCase() == 'pending';
    final bool isConfirmed = status.toLowerCase() == 'confirmed';
    final bool isDelivered = status.toLowerCase() == 'delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #$orderId",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                          fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product
          _infoRow(Icons.shopping_bag_outlined, productName, bold: true, color: const Color(0xFF6A5AE0)),
          const SizedBox(height: 6),
          _infoRow(Icons.numbers, "Qty: $quantity"),
          const SizedBox(height: 4),
          _infoRow(Icons.currency_rupee, "Total Amount: ₹${totalPrice.toStringAsFixed(2)}", bold: true, color: const Color(0xFF6A5AE0)),
          const SizedBox(height: 4),
          _infoRow(Icons.phone_outlined, phone),
          const SizedBox(height: 4),
          _infoRow(Icons.location_on_outlined, address),
          const SizedBox(height: 4),
          _infoRow(Icons.payment_outlined, paymentMode),

          const SizedBox(height: 14),

          // Action Button
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isConfirming ? null : () => _confirmOrder(orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5AE0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: isConfirming
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm Order", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          else if (isConfirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDelivering ? null : () => _deliverOrder(orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: isDelivering
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Mark as Delivered", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          else if (isDelivered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Disabled / greyed out
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text("✓ Delivered", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool bold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey.shade600,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: Color(0xFF6A5AE0)),
          ),
          const SizedBox(height: 16),
          const Text("No recent orders",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("New orders will appear here",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
