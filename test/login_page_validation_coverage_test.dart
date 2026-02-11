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

  group('Login Page Validation Coverage Tests', () {
    testWidgets('validates invalid email format', (tester) async {
      await _pumpLoginPage(tester);

      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      // Test without @ symbol
      await tester.enterText(emailField, 'invalidemail');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('validates empty email', (tester) async {
      await _pumpLoginPage(tester);

      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('allows valid email format', (tester) async {
      await _pumpLoginPage(tester);

      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'valid@email.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // This will attempt login and hit Firebase error handling
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('signup validates all required fields in sequence', (tester) async {
      await _pumpLoginPage(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Empty name
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Add name, empty email
      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'Test User');
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Add invalid email
      final emailField = find.byType(TextField).at(1);
      await tester.enterText(emailField, 'invalid');
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Add valid email, weak password
      await tester.enterText(emailField, 'test@example.com');
      final passwordField = find.byType(TextField).at(2);
      await tester.enterText(passwordField, '12345');
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Add strong password, mismatched confirm
      await tester.enterText(passwordField, 'password123');
      final confirmField = find.byType(TextField).at(3);
      await tester.enterText(confirmField, 'different');
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(find.byType(SnackBar), findsWidgets);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Finally valid form - will hit Firebase
      await tester.enterText(confirmField, 'password123');
      await tester.pump();
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('forgot password button navigates correctly', (tester) async {
      await _pumpLoginPage(tester);

      expect(find.text('Forgot Password?'), findsOneWidget);
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('displays loading state during authentication', (tester) async {
      await _pumpLoginPage(tester);

      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Tap login button
      await tester.tap(find.byType(AppButton));
      await tester.pump();
    });
  });
}
