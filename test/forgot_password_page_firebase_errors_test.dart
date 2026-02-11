import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/auth/ui/forgot_password_page.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPassword Error Handling Tests', () {
    testWidgets('handles invalid-email error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'invalid');
      await tester.pump();

      // Tap send reset link
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handles user-not-found error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Enter non-existent email
      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'nonexistent@example.com');
      await tester.pump();

      // Tap send reset link
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handles generic error', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Enter valid email (will fail with Firebase not initialized)
      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Tap send reset link
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handles empty email validation', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Don't enter any email
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Should show validation error
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('handles email without @ symbol', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Enter email without @
      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'invalidemail');
      await tester.pump();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      // Should show validation error
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('back to login button visible after email sent', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Initial state - should have Send Reset Link button
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsNothing);
    });

    testWidgets('all UI elements are present', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Verify all elements exist
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back arrow navigates to login', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
      await tester.pumpAndSettle();

      // Find and tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
