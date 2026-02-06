import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import '../main.dart';

class BackButtonWidget extends StatelessWidget {
  final Widget destinationPage;

  const BackButtonWidget({super.key, required this.destinationPage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationPage),
        );
      },
      child: const Icon(Icons.arrow_back, size: 30, color: Color(0xFF76263D)),
    );
  }
}

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  bool isVerified = false;
  String? verifiedDocId;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        duration: const Duration(seconds: 3),
        animation: null,
      ),
    );
  }

  Future<void> _verifyUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();

    if (name.isEmpty) {
      _showMessage("Please enter your name.");
      return;
    }

    if (email.isEmpty || !email.contains("@")) {
      _showMessage("Please enter a valid email address.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: email)
          .where("name", isEqualTo: name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showMessage("No account found with that name and email.");
        return;
      }

      setState(() {
        isVerified = true;
        verifiedDocId = query.docs.first.id;
      });
    } catch (_) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.length < 6) {
      _showMessage("Password must be at least 6 characters.");
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(verifiedDocId)
          .update({"password": newPassword});

      _showMessage("Password updated successfully!", isError: false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInPage()),
        );
      }
    } catch (_) {
      _showMessage("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        isVerified ? "Set New Password" : "Forgot Password?",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Color(0xFF76263D),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BackButtonWidget(
                        destinationPage: const SignInPage(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Text(
                        isVerified
                            ? "Enter your new password below."
                            : "Enter your name and email to verify your account.",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!isVerified) ...[
                      const Text("Name", style: TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Your name",
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Email address",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Your email",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 30),
                      AppButton(
                        text: "Verify",
                        onPressed: _verifyUser,
                        isLoading: isLoading,
                        enabled: !isLoading,
                      ),
                    ] else ...[
                      const Text(
                        "New Password",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      UserField(
                        label: "New password",
                        obscureText: true,
                        controller: newPasswordController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Confirm Password",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Confirm password",
                        obscureText: true,
                        controller: confirmPasswordController,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 30),
                      AppButton(
                        text: "Reset Password",
                        onPressed: _resetPassword,
                        isLoading: isLoading,
                        enabled: !isLoading,
                      ),
                    ],
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
