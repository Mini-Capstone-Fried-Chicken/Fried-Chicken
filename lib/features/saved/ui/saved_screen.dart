import 'package:flutter/material.dart';

class SavedScreen extends StatelessWidget {
  final bool isLoggedIn;
  const SavedScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Saved Screen"),
      ),
    );
  }
}
