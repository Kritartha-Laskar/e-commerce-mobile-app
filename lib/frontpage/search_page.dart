import 'package:flutter/material.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TopBar(),
            ),
            const SizedBox(height: 10),
            // 🔵 Top Search Bar Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF6A5AE0), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF6A5AE0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: "running shoes"),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Searches
                    const Text(
                      "Recent searches",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _searchChip("air max"),
                        _searchChip("leather bag"),
                        _searchChip("smartwatch"),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Results
                    const Text(
                      "Results (32)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Product List
                    _searchResultCard(
                      name: "Air Runner Pro",
                      price: "\$129",
                      imageColor: const Color(0xFFEAE8FA),
                      stockStatus: "In stock",
                      statusBgColor: const Color(0xFFE5F1D5),
                      statusTextColor: const Color(0xFF4C8C2A),
                    ),
                    _searchResultCard(
                      name: "Cloud Stride",
                      price: "\$165",
                      imageColor: const Color(0xFFE5F1D5),
                      stockStatus: "In stock",
                      statusBgColor: const Color(0xFFE5F1D5),
                      statusTextColor: const Color(0xFF4C8C2A),
                    ),
                    _searchResultCard(
                      name: "Flex Max 2.0",
                      price: "\$95",
                      imageColor: const Color(0xFFFAE0E4),
                      stockStatus: "Low stock",
                      statusBgColor: const Color(0xFFFAE0E4),
                      statusTextColor: const Color(0xFFB5445A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 1),
    );
  }

  Widget _searchChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE8FA), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6A5AE0),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _searchResultCard({
    required String name,
    required String price,
    required Color imageColor,
    required String stockStatus,
    required Color statusBgColor,
    required Color statusTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
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
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: imageColor,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF6A5AE0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              stockStatus,
              style: TextStyle(
                color: statusTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
