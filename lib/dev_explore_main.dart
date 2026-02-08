// lib/dev_explore_main.dart
import 'package:flutter/material.dart';
import 'features/explore/ui/explore_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ExploreScreen(isLoggedIn: true),
    ),
  );
}
//flutter run -t lib/dev_explore_main.dart -d emulator-5554
