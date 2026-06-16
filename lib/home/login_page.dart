import 'package:flutter/material.dart';
import '../frontpage/frontpage.dart' as frontpage;
import '../services/api_service.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../saler/salerproductshow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> handleLogin() async {

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter email and password"),
        ),
      );

      return;
    }

    setState(() => isLoading = true);

    // ✅ LOGIN API
    final result = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    // ✅ SUCCESS
    if (result != null && result['token'] != null) {

      // ✅ GET USER TYPE FROM API
      String userType =
          result['user']['user_type'].toString();

      print("USER TYPE: $userType");

      // ✅ AUTO REDIRECT
      if (userType == "seller") {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const SalerProductShow(),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const frontpage.FrontPage(),
          ),
        );
      }

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid email or password"),
        ),
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

              // 🔵 HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A5AE0),
                      Color(0xFF7F6CF2),
                    ],
                  ),
                ),

                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    SizedBox(height: 20),

                    Text(
                      "Welcome back",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Sign in to continue",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔽 FORM
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const SizedBox(height: 10),

                        const Text("Email address"),

                        const SizedBox(height: 6),

                        TextField(
                          controller: emailController,

                          decoration: InputDecoration(
                            hintText:
                                "Enter your email",

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      25),

                              borderSide:
                                  const BorderSide(
                                color: Colors.deepPurple,
                              ),
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      25),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        const Text("Password"),

                        const SizedBox(height: 6),

                        TextField(
                          controller: passwordController,
                          obscureText: true,

                          decoration: InputDecoration(
                            hintText:
                                "Enter your password",

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),

                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      25),

                              borderSide: BorderSide(
                                color:
                                    Colors.grey.shade300,
                              ),
                            ),

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      25),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Align(
                          alignment:
                              Alignment.centerRight,

                          child: GestureDetector(
                            onTap: () {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },

                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(
                                color:
                                    Colors.deepPurple,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ✅ LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : handleLogin,

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.deepPurple,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        25),
                              ),

                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),

                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                  )
                                : const Text(
                                    "Sign In",
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [

                            Expanded(
                              child: const Divider(),
                            ),

                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                      horizontal: 10),

                              child: Text(
                                "or continue with",
                              ),
                            ),

                            Expanded(
                              child: const Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // Row(
                        //   children: [

                        //     Expanded(
                        //       child: socialButton(
                        //         "Google",
                        //         Colors.blue,
                        //       ),
                        //     ),

                        //     const SizedBox(width: 10),

                        //     Expanded(
                        //       child: socialButton(
                        //         "Apple",
                        //         Colors.black,
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        const SizedBox(height: 40),

                        Center(
                          child: GestureDetector(
                            onTap: () {

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterPage(),
                                ),
                              );
                            },

                            child: const Text.rich(
                              TextSpan(
                                text: "No account? ",

                                style: TextStyle(
                                  color: Colors.grey,
                                ),

                                children: [

                                  TextSpan(
                                    text: "Register",

                                    style: TextStyle(
                                      color: Colors.deepPurple,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget socialButton(String text, Color color) {

    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 12),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),

        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          CircleAvatar(
            radius: 6,
            backgroundColor: color,
          ),

          const SizedBox(width: 8),

          Text(text),
        ],
      ),
    );
  }
}