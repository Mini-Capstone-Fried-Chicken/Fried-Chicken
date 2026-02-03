import 'package:flutter/material.dart';
import "../screens/explore_screen.dart";
import "../screens/calendar_screen.dart";
import "../screens/saved_screen.dart";
import "../screens/settings_screen.dart";

const Color burgundy = Color(0xFF800020);

class MainApp extends StatefulWidget {
  final bool isLoggedIn;
  const MainApp({super.key, required this.isLoggedIn});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = widget.isLoggedIn
        ? [
            ExploreScreen(isLoggedIn: widget.isLoggedIn),
            CalendarScreen(isLoggedIn: widget.isLoggedIn),
            SavedScreen(isLoggedIn: widget.isLoggedIn),
            SettingsScreen(isLoggedIn: widget.isLoggedIn),
          ]
        : [
            ExploreScreen(isLoggedIn: widget.isLoggedIn),
            SettingsScreen(isLoggedIn: widget.isLoggedIn),
          ];

    final List<BottomNavigationBarItem> items = widget.isLoggedIn
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Saved"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() {
          currentIndex = index;
        }),
        type: BottomNavigationBarType.fixed,
        backgroundColor: burgundy,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: items,
      ),
    );
  }
}
