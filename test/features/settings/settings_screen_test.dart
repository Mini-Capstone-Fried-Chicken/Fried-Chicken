import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  group('SettingsScreen (feature)', () {
    setUp(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    testWidgets('shows screen sections and auth action button', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Accessibility Settings'), findsOneWidget);
      expect(find.text('Default Campus'), findsOneWidget);
      expect(find.text('Permission Management'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('shows sign in button when guest mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
    });

    testWidgets('renders campus segmented control options', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('SGW'), findsWidgets);
      expect(find.text('Loyola'), findsWidgets);
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('toggles large text directly from settings controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Large Text'));
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);

      await tester.tap(find.text('Large Text'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
    });

    testWidgets('accepts isLoggedIn parameter correctly', (tester) async {
      const screenLoggedIn = SettingsScreen(isLoggedIn: true);
      const screenLoggedOut = SettingsScreen(isLoggedIn: false);

      expect(screenLoggedIn.isLoggedIn, isTrue);
      expect(screenLoggedOut.isLoggedIn, isFalse);
    });
  });
}
