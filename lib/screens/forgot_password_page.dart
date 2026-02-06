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
      child: const Icon(
        Icons.arrow_back, 
        size: 30,
        color: Color(0xFF76263D), 
      ),
    );
  }
}

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

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

              const SizedBox(height: 100),
              SizedBox(
              width: 500,
              child: Image.asset(
                "assets/images/password.png",
                fit: BoxFit.cover,
              ),
            ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    
                    Center(child:
                      const Text(
                      "Please write your email to set a new password.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                    
                    const SizedBox(height: 60),

                    const Text(
                      "Email address",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    const UserField(label: "Your email"),
                    const SizedBox(height: 30),

                    AppButton(
                    text: "Send",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInPage()),
                      );
                    },
                  ),
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