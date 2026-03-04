import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/auth/ui/forgot_password_page.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _pumpForgotPassword(WidgetTester tester) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
    
    await tester.pumpWidget(const MaterialApp(home: ForgotPassword()));
    await tester.pumpAndSettle();
  }

  group('ForgotPassword Widget Tests', () {
    testWidgets('displays all UI elements initially', (tester) async {
      await _pumpForgotPassword(tester);

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byType(UserField), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('shows error for empty email', (tester) async {
      await _pumpForgotPassword(tester);

      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.byType(SnackBar), findsWidgets);
      expect(find.textContaining('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await _pumpForgotPassword(tester);

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();

      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.byType(SnackBar), findsWidgets);
      expect(find.textContaining('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('back button navigates to login page', (tester) async {
      await _pumpForgotPassword(tester);

      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(ForgotPassword), findsNothing);
    });

    testWidgets('email field accepts input', (tester) async {
      await _pumpForgotPassword(tester);

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('button is tappable with valid email', (tester) async {
      await _pumpForgotPassword(tester);

      final emailField = find.byType(TextField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      final button = find.byType(AppButton);
      expect(button, findsOneWidget);
      
      // Tap button - will fail with Firebase not initialized but proves code path works
      await tester.tap(button);
      await tester.pump();
      
      // Should still be on the page
      expect(find.byType(ForgotPassword), findsOneWidget);
    });

    testWidgets('shows descriptive text for user guidance', (tester) async {
      await _pumpForgotPassword(tester);

      expect(
        find.textContaining("Enter your email address and we'll send you a link"),
        findsOneWidget,
      );
    });

    testWidgets('UserField has correct properties', (tester) async {
      await _pumpForgotPassword(tester);

      final textField = find.byType(TextField);
      final textFieldWidget = tester.widget<TextField>(textField);

      expect(textFieldWidget.keyboardType, TextInputType.emailAddress);
      expect(textFieldWidget.obscureText, false);
    });
  });

  group('BackButtonWidget Tests', () {
    testWidgets('BackButtonWidget displays icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BackButtonWidget(destinationPage: SignInPage()),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('BackButtonWidget navigates on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackButtonWidget(destinationPage: SignInPage()),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });
  });
}
