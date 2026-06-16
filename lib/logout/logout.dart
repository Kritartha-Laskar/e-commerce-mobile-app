import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../home/login_page.dart';

class LogoutResult {
  final bool success;
  final String message;

  const LogoutResult({
    required this.success,
    required this.message,
  });
}

class LogoutService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Calls POST /api/logout and clears local session.
  static Future<LogoutResult> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String message = 'Logged out successfully';

    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
            'Authorization': 'Bearer $token',
          },
        );

        print('LOGOUT STATUS: ${response.statusCode}');
        print('LOGOUT BODY: ${response.body}');

        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['message'] != null) {
              message = data['message'].toString();
            }
          } catch (_) {}
        }

        if (response.statusCode != 200 &&
            response.statusCode != 204 &&
            message == 'Logged out successfully') {
          message = 'Session cleared locally';
        }
      } catch (e) {
        print('LOGOUT ERROR: $e');
        message = 'Session cleared locally';
      }
    }

    await _clearSession();
    return LogoutResult(success: true, message: message);
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_type');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  /// Shows confirmation, calls logout API, then navigates to login.
  static Future<void> handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6A5AE0)),
      ),
    );

    final result = await logout();

    if (!context.mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: const Color(0xFF6A5AE0),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
