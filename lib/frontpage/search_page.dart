import 'package:flutter/material.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';
import '../services/product_api.dart';
import '../frontpage/product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductApi.getStorefrontProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredProducts = []);
      return;
    }
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] ?? product['product_name'] ?? '')
            .toString()
            .toLowerCase();
        final category =
            (product['category']?['name'] ?? product['category_name'] ?? '')
                .toString()
                .toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _filteredProducts = []);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ──
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20),
              child: TopBar(),
            ),
            const SizedBox(height: 10),

            // ── Search Input ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: const Color(0xFF6A5AE0), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF6A5AE0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
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
                      ),
                  ],
                ),
              ),
            ),

            // ── Body ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6A5AE0)),
                    )
                  : query.isEmpty
                      ? _buildEmptyPrompt()
                      : _filteredProducts.isEmpty
                          ? _buildNoResults(query)
                          : _buildResults(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(selectedIndex: 1),
    );
  }

  // ── Prompt: type to search ────────────────────────────────────────────────
  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search,
                size: 52, color: Color(0xFF6A5AE0)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Search for products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a product name or category above',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── No results ────────────────────────────────────────────────────────────
  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFFAE0E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off,
                size: 52, color: Color(0xFFB5445A)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No products matched "$query"',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Results list ──────────────────────────────────────────────────────────
  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'Results (${_filteredProducts.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final imageUrl = ProductApi.getImageUrl(product);
              final name =
                  product['name'] ?? product['product_name'] ?? 'Product';
              final price = product['price']?.toString() ?? '0';
              final inStock = product['status'] != 'out_of_stock' &&
                  product['quantity'] != 0;

              return GestureDetector(
                onTap: () {
                  final int pId = product['id'] is int
                      ? product['id'] as int
                      : int.tryParse(product['id']?.toString() ?? '') ?? 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(
                        name: (product['name'] ?? product['product_name'] ?? 'Product').toString(),
                        brand: (product['brand'] ?? product['category']?['name'] ?? '').toString(),
                        price: (product['price'] ?? '0').toString(),
                        imageColor: const Color(0xFFF1EEFF),
                        productId: pId,
                        imageUrl: ProductApi.getImageUrl(product),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Product image / placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '₹$price',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: inStock
                              ? const Color(0xFFE5F1D5)
                              : const Color(0xFFFAE0E4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          inStock ? 'In stock' : 'Out of stock',
                          style: TextStyle(
                            color: inStock
                                ? const Color(0xFF4C8C2A)
                                : const Color(0xFFB5445A),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFF1EEFF),
      ),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF6A5AE0), size: 28),
    );
  }
}
