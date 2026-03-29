import "package:flutter/material.dart";
import '../features/settings/app_settings.dart';
import '../features/saved/saved_directions_controller.dart';

import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import "../features/explore/ui/explore_screen.dart";
import "../features/saved/ui/saved_screen.dart";
import "../features/settings/ui/settings_screen.dart";

class AppShell extends StatefulWidget {
  final bool isLoggedIn;
  const AppShell({super.key, required this.isLoggedIn});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SavedDirectionsController.notifier.addListener(_onDirectionsRequested);
  }

  void _onDirectionsRequested() {
    if (!widget.isLoggedIn) return;
    if (SavedDirectionsController.notifier.value == null) return;
    if (!mounted) return;
    if (currentIndex != 0) {
      setState(() => currentIndex = 0);
    }
  }

  @override
  void dispose() {
    SavedDirectionsController.notifier.removeListener(_onDirectionsRequested);
    super.dispose();
  }

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

    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: AppSettingsController.notifier,
      builder: (context, settings, _) {
        return Scaffold(
          body: pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => setState(() => currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppUiColors.primary(
              highContrastEnabled: settings.highContrastModeEnabled,
            ),
            selectedItemColor: settings.highContrastModeEnabled
                ? Colors.black
                : Colors.white,
            unselectedItemColor: settings.highContrastModeEnabled
                ? Colors.black54
                : Colors.white70,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: items,
          ),
        );
      },
    );
  }
}
