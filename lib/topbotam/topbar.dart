import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../frontpage/notifications_page.dart';
import '../profile/profile_page.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  String userName = "User";
  String userInitials = "U";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    String? name = await ApiService.getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() {
        userName = name;
        userInitials = _getInitials(name);
      });
    }
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(" ");
    if (names.isNotEmpty) {
      if (names.length > 1) {
        return "${names[0][0]}${names[1][0]}".toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    }
    return "U";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Good morning 👋",
            //   style: TextStyle(color: Colors.grey, fontSize: 12),
            // ),
            const SizedBox(height: 2),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // GestureDetector(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const NotificationsPage(),
            //       ),
            //     );
            //   },
            //   child: const Icon(Icons.notifications_none, size: 28),
            // ),
            // const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EEFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Color(0xFF6A5AE0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
