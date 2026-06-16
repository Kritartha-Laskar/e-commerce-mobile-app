import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEFF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF6A5AE0), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "3 new",
                  style: TextStyle(
                    color: Color(0xFF6A5AE0),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  const Text(
                    "Today",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _notificationItem(
                    icon: Icons.receipt_long_outlined,
                    iconBgColor: const Color(0xFF6A5AE0),
                    iconColor: Colors.white,
                    title: "Order Delivered!",
                    subtitle: "Your order #ORD-2024-009 has been delivered.",
                    time: "2 hours ago",
                    isNew: true,
                    titleColor: const Color(0xFF6A5AE0),
                  ),
                  _notificationItem(
                    icon: Icons.star_border,
                    iconBgColor: Colors.amber,
                    iconColor: Colors.black87,
                    title: "Flash Sale Live!",
                    subtitle: "50% off all footwear. Limited time!",
                    time: "5 hours ago",
                    isNew: true,
                    titleColor: const Color(0xFF6A5AE0),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Yesterday",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _notificationItem(
                    icon: Icons.check_circle_outline,
                    iconBgColor: Colors.green.shade50,
                    iconColor: Colors.green.shade600,
                    title: "Payment successful",
                    subtitle: "\$315 paid for order #ORD-2024-009.",
                    time: "1 day ago",
                    isNew: false,
                    titleColor: Colors.black87,
                  ),
                  _notificationItem(
                    icon: Icons.shopping_bag_outlined,
                    iconBgColor: Colors.pink.shade50,
                    iconColor: Colors.pink.shade400,
                    title: "Back in stock!",
                    subtitle: "Smart Watch X is available again.",
                    time: "1 day ago",
                    isNew: false,
                    titleColor: Colors.black87,
                  ),
            ],
          ),
        ),
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isNew,
    required Color titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFF1EEFF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isNew)
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: isNew ? const Color(0xFF8B80F8) : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF6A5AE0),
                shape: BoxShape.circle,
              ),
            )
        ],
      ),
    );
  }
}
