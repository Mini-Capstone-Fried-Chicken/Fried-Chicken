import "package:campus_app/shared/widgets/app_widgets.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "login_page.dart";

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
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool emailSent = false;

  @override
  void dispose() {
    emailController.dispose();
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

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty || !email.contains("@")) {
      _showMessage("Please enter a valid email address.");
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      setState(() => emailSent = true);
      _showMessage(
        "Password reset link sent! Check your email.",
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showMessage("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Color(0xFF76263D),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BackButtonWidget(destinationPage: const SignInPage()),
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
                        emailSent
                            ? "If an email is associated with an account, a password reset link has been sent. You can close this page and return to login."
                            : "Enter your email address and we'll send you a link to reset your password.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!emailSent) ...[
                      const Text("Email address", style: TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Your email",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 30),
                      AppButton(
                        text: "Send Reset Link",
                        onPressed: _sendPasswordResetEmail,
                        isLoading: isLoading,
                        enabled: !isLoading,
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      AppButton(
                        text: "Back to Login",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInPage()),
                          );
                        },
                        isLoading: false,
                        enabled: true,
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