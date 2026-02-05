import 'package:flutter/material.dart';

import 'screens/indoor_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Guide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
<<<<<<< Updated upstream
      width: 120,
=======
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
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
>>>>>>> Stashed changes
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
<<<<<<< Updated upstream
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
=======
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.50,
              child: Image.asset(
                'assets/images/concordia.png',
                fit: BoxFit.cover, 
                color: const Color(0xFF800020).withOpacity(0.5), 
                colorBlendMode: BlendMode.darken,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
>>>>>>> Stashed changes
                children: <Widget>[
                  const Text(
                    "Welcome to Campus",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "your go-to map on campus",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IndoorPage()),
                      );
                    },
                    child: const Text("Open Indoor Map"),
                  ),
                ],
              ),

              const AppLogo(),
            ],
          ),
        ),
      ),
    );
  }
}
