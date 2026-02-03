import 'package:flutter/material.dart';
import 'screens/indoor_page.dart';
import 'screens/login_page.dart';

import 'widgets/main_app.dart';

void main() {
  const bool isLoggedIn = true;
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Guide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: HomePage(isLoggedIn: isLoggedIn),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '../assets/images/logo.png',
      width: 200,
      height: 200, 
      fit: BoxFit.contain,
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, 
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF800020),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isLoggedIn;
  const HomePage({super.key, required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.55, 
              child: Image.asset(
                '../assets/images/concordia.png',
                fit: BoxFit.cover, 
                color: const Color(0xFF800020).withOpacity(0.5), 
                colorBlendMode: BlendMode.darken,
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: <Widget>[
                  const Text(
                    "Welcome to Campus",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    "your go-to map on campus",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                    ),
                  ),
                  const AppLogo(),
                  // AppButton to Sign In
                  AppButton(
                    text: "Get started",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInPage()),
                      );
                    },
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MainApp(isLoggedIn: isLoggedIn),
                          ),
                        );
                      },
                      child: const Text("Explore Campus Map"),
                  ),
                ],
              ),
            ),
          ],

                  // Indoor map button for Sprint 3
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => const IndoorPage()),
                  //     );
                  //   },
                  //   child: const Text("Open Indoor Map"),
                  // ),
              ),
            ),
        );
  }
}

