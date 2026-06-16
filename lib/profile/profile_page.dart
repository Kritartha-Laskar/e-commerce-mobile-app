import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../frontpage/frontpage.dart';
import '../frontpage/search_page.dart';
import '../chart/cart_page.dart';
import 'edit_profile_page.dart';
import '../track/my_orders_page.dart';
import '../saler/seller_my_orders_page.dart';
import '../chart/address_page.dart';
import '../frontpage/wishlist_page.dart';
import '../topbotam/topbar.dart';
import '../topbotam/bottombar.dart';
import '../topbotam/seller_bottombar.dart';
import '../services/my_cartapi.dart';
import '../services/orde_api.dart';
import '../services/seller_orders_api.dart';
import '../logout/logout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User data from SharedPreferences
  String _name = '';
  String _email = '';
  String _initials = '';
  String _userType = '';

  // Stats
  int _cartCount = 0;
  int _orderCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'User';
    final email = prefs.getString('user_email') ?? '';
    final userType = prefs.getString('user_type') ?? '';

    // Build initials from name
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : 'U';

    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _initials = initials;
        _userType = userType;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type') ?? '';

      final cartItems = await MyCartApiService.getCartItems();
      final orders = userType == 'seller'
          ? await SellerOrdersApiService.getMyOrders()
          : await OrderApiService.getMyOrders();

      if (mounted) {
        setState(() {
          _cartCount = (cartItems as List).length;
          _orderCount = orders.length;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statsLoading = false);
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
          decoration: const BoxDecoration(color: Colors.white),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F8FB),
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(
                      top: 20, left: 20, right: 20, bottom: 10),
                  child: const TopBar(),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // Purple background
                      Container(
                        height: 220,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6A5AE0),
                        ),
                      ),

                      // Content
                      Column(
                        children: [
                          // ── Profile Header ──
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 60, left: 20, right: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Avatar with initials
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _initials.isEmpty ? 'U' : _initials,
                                          style: const TextStyle(
                                            color: Color(0xFF6A5AE0),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _name.isEmpty ? 'Loading...' : _name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _email,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfilePage()),
                                    );
                                    // Reload after edit
                                    _loadUserData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // ── Stats Card ──
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
                            child: _statsLoading
                                ? const Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF6A5AE0),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _statItem(
                                          _cartCount.toString(), "Cart Items"),
                                      Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade100),
                                      _statItem(_orderCount.toString(), "Orders"),
                                      Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade100),
                                      _statItem("0", "Reviews"),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // ── Menu Items ──
                          Expanded(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  _menuItem(
                                    icon: Icons.shopping_bag_outlined,
                                    iconBg: const Color(0xFFF1EEFF),
                                    iconColor: const Color(0xFF6A5AE0),
                                    title: "My Orders",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => _userType == 'seller'
                                              ? const SellerMyOrdersPage()
                                              : const MyOrdersPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  // _menuItem(
                                  //   icon: Icons.favorite_border,
                                  //   iconBg: const Color(0xFFFCEEED),
                                  //   iconColor: const Color(0xFFE57373),
                                  //   title: "Wishlist",
                                  //   onTap: () {
                                  //     Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //           builder: (_) =>
                                  //               const WishlistPage()),
                                  //     );
                                  //   },
                                  // ),
                                  _menuItem(
                                    icon: Icons.location_on_outlined,
                                    iconBg: const Color(0xFFE8F5E9),
                                    iconColor: const Color(0xFF81C784),
                                    title: "Addresses",
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const AddressPage(
                                                fromProfile: true)),
                                      );
                                    },
                                  ),
                                  // _menuItem(
                                  //   icon: Icons.credit_card_outlined,
                                  //   iconBg: const Color(0xFFFFF3E0),
                                  //   iconColor: const Color(0xFFFFB74D),
                                  //   title: "Payment Methods",
                                  // ),
                                  _menuItem(
                                    icon: Icons.logout,
                                    iconBg: const Color(0xFFFFEBEE),
                                    iconColor: Colors.redAccent,
                                    title: "Logout",
                                    titleColor: Colors.redAccent,
                                    showChevron: false,
                                    onTap: () => LogoutService.handleLogout(context),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _userType == 'seller'
                ? const SellerBottomBar(selectedIndex: 3)
                : const CustomBottomBar(selectedIndex: 3),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: Color(0xFF6A5AE0),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Color titleColor = Colors.black87,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: titleColor,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
