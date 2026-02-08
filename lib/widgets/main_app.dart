import 'package:flutter/material.dart';
import "../screens/explore_screen.dart";
import "../screens/calendar_screen.dart";
import "../screens/saved_screen.dart";
import "../screens/settings_screen.dart";

const Color burgundy = Color(0xFF76263D); 

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
        ? [
            BottomNavigationBarItem(icon: Image.asset('assets/images/explore.png',width: 24, height: 24,), label: "Explore"), 
            BottomNavigationBarItem(icon: Image.asset('assets/images/calendar.png',width: 24, height: 24,), label: "Calendar"),
            BottomNavigationBarItem(icon: Image.asset('assets/images/saved.png',width: 24, height: 24,),label: "Saved"),
            BottomNavigationBarItem(icon: Image.asset('assets/images/settings.png',width: 24, height: 24,), label: "Settings"),
          ]
        : [
            BottomNavigationBarItem(icon: Image.asset('assets/images/explore.png',width: 24, height: 24,), label: "Explore"),
            BottomNavigationBarItem(icon: Image.asset('assets/images/settings.png',width: 24, height: 24,), label: "Settings"),
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
