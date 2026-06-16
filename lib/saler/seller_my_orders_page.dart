import 'package:flutter/material.dart';
import '../services/seller_orders_api.dart';
import '../topbotam/seller_bottombar.dart';
import '../topbotam/topbar.dart';

class SellerMyOrdersPage extends StatefulWidget {
  const SellerMyOrdersPage({super.key});

  @override
  State<SellerMyOrdersPage> createState() => _SellerMyOrdersPageState();
}

class _SellerMyOrdersPageState extends State<SellerMyOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
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
    final orders = await SellerOrdersApiService.getMyOrders();
    if (mounted) setState(() { _orders = orders; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      bottomNavigationBar: const SellerBottomBar(selectedIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
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
                    "My Orders",
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
    final orderId = order['id']?.toString() ?? '-';
    final status = order['status']?.toString() ?? 'Confirmed';
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
    
    final orderIdInt = order['id'] is int ? order['id'] as int : int.tryParse(order['id']?.toString() ?? '0') ?? 0;
    final isDelivering = _deliveringIds.contains(orderIdInt);
    final isDelivered = status.toLowerCase() == 'delivered';

    Color statusColor;
    IconData statusIcon;
    if (status.toLowerCase() == 'delivered') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.toLowerCase() == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (status.toLowerCase() == 'confirmed') {
      statusColor = const Color(0xFF6A5AE0);
      statusIcon = Icons.verified_outlined;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.local_shipping_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Divider(height: 20),
          _row(Icons.shopping_bag_outlined, productName,
              bold: true, color: const Color(0xFF6A5AE0)),
          const SizedBox(height: 5),
          _row(Icons.numbers, "Quantity: $quantity"),
          const SizedBox(height: 4),
          _row(Icons.currency_rupee, "Total Amount: ₹${totalPrice.toStringAsFixed(2)}", bold: true, color: const Color(0xFF6A5AE0)),
          const SizedBox(height: 4),
          _row(Icons.phone_outlined, phone),
          const SizedBox(height: 4),
          _row(Icons.location_on_outlined, address),
          const SizedBox(height: 4),
          _row(Icons.payment_outlined, paymentMode),

          const SizedBox(height: 14),

          // Action Button
          if (isDelivered)
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
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isDelivering ? null : () => _deliverOrder(orderIdInt),
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
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool bold = false, Color? color}) {
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
            child: const Icon(Icons.inventory_2_outlined,
                size: 48, color: Color(0xFF6A5AE0)),
          ),
          const SizedBox(height: 16),
          const Text("No orders yet",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("Your confirmed & delivered orders will appear here",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
