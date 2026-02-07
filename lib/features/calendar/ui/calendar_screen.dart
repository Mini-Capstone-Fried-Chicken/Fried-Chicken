import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  final bool isLoggedIn;
  const CalendarScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Calendar Screen"),
      ),
    );
  }
}
