import 'package:flutter/material.dart';
import "../screens/explore_screen.dart";
import "../screens/calendar_screen.dart";
import "../screens/saved_screen.dart";
import "../screens/settings_screen.dart";

const Color burgundy = Color(0xFF800020);

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final bool isLoggedIn;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.isLoggedIn,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
  }

  void _navigate(BuildContext context, int index) {
    setState(() {
      currentIndex = index;
    });

    Widget destination;
    if (widget.isLoggedIn) {
      switch (index) {
        case 0:
          destination = ExploreScreen(isLoggedIn: widget.isLoggedIn);
          break;
        case 1:
          destination = CalendarScreen(isLoggedIn: widget.isLoggedIn);
          break;
        case 2:
          destination = SavedScreen(isLoggedIn: widget.isLoggedIn);
          break;
        case 3:
          destination = SettingsScreen(isLoggedIn: widget.isLoggedIn);
          break;
        default:
          return;
      }
    } else {
      switch (index) {
        case 0:
          destination = ExploreScreen(isLoggedIn: widget.isLoggedIn);
          break;
        case 1:
          destination = SettingsScreen(isLoggedIn: widget.isLoggedIn);
          break;
        default:
          return;
      }
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: Duration.zero, // No transition duration
        reverseTransitionDuration: Duration.zero, // No reverse transition duration
        transitionsBuilder: (_, _, _, child) => child, // Directly show the new page
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.isLoggedIn
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: "Calendar",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: "Saved",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ]
        : const [ //guest
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      items: items,
      type: BottomNavigationBarType.fixed,
      backgroundColor: burgundy,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      onTap: (index) => _navigate(context, index),
    );
  }
}
