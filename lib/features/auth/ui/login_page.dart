import "package:campus_app/app/app_shell.dart";
import "package:campus_app/shared/widgets/app_widgets.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "forgot_password_page.dart";

class UserField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  const UserField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
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
              borderSide: const BorderSide(color: Color(0xFF76263D)),
            ),
          ),
        ),
      ],
    );
  }
}

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
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          _buildOption(text: "Sign In", isActive: isLogin, onTap: onLoginTap),
          _buildOption(text: "Sign Up", isActive: !isLogin, onTap: onSignupTap),
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
            color: isActive ? const Color(0xFF76263D) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
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

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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

  void _continueAsGuest() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppShell(isLoggedIn: false)),
    );
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _handleAuth() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final name = nameController.text.trim();
    final confirmPassword = confirmPasswordController.text;

    if (!isLogin && name.isEmpty) {
      _showMessage("Please enter your name.");
      return;
    }

    if (email.isEmpty || !email.contains("@")) {
      _showMessage("Please enter a valid email address.");
      return;
    }

    if (!isLogin && password.length < 6) {
      _showMessage("Password must be at least 6 characters.");
      return;
    }

    if (!isLogin && password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Create new user with Firebase Authentication
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.updateDisplayName(name);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell(isLoggedIn: true)),
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showMessage("An unexpected error occurred. Please try again.");
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
              const AppLogo(),
              const Center(
                child: Text(
                  "Welcome to Campus",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Color(0xFF76263D),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              LoginToggle(
                isLogin: isLogin,
                onLoginTap: () => setState(() => isLogin = true),
                onSignupTap: () => setState(() => isLogin = false),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    if (!isLogin) ...[
                      const Text("Name", style: TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Your name",
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text("Email address", style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    UserField(
                      label: "Your email",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 20),
                    const Text("Password", style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    UserField(
                      label: "Password",
                      obscureText: true,
                      controller: passwordController,
                      textInputAction:
                          isLogin ? TextInputAction.done : TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                    ),
                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPassword(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    if (!isLogin) ...[
                      const Text(
                        "Confirm your password",
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      UserField(
                        label: "Confirm password",
                        obscureText: true,
                        controller: confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 50),
                    AppButton(
                      text: isLogin ? "Sign In" : "Sign Up",
                      onPressed: _handleAuth,
                      isLoading: isLoading,
                      enabled: !isLoading,
                    ),
                    if (isLogin) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: isLoading ? null : _continueAsGuest,
                          child: const Text(
                            "Continue as a guest",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF76263D),
                            ),
                          ),
                        ),
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
