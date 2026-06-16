import 'package:flutter/material.dart';
import '../services/orde_api.dart';
import '../services/product_api.dart';
import '../widgets/ngrok_image.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await OrderApiService.getMyOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredOrders {
    if (_selectedTab == 'All') return _orders;

    return _orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      final hasDelivery = order['delivery_date'] != null;

      switch (_selectedTab) {
        case 'Active':
          return (status == 'pending' || status == 'confirmed') && !hasDelivery;
        case 'Completed':
          // Match any variation of delivered/completed status
          return hasDelivery ||
              status == 'delivered' ||
              status == 'completed' ||
              status == 'deliver' ||
              status.contains('deliver');
        case 'Cancelled':
          return status == 'cancelled' || status == 'canceled';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text(
                      "My Orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadOrders,
                    icon: const Icon(Icons.refresh, color: Color(0xFF6A5AE0)),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tabItem('All'),
                      _tabItem('Active'),
                      _tabItem('Completed'),
                      _tabItem('Cancelled'),
                    ],
                  ),
                  Container(height: 1, color: Colors.grey.shade200),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6A5AE0),
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          color: const Color(0xFF6A5AE0),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              return _orderCard(_filteredOrders[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 'All'
                ? 'No orders yet'
                : 'No $_selectedTab orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String title) {
    final isActive = _selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF6A5AE0) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF6A5AE0) : Colors.grey.shade400,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final orderId = order['id']?.toString() ?? '-';
    final status = order['status']?.toString() ?? 'pending';
    final product = order['product'];
    final productName = product is Map
        ? product['product_name']?.toString() ?? 'Product'
        : 'Product';
    final quantity = order['quantity']?.toString() ?? '1';
    final totalPrice = order['total_price']?.toString() ??
        order['price']?.toString() ??
        '0';
    final address = order['delivery_address']?.toString() ?? '-';
    final phone = order['delivery_phone_no']?.toString() ?? '-';
    final paymentMode = order['payment_mode']?.toString() ?? 'COD';
    final orderDate = _formatDate(
      order['order_date']?.toString() ?? order['created_at']?.toString(),
    );
    final imageUrl = product is Map ? ProductApi.getImageUrl(product) : '';

    final statusStyle = _statusStyle(status, order);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusStyle.$2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusStyle.$1,
                  style: TextStyle(
                    color: statusStyle.$3,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty &&
                          !imageUrl.contains('dummyimage.com')
                      ? NgrokImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$totalPrice',
                      style: const TextStyle(
                        color: Color(0xFF6A5AE0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _detailRow(Icons.calendar_today_outlined, orderDate),
          const SizedBox(height: 8),
          _detailRow(Icons.location_on_outlined, address),
          const SizedBox(height: 8),
          _detailRow(Icons.phone_outlined, phone),
          const SizedBox(height: 8),
          _detailRow(Icons.payment_outlined, paymentMode),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  (String, Color, Color) _statusStyle(String status, dynamic order) {
    final s = status.toLowerCase();
    if (order['delivery_date'] != null || s.contains('deliver') || s == 'completed') {
      return ('Delivered', const Color(0xFFE8F5E9), const Color(0xFF4C8C2A));
    }
    switch (s) {
      case 'confirmed':
        return ('Confirmed', const Color(0xFFFBE9D7), const Color(0xFFD98836));
      case 'cancelled':
      case 'canceled':
        return ('Cancelled', const Color(0xFFFFEBEE), Colors.redAccent);
      default:
        return ('Processing', const Color(0xFFEBF5FB), const Color(0xFF2E86C1));
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
