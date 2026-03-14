import 'package:campus_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('SettingsScreen', () {
    testWidgets('shows logout UI when user is logged in', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: true),
        ),
      );

      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('(Temporary for testing)'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('(Guest mode)'), findsNothing);
    });

    testWidgets('shows sign in UI when user is not logged in', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const SettingsScreen(isLoggedIn: false),
        ),
      );

      expect(find.text('Settings Screen'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('(Guest mode)'), findsOneWidget);
      expect(find.text('Logout'), findsNothing);
      expect(find.text('(Temporary for testing)'), findsNothing);
    });

    testWidgets('calls logout override when logout button is pressed', (
      tester,
    ) async {
      var logoutCalled = false;

      await tester.pumpWidget(
        makeTestableWidget(
          SettingsScreen(
            isLoggedIn: true,
            onLogoutOverride: (_) async {
              logoutCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('calls sign in override when sign in button is pressed', (
      tester,
    ) async {
      var signInCalled = false;

      await tester.pumpWidget(
        makeTestableWidget(
          SettingsScreen(
            isLoggedIn: false,
            onSignInOverride: (_) {
              signInCalled = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(signInCalled, isTrue);
    });

    testWidgets('logout override can show snackbar path safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(
          SettingsScreen(
            isLoggedIn: true,
            onLogoutOverride: (context) async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fake logout error')),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Logout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fake logout error'), findsOneWidget);
    });
  });
}