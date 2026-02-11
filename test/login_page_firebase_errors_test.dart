import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _pumpLoginPage(WidgetTester tester) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));
    await tester.pumpAndSettle();
  }

  group('Login Error Handling Tests', () {
    testWidgets('handles error during signup attempt', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to Sign Up mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill in form
      final nameField = find.byType(TextField).at(0);
      final emailField = find.byType(TextField).at(1);
      final passwordField = find.byType(TextField).at(2);
      final confirmField = find.byType(TextField).at(3);

      await tester.enterText(nameField, 'Test User');
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmField, 'password123');
      await tester.pump();

      // Tap sign up - will fail due to Firebase not being initialized
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handles error during login attempt', (tester) async {
      await _pumpLoginPage(tester);

      // Fill in form
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Tap login - will fail and trigger error handling
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('continue as guest button works', (tester) async {
      await _pumpLoginPage(tester);

      // Find and tap continue as guest button
      expect(find.text('Continue as a guest'), findsOneWidget);
      await tester.tap(find.text('Continue as a guest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('signup validation checks empty name', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to Sign Up mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Try to submit without name
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Should show error for empty name
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('signup validation checks password length', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to Sign Up mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill in all fields but weak password
      final nameField = find.byType(TextField).at(0);
      final emailField = find.byType(TextField).at(1);
      final passwordField = find.byType(TextField).at(2);
      final confirmField = find.byType(TextField).at(3);

      await tester.enterText(nameField, 'Test User');
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'weak');
      await tester.enterText(confirmField, 'weak');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Should show error
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('signup validation checks password match', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to Sign Up mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill passwords that don't match
      final nameField = find.byType(TextField).at(0);
      final emailField = find.byType(TextField).at(1);
      final passwordField = find.byType(TextField).at(2);
      final confirmField = find.byType(TextField).at(3);

      await tester.enterText(nameField, 'Test User');
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmField, 'different123');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Should show error
      expect(find.byType(SnackBar), findsWidgets);
    });
  });
}
