import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/app/app_shell.dart';
import 'package:campus_app/features/explore/ui/explore_screen.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/saved/ui/saved_screen.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';

void main() {
  group('AppShell Tests', () {
    testWidgets('AppShell displays 4 navigation items when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('AppShell displays 2 navigation items when logged out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: false)),
      );

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Calendar'), findsNothing);
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('AppShell displays ExploreScreen by default when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(CalendarScreen), findsNothing);
      expect(find.byType(SavedScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('AppShell displays ExploreScreen by default when logged out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: false)),
      );

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets('Tapping Calendar tab shows CalendarScreen when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Initially on Explore screen
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(CalendarScreen), findsNothing);

      // Tap on Calendar tab
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Should now show Calendar screen
      expect(find.byType(ExploreScreen), findsNothing);
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('Tapping Saved tab shows SavedScreen when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Initially on Explore screen
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(SavedScreen), findsNothing);

      // Tap on Saved tab
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      // Should now show Saved screen
      expect(find.byType(ExploreScreen), findsNothing);
      expect(find.byType(SavedScreen), findsOneWidget);
    });

    testWidgets('Tapping Settings tab shows SettingsScreen when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Initially on Explore screen
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should now show Settings screen
      expect(find.byType(ExploreScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Tapping Settings tab shows SettingsScreen when logged out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: false)),
      );

      // Initially on Explore screen
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Should now show Settings screen
      expect(find.byType(ExploreScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Navigation between tabs works correctly when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Start on Explore
      expect(find.byType(ExploreScreen), findsOneWidget);

      // Navigate to Calendar
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsOneWidget);

      // Navigate to Saved
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedScreen), findsOneWidget);

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Navigate back to Explore
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('Bottom navigation bar has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNavBar.type, BottomNavigationBarType.fixed);
      expect(bottomNavBar.backgroundColor, const Color(0xFF76263D));
      expect(bottomNavBar.selectedItemColor, Colors.white);
      expect(bottomNavBar.unselectedItemColor, Colors.white70);
      expect(bottomNavBar.selectedLabelStyle?.fontWeight, FontWeight.bold);
    });

    testWidgets('Bottom navigation bar updates currentIndex on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      // Initially on index 0
      expect(bottomNavBar.currentIndex, 0);

      // Tap on Calendar (index 1)
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      final updatedBottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(updatedBottomNavBar.currentIndex, 1);
    });

    testWidgets('AppShell has correct number of navigation items', (
      WidgetTester tester,
    ) async {
      // When logged in
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      BottomNavigationBar bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.items.length, 4);

      // When logged out
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: false)),
      );

      bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.items.length, 2);
    });

    testWidgets('AppShell passes isLoggedIn to all screens when logged in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Check Explore screen
      final exploreScreen = tester.widget<ExploreScreen>(
        find.byType(ExploreScreen),
      );
      expect(exploreScreen.isLoggedIn, true);

      // Navigate to Calendar
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      final calendarScreen = tester.widget<CalendarScreen>(
        find.byType(CalendarScreen),
      );
      expect(calendarScreen.isLoggedIn, true);

      // Navigate to Saved
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      final savedScreen = tester.widget<SavedScreen>(find.byType(SavedScreen));
      expect(savedScreen.isLoggedIn, true);

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      final settingsScreen = tester.widget<SettingsScreen>(
        find.byType(SettingsScreen),
      );
      expect(settingsScreen.isLoggedIn, true);
    });

    testWidgets('AppShell passes isLoggedIn to screens when logged out', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: false)),
      );

      // Check Explore screen
      final exploreScreen = tester.widget<ExploreScreen>(
        find.byType(ExploreScreen),
      );
      expect(exploreScreen.isLoggedIn, false);

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      final settingsScreen = tester.widget<SettingsScreen>(
        find.byType(SettingsScreen),
      );
      expect(settingsScreen.isLoggedIn, false);
    });

    testWidgets('Navigation icons are displayed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell(isLoggedIn: true)),
      );

      // Check that Image widgets are present for each tab
      expect(
        find.byType(Image),
        findsNWidgets(5),
      ); // 4 bottom nav + 1 logo from ExploreScreen
    });
  });
}
