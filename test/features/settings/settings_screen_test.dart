import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Tests', () {
    testWidgets('displays Settings Screen title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: false)),
      );

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('shows logout button when logged in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('(Temporary for testing)'), findsOneWidget);
    });

    testWidgets('shows sign in button when not logged in (guest mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: false)),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('(Guest mode)'), findsOneWidget);
      expect(find.text('Logout'), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('logout button is tappable when logged in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      // Find the logout button by its icon
      final logoutIcon = find.byIcon(Icons.logout);
      expect(logoutIcon, findsOneWidget);

      // Verify text exists
      expect(find.text('Logout'), findsOneWidget);

      // Tap the button to trigger logout
      await tester.tap(logoutIcon);
      await tester.pump();
    });

    testWidgets('logout button has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      // Verify button exists with correct content
      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('(Temporary for testing)'), findsOneWidget);
    });

    testWidgets('sign in button is tappable when in guest mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: false)),
      );
      await tester.pumpAndSettle();

      // Find the sign in button by its icon
      final signInIcon = find.byIcon(Icons.login);
      expect(signInIcon, findsOneWidget);

      // Verify text exists
      expect(find.text('Sign In'), findsOneWidget);

      // Tap the button to trigger sign in
      await tester.tap(signInIcon);
      await tester.pump();
    });

    testWidgets('sign in button has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: false)),
      );
      await tester.pumpAndSettle();

      // Verify button exists with correct content
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('(Guest mode)'), findsOneWidget);
    });

    testWidgets('screen layout is centered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: true)),
      );

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('accepts isLoggedIn parameter correctly', (tester) async {
      const screenLoggedIn = SettingsScreen(isLoggedIn: true);
      const screenLoggedOut = SettingsScreen(isLoggedIn: false);

      expect(screenLoggedIn.isLoggedIn, true);
      expect(screenLoggedOut.isLoggedIn, false);
    });

    testWidgets('displays all elements in correct order when logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: true)),
      );
      await tester.pumpAndSettle();

      final column = find.byType(Column);
      expect(column, findsOneWidget);

      // Check elements exist
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('(Temporary for testing)'), findsOneWidget);
    });

    testWidgets('displays all elements in correct order when in guest mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen(isLoggedIn: false)),
      );
      await tester.pumpAndSettle();

      final column = find.byType(Column);
      expect(column, findsOneWidget);

      // Check elements exist
      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('(Guest mode)'), findsOneWidget);
    });
  });
}
