import "package:flutter/material.dart";

import "../features/calendar/ui/calendar_screen.dart";
import "../features/explore/ui/explore_screen.dart";
import "../features/saved/ui/saved_screen.dart";
import "../features/settings/ui/settings_screen.dart";

const Color burgundy = Color(0xFF76263D);

class AppShell extends StatefulWidget {
  final bool isLoggedIn;
  const AppShell({super.key, required this.isLoggedIn});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = widget.isLoggedIn
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

    final items = widget.isLoggedIn
        ? [
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/explore.png", width: 24, height: 24),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/calendar.png", width: 24, height: 24),
              label: "Calendar",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/saved.png", width: 24, height: 24),
              label: "Saved",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/settings.png", width: 24, height: 24),
              label: "Settings",
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/explore.png", width: 24, height: 24),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/images/settings.png", width: 24, height: 24),
              label: "Settings",
            ),
          ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
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
