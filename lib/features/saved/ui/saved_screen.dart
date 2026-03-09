import 'package:flutter/material.dart';

class SavedScreen extends StatelessWidget {
  final bool isLoggedIn;
  const SavedScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: const Center(
        child: const Text("Saved Screen"),
      ),
    );
  }
}
