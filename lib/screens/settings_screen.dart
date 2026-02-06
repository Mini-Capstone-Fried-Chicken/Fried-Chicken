import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final bool isLoggedIn;
  const SettingsScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Settings Screen"),
      ),
    );
  }
}
