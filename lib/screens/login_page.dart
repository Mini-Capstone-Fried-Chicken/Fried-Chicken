import 'package:campus_app/screens/explore_screen.dart';
import 'package:flutter/material.dart';

import '../main.dart';
class UserField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController? controller;

  const UserField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Color(0xFF800020)),
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------
// Login/Signup toggle
// ----------------------
class LoginToggle extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

  const LoginToggle({
    super.key,
    required this.isLogin,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, 
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          _buildOption(
            text: "Sign In",
            isActive: isLogin,
            onTap: onLoginTap,
          ),
          _buildOption(
            text: "Sign Up",
            isActive: !isLogin,
            onTap: onSignupTap,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF800020) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------
// Main SignInPage
// ----------------------
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLogin = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              const AppLogo(),

              LoginToggle(
                isLogin: isLogin,
                onLoginTap: () {
                  setState(() => isLogin = true);
                },
                onSignupTap: () {
                  setState(() => isLogin = false);
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(
                      child: Text(
                        "Welcome to Campus",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Color(0xFF800020),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!isLogin) ...[
                      const Text(
                        "Name",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      const UserField(label: "Your name"),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      "Email address",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    const UserField(label: "Your email"),
                    const SizedBox(height: 20),

                    const Text(
                      "Password",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    const UserField(label: "Password", obscureText: true),
                    const SizedBox(height: 20),

                    if (!isLogin) ...[
                      const Text(
                        "Confirm your password",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      const UserField(label: "Confirm password", obscureText: true),
                      const SizedBox(height: 20),
                    ],

                    AppButton(
                      text: isLogin ? "Sign In" : "Sign Up",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExploreScreen(isLoggedIn: true)),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}