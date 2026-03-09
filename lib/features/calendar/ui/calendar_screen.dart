import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  final bool isLoggedIn;
  const CalendarScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: const Center(
        child: const Text("Calendar Screen"),
      ),
    );
  }
}