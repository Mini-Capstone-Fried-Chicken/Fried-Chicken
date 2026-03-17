import 'package:campus_app/features/settings/ui/settings_screen.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('SettingsScreen', () {
    setUp(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    testWidgets('renders sectioned settings layout and sign out button when logged in', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Accessibility Settings'), findsOneWidget);
      expect(find.text('Default Campus'), findsOneWidget);
      expect(find.text('Calendar Access'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('renders sign in button when user is not logged in', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: false),
        ),
      );

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
    });

    testWidgets('accessibility controls are gated until accessibility mode is enabled', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      await tester.ensureVisible(find.text('High Contrast mode'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('High Contrast mode'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        AppSettingsController.state.highContrastModeEnabled,
        isFalse,
      );

      await tester.tap(find.text('Assessibility Mode'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.accessibilityModeEnabled, isTrue);

      await tester.tap(find.text('High Contrast mode'));
      await tester.pumpAndSettle();
      expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
    });

    testWidgets('high contrast mode switch updates shared settings when accessibility mode is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      await tester.tap(find.text('Assessibility Mode'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);

      await tester.ensureVisible(find.text('High Contrast mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High Contrast mode'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
    });

    testWidgets('large text switch updates shared settings when accessibility mode is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      await tester.tap(find.text('Assessibility Mode'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);

      await tester.ensureVisible(find.text('Large Text'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large Text'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
    });

    testWidgets('calendar access switch updates shared settings state', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);

      await tester.tap(find.text('Calendar Access'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.calendarAccessEnabled, isFalse);
    });

    testWidgets('high contrast active settings screen uses dark page background', (tester) async {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);

      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('listens to shared settings updates after initial build', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);
      await tester.pumpAndSettle();

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('default campus segmented control allows switching to Loyola', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      await tester.tap(find.text('Loyola'));
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );

      expect(segmentedButton.selected, {'Loyola'});
    });
  });
}