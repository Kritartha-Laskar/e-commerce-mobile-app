import 'package:flutter/material.dart';
import 'otp_verification_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isChecked = true;
  String userType = "user";

  // ✅ Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  // ✅ REGISTER FUNCTION
  Future<void> handleRegister() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Policy")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.register(
      nameController.text,
      emailController.text,
      passwordController.text,
      userType,
    );

    setState(() => isLoading = false);

    if (result != null && result['token'] != null) {
      String token = result['token'];
      debugPrint("REGISTER TOKEN: $token");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token); // ✅ FIX

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OtpVerificationPage()),
      );
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
          color: const Color(0xFFF3F3F7),
          child: Column(
            children: [
              // 🔵 Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFF7F6CF2)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      "Create account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Join Xaj-par today",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // 🔽 Form
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Full name"),
                        const SizedBox(height: 6),
                        inputField("Enter Name", controller: nameController),

                        const SizedBox(height: 15),

                        const Text("Email address"),
                        const SizedBox(height: 6),
                        inputField("Enter Email", controller: emailController),

                        const SizedBox(height: 15),

                        const Text("Phone number"),
                        const SizedBox(height: 6),
                        inputField(
                          "Enter Phone Number",
                          controller: phoneController,
                        ),

                        const SizedBox(height: 15),

                        const Text("Password"),
                        const SizedBox(height: 6),
                        inputField(
                          "********",
                          obscure: true,
                          controller: passwordController,
                        ),

                        const SizedBox(height: 15),

                        // 🔘 USER TYPE RADIO BUTTONS
                        const Text("Select Account Type"),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("User"),
                                value: "user",
                                groupValue: userType,
                                onChanged: (value) {
                                  setState(() {
                                    userType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Seller"),
                                value: "seller",
                                groupValue: userType,
                                onChanged: (value) {
                                  setState(() {
                                    userType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  isChecked = val!;
                                });
                              },
                              activeColor: Colors.deepPurple,
                            ),
                            const Expanded(
                              child: Text(
                                "I agree to the Terms & Privacy Policy",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // 🔥 REGISTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Create Account"),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(
                                    text: "Sign In",
                                    style: TextStyle(color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Updated input field
  Widget inputField(
    String hint, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}
