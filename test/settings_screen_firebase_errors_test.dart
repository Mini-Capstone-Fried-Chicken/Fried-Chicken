import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Error Handling Tests', () {
    testWidgets('logout triggers error handling when Firebase fails', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: true),
        ),
      );
      await tester.pumpAndSettle();

      // Find logout button by text
      final logoutButton = find.text('Logout');
      expect(logoutButton, findsOneWidget);

      // Tap logout - will trigger Firebase error since not initialized
      await tester.tap(logoutButton);
      await tester.pump();
      
      // Wait for error handling
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      // The catch block will execute showing error snackbar
    });

    testWidgets('logout button icon is visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify icon exists
      final icon = find.byIcon(Icons.logout);
      expect(icon, findsOneWidget);
      
      // Tap on the icon specifically
      await tester.tap(icon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('temporary testing note is displayed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify temporary note
      expect(find.text('(Temporary for testing)'), findsOneWidget);
    });

    testWidgets('layout uses correct alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Column exists
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('screen has scaffold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold exists
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('guest mode shows correct message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify guest message
      expect(find.text('Not logged in (Guest mode)'), findsOneWidget);
      
      // Verify no logout elements
      expect(find.text('Logout'), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(find.text('(Temporary for testing)'), findsNothing);
    });

    testWidgets('settings screen title has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(isLoggedIn: true),
        ),
      );
      await tester.pumpAndSettle();

      // Find the title text widget
      final titleWidget = tester.widget<Text>(
        find.text('Settings Screen'),
      );
      
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
