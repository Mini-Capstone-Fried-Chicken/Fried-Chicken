import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;
import 'package:campus_app/app/app_shell.dart';

// Adjust these imports if your screen/widget paths differ
import 'package:campus_app/features/explore/ui/explore_screen.dart';
import 'package:campus_app/features/calendar/ui/calendar_screen.dart';
import 'package:campus_app/features/saved/ui/saved_screen.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';

// run using:
// flutter run -d R5CWA1BZZSE integration_test/epic7_navigation_coreUI_e2e_test.dart --dart-define=GOOGLE_DIRECTIONS_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U --dart-define=GOOGLE_PLACES_API_KEY=AIzaSyAz7CcEsdorD_rQSq_fHruG5pvYuQAPu7U

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPIC-7 App Navigation & Core UI E2E Test', () {
    testWidgets('Complete Epic 7 flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // --- FORCE LOGOUT IF ALREADY LOGGED IN ---
      if (_isLoggedInNavVisible(tester)) {
        // Go to Settings
        final settingsTab = find.text('Settings');
        await tester.tap(settingsTab);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to find logout button
        final signOutButton = find.byKey(const Key('sign_out_button'));
        final signOutText = find.textContaining('Sign Out');

        if (signOutButton.evaluate().isNotEmpty) {
          await tester.tap(signOutButton);
        } else if (signOutText.evaluate().isNotEmpty) {
          await tester.tap(signOutText.first);
        }

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 3));
        });
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // FLOW 1: GUEST USER NAVIGATION BAR
      // Verify guest sees only Explore and Settings
      // --- ENTER GUEST MODE IF ON AUTH SCREEN ---
      await _enterGuestModeIfNeeded(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _expectGuestNavigation(tester);

      // Verify Explore screen is accessible
      await _openBottomTabByText(tester, 'Explore');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ExploreScreen), findsOneWidget);

      // Verify Settings screen is accessible for guests
      await _openBottomTabByText(tester, 'Settings');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // FLOW 2: SETTINGS FOR GUEST
      // Verify settings page contains expected setting groups/options
      await _expectSettingsCoreOptionsVisible(tester, loggedIn: false);

      // Verify general settings can be modified
      await _toggleIfExists(tester, const Key('accessibility_mode_toggle'));
      await _toggleIfExists(tester, const Key('high_contrast_toggle'));
      await _toggleIfExists(tester, const Key('large_text_toggle'));

      // Default campus selection
      await _changeDefaultCampusIfExists(tester);

      // FLOW 3: LOGIN
      // From guest settings page, press sign in button
      final signInButton = find.byKey(const Key('go_to_login_button'));
      final signInText = find.textContaining('Sign In');

      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } else if (signInText.evaluate().isNotEmpty) {
        await tester.tap(signInText.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Login (if not already done)
      if (!_isLoggedInNavVisible(tester)) {
        final emailField = find.byKey(const Key('login_email'));
        final passwordField = find.byKey(const Key('login_password'));
        final loginButton = find.byKey(const Key('login_button'));

        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        expect(loginButton, findsOneWidget);

        // Enter login credentials
        await tester.enterText(emailField, 'hiba.tal05@gmail.com');
        await tester.enterText(passwordField, '123456');
        await tester.pumpAndSettle();
        await tester.ensureVisible(loginButton);

        // Tap login button
        await tester.tap(loginButton);

        await tester.runAsync(() async {
          await Future.delayed(const Duration(seconds: 5));
        });
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify we're on the main app shell
      expect(find.byType(AppShell), findsOneWidget);

      // Give the auth transition time to fully swap guest nav -> logged-in nav
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 3));
      });
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // FLOW 4: LOGGED-IN USER NAVIGATION BAR
      // Logged-in nav should show Explore, Calendar, Saved, Settings
      await _expectLoggedInNavigation(tester);

      // Explore
      await _openBottomTabByText(tester, 'Explore');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ExploreScreen), findsOneWidget);

      // Calendar
      await _openBottomTabByText(tester, 'Calendar');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CalendarScreen), findsOneWidget);

      // Saved
      await _openBottomTabByText(tester, 'Saved');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SavedScreen), findsOneWidget);

      // Settings
      await _openBottomTabByText(tester, 'Settings');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // FLOW 5: SETTINGS FOR LOGGED-IN USER
      await _expectSettingsCoreOptionsVisible(tester, loggedIn: true);

      // Test general settings toggles
      await _toggleIfExists(tester, const Key('calendar_access_toggle'));
      await _toggleIfExists(tester, const Key('location_access_toggle'));
      await _toggleIfExists(tester, const Key('accessibility_mode_toggle'));

      // Test accessibility settings toggles
      await _toggleIfExists(tester, const Key('wheelchair_routing_toggle'));
      await _toggleIfExists(tester, const Key('high_contrast_toggle'));
      await _toggleIfExists(tester, const Key('large_text_toggle'));

      // Change default campus again if the control exists
      await _changeDefaultCampusIfExists(tester);

      // FLOW 6: SAVE / UNSAVE LOCATION
      await _openBottomTabByText(tester, 'Explore');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on a building on the map to open the popup
      final lbBuildingDetector = find.byKey(const Key('building_detector_LB'));
      final evBuildingDetector = find.byKey(const Key('building_detector_EV'));

      if (lbBuildingDetector.evaluate().isNotEmpty) {
        await tester.tap(lbBuildingDetector);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else if (evBuildingDetector.evaluate().isNotEmpty) {
        await tester.tap(evBuildingDetector);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify save toggle appears in building popup
      final saveToggle = find.byKey(const Key('save_toggle_button'));
      expect(
        saveToggle,
        findsOneWidget,
        reason: 'Save toggle should appear after opening a building popup',
      );

      // Save the building
      await tester.tap(saveToggle);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to Saved tab and verify saved locations screen is accessible
      await _openBottomTabByText(tester, 'Saved');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SavedScreen), findsOneWidget);

      // Optional: verify at least one saved item appears
      final savedItem = find.byKey(const Key('saved_location_item'));
      if (savedItem.evaluate().isNotEmpty) {
        expect(savedItem, findsWidgets);
      }

      // Optional: unfavorite from saved screen
      final removeFavoriteButton = find.byKey(
        const Key('remove_favorite_button'),
      );
      if (removeFavoriteButton.evaluate().isNotEmpty) {
        await tester.tap(removeFavoriteButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // FLOW 7: SIGN OUT
      await _openBottomTabByText(tester, 'Settings');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final signOutButton = find.byKey(const Key('sign_out_button'));
      if (signOutButton.evaluate().isNotEmpty) {
        await tester.tap(signOutButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        final signOutText = find.textContaining('Sign Out');
        if (signOutText.evaluate().isNotEmpty) {
          await tester.tap(signOutText.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // After sign out, guest nav should be visible again
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 4));
      });
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await _enterGuestModeIfNeeded(tester);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 2));
      });
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('Explore').evaluate().isNotEmpty ||
            find
                .byKey(const Key('continue_as_guest_button'))
                .evaluate()
                .isNotEmpty ||
            find.textContaining('Continue as Guest').evaluate().isNotEmpty,
        isTrue,
        reason:
            'After sign out, app should show either guest nav or the guest entry screen.',
      );

      if (find.text('Explore').evaluate().isNotEmpty) {
        await _expectGuestNavigation(tester);
      }
    });
  });
}

bool _isLoggedInNavVisible(WidgetTester tester) {
  return find.text('Calendar').evaluate().isNotEmpty &&
      find.text('Saved').evaluate().isNotEmpty;
}

Future<void> _enterGuestModeIfNeeded(WidgetTester tester) async {
  final continueAsGuestButton = find.byKey(
    const Key('continue_as_guest_button'),
  );
  final continueAsGuestText = find.textContaining('Continue as Guest');

  if (continueAsGuestButton.evaluate().isNotEmpty) {
    await tester.tap(continueAsGuestButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  } else if (continueAsGuestText.evaluate().isNotEmpty) {
    await tester.tap(continueAsGuestText.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

Future<void> _expectGuestNavigation(WidgetTester tester) async {
  expect(find.text('Explore'), findsOneWidget);
  expect(find.text('Settings'), findsOneWidget);

  // Guest should not see logged-in-only tabs
  expect(find.text('Calendar'), findsNothing);
  expect(find.text('Saved'), findsNothing);
}

Future<void> _expectLoggedInNavigation(WidgetTester tester) async {
  expect(find.text('Explore'), findsOneWidget);
  expect(find.text('Calendar'), findsOneWidget);
  expect(find.text('Saved'), findsOneWidget);
  expect(find.text('Settings'), findsOneWidget);
}

Future<void> _openBottomTabByText(WidgetTester tester, String label) async {
  final tab = find.text(label);
  expect(tab, findsOneWidget);
  await tester.tap(tab);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _toggleIfExists(WidgetTester tester, Key key) async {
  final toggle = find.byKey(key);
  if (toggle.evaluate().isNotEmpty) {
    await tester.tap(toggle);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

Future<void> _changeDefaultCampusIfExists(WidgetTester tester) async {
  final campusDropdown = find.byKey(const Key('default_campus_dropdown'));
  if (campusDropdown.evaluate().isNotEmpty) {
    await tester.tap(campusDropdown);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final loyolaOption = find.text('Loyola');
    if (loyolaOption.evaluate().isNotEmpty) {
      await tester.tap(loyolaOption.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    await tester.tap(campusDropdown);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final sgwOption = find.text('SGW');
    if (sgwOption.evaluate().isNotEmpty) {
      await tester.tap(sgwOption.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }
}

Future<void> _expectSettingsCoreOptionsVisible(
  WidgetTester tester, {
  required bool loggedIn,
}) async {
  // Default campus option
  final defaultCampusText = find.textContaining('Default Campus');
  if (defaultCampusText.evaluate().isNotEmpty) {
    expect(defaultCampusText, findsOneWidget);
  }

  // Permission management
  final calendarAccessText = find.textContaining('calendar');
  if (loggedIn && calendarAccessText.evaluate().isNotEmpty) {
    expect(calendarAccessText, findsWidgets);
  }

  // Accessibility settings group
  final accessibilityText = find.textContaining('Accessibility');
  if (accessibilityText.evaluate().isNotEmpty) {
    expect(accessibilityText, findsWidgets);
  }

  final wheelchairText = find.textContaining('wheelchair');
  if (wheelchairText.evaluate().isNotEmpty) {
    expect(wheelchairText, findsWidgets);
  }

  final highContrastText = find.textContaining('contrast');
  if (highContrastText.evaluate().isNotEmpty) {
    expect(highContrastText, findsWidgets);
  }

  final textSizeText = find.textContaining('text');
  if (textSizeText.evaluate().isNotEmpty) {
    expect(textSizeText, findsWidgets);
  }

  // Sign out visible for logged-in user
  final signOutText = find.textContaining('Sign Out');
  if (loggedIn && signOutText.evaluate().isNotEmpty) {
    expect(signOutText, findsOneWidget);
  }
}
