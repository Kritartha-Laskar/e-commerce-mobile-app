import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'get_started_page.dart';
import '../frontpage/frontpage.dart';
import '../saler/salerproductshow.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();

    // After 3 seconds → check login state and navigate accordingly
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final String? userType = prefs.getString('user_type');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // ✅ Already logged in — go straight to the right home page
        if (userType == 'seller') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SalerProductShow()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FrontPage()),
          );
        }
      } else {
        // ❌ Not logged in — show onboarding/get started
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GetStartedPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF7F6CF2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.store, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Xaj-par",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Premium Shopping",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}