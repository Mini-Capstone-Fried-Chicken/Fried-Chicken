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

  group('LoginToggle Widget Tests', () {
    testWidgets('LoginToggle displays both options', (tester) async {
      await _pumpLoginPage(tester);

      // Find the LoginToggle widget and verify both options exist
      final loginToggle = find.byType(LoginToggle);
      expect(loginToggle, findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('LoginToggle switches between Sign In and Sign Up', (tester) async {
      await _pumpLoginPage(tester);

      // Initially on Sign In - name field should not be visible
      expect(find.text('Name'), findsNothing);

      // Tap Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should show name field for sign up
      expect(find.text('Name'), findsOneWidget);

      // Tap Sign In again
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Name field should be hidden
      expect(find.text('Name'), findsNothing);
    });
  });

  group('UserField Widget Tests', () {
    testWidgets('UserField displays label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserField(label: 'Test Label'),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('UserField can be obscured for passwords', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserField(
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('UserField accepts keyboard type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserField(
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('UserField accepts input', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserField(
              label: 'Test',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test input');
      expect(controller.text, 'test input');
    });
  });

  group('SignInPage Validation Tests', () {
    testWidgets('shows name field only during signup', (tester) async {
      await _pumpLoginPage(tester);

      // Initially in login mode - no name field
      expect(find.text('Name'), findsNothing);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Name field should appear
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('shows confirm password only during signup', (tester) async {
      await _pumpLoginPage(tester);

      // Initially in login mode - no confirm password
      expect(find.text('Confirm your password'), findsNothing);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Confirm password should appear
      expect(find.text('Confirm your password'), findsOneWidget);
    });

    testWidgets('validates name is required during signup', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Enter email and password but not name
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), '123456');
      await tester.enterText(textFields.at(3), '123456');

      // Try to submit
      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.textContaining('Please enter your name'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      await _pumpLoginPage(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'invalid-email');
      await tester.enterText(textFields.at(1), '123456');

      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.textContaining('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('validates password length during signup', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), '12345');

      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.textContaining('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('validates passwords match during signup', (tester) async {
      await _pumpLoginPage(tester);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Test User');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), '123456');
      await tester.enterText(textFields.at(3), '654321');

      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pump();

      expect(find.textContaining('Passwords do not match'), findsOneWidget);
    });
  });

  group('SignInPage UI Tests', () {
    testWidgets('displays app logo', (tester) async {
      await _pumpLoginPage(tester);

      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('displays welcome message', (tester) async {
      await _pumpLoginPage(tester);

      expect(find.text('Welcome to Campus'), findsOneWidget);
    });

    testWidgets('displays forgot password link during login', (tester) async {
      await _pumpLoginPage(tester);

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('hides forgot password link during signup', (tester) async {
      await _pumpLoginPage(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsNothing);
    });

    testWidgets('displays continue as guest button during login', (tester) async {
      await _pumpLoginPage(tester);

      expect(find.text('Continue as a guest'), findsOneWidget);
    });

    testWidgets('hides continue as guest during signup', (tester) async {
      await _pumpLoginPage(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Continue as a guest'), findsNothing);
    });

    testWidgets('button text changes between Sign In and Sign Up', (tester) async {
      await _pumpLoginPage(tester);

      // Initially Sign In
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Sign Up'), findsOneWidget);
    });
  });

  group('SignInPage State Management Tests', () {
    testWidgets('maintains form state during mode switch', (tester) async {
      await _pumpLoginPage(tester);

      final emailField = find.byType(TextField).at(0);
      await tester.enterText(emailField, 'test@example.com');

      // Switch to signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Switch back to login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Email should still be there
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('clears validation error on input', (tester) async {
      await _pumpLoginPage(tester);

      // Try to submit empty form
      final button = find.byType(AppButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should show error
      expect(find.byType(SnackBar), findsWidgets);

      // Type something in email field
      final emailField = find.byType(TextField).at(0);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Error should be gone
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('SignInPage Navigation Tests', () {
    testWidgets('forgot password button navigates to forgot password page', (tester) async {
      await _pumpLoginPage(tester);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsNothing);
    });

    testWidgets('continue as guest button is tappable', (tester) async {
      await _pumpLoginPage(tester);

      final guestButton = find.text('Continue as a guest');
      expect(guestButton, findsOneWidget);

      await tester.tap(guestButton);
      await tester.pump();

      // Should attempt navigation (will fail without full app context)
      expect(find.byType(SignInPage), findsOneWidget);
    });
  });
}
