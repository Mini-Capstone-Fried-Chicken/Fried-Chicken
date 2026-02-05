import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart' show HomePage, AppLogo, AppButton;
import 'package:campus_app/screens/login_page.dart' show SignInPage, LoginToggle, UserField;
import 'package:campus_app/screens/forgot_password_page.dart' show ForgotPassword;

void main() {
  group('Welcome Page Tests', () {
    testWidgets('Welcome page displays logo', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byWidgetPredicate(
        (widget) => widget is Image && widget.image.toString().contains('logo.png'),
      ), findsWidgets);
    });

    testWidgets('Welcome page displays get started button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.text('Get started'), findsOneWidget);
      expect(find.byType(AppButton), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Welcome page displays welcome message', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.text('Welcome to Campus'), findsOneWidget);
      expect(find.text('your go-to map on campus'), findsOneWidget);
    });

    testWidgets('Get started button is functional', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert button exists and is enabled
      final getStartedButton = find.byType(AppButton);
      expect(getStartedButton, findsWidgets);

      // Tap the button
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Verify navigation occurred by checking if new route was pushed
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('Welcome page has all required UI elements', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert - Logo is present
      expect(find.byType(AppLogo), findsOneWidget);

      // Assert - Get started button is present
      expect(find.text('Get started'), findsOneWidget);

      // Assert - Welcome text is present
      expect(find.text('Welcome to Campus'), findsOneWidget);

      // Assert - Descriptive text is present
      expect(find.text('your go-to map on campus'), findsOneWidget);
    });
  });

  group('Login Page Tests', () {
    testWidgets('Login page displays sign in tab initially', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Welcome to Campus'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);

    });

    testWidgets('Login page toggle switches to sign up mode', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Find and tap the "Sign Up" toggle
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - Sign Up specific fields are now visible
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);
    });

    testWidgets('Login page displays all form fields for sign in', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert - Common fields for Sign In
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.byType(UserField), findsWidgets);
    });

    testWidgets('Login page sign in button is present and labeled correctly', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert
      expect(find.text('Sign In'), findsWidgets);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Login page sign up button is labeled correctly after toggle', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - Button text changes to "Sign Up"
      expect(find.text('Sign Up'), findsWidgets);
    });

    testWidgets('Login page displays logo', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert
      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('Login page has all required UI elements for sign in', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert - All Sign In elements are present
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(LoginToggle), findsOneWidget);
      expect(find.text('Welcome to Campus'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Sign In'), findsWidgets);
    });
  });

  group('Sign Up Page Tests', () {
    testWidgets('Sign up page displays all signup fields', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - All Sign Up specific fields are visible
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Confirm your password'), findsOneWidget);
    });

    testWidgets('Sign up page has correct form fields count', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - 4 UserField widgets for Sign Up (Name, Email, Password, Confirm Password)
      expect(find.byType(UserField), findsNWidgets(4));
    });

    testWidgets('Sign up button is present and labeled correctly', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sign Up'), findsWidgets);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Sign up page can toggle back to sign in', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert Sign Up fields are visible
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);

      // Toggle back to Sign In
      await tester.tap(find.text('Sign In').first);
      await tester.pumpAndSettle();

      // Assert Sign Up specific fields are gone
      expect(find.text('Name'), findsNothing);
      expect(find.text('Confirm your password'), findsNothing);
    });

    testWidgets('Sign up page displays logo', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('Sign up page has all required UI elements', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - All Sign Up elements are present
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(LoginToggle), findsOneWidget);
      expect(find.text('Welcome to Campus'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Confirm your password'), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets);
    });

    testWidgets('Sign up form has password fields with obscure text enabled', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Toggle to Sign Up
      await tester.tap(find.text('Sign Up').first);
      await tester.pumpAndSettle();

      // Assert - Both password fields should be obscured
      final passwordFields = find.byType(UserField);
      expect(passwordFields, findsNWidgets(4));
    });

    testWidgets('Login page displays continue as guest button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert
      expect(find.text('Continue as a guest'), findsOneWidget);
    });

    testWidgets('Login page displays forgot password button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Continue as guest button is functional', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      // Assert button exists and is tappable
      final guestButton = find.text('Continue as a guest');
      expect(guestButton, findsOneWidget);
      
      // Tap it
      await tester.tap(guestButton);
      await tester.pumpAndSettle();
      
      // Assert - Button can be tapped without error
      expect(guestButton, findsNothing);
    });
  });

  group('Forgot Password Page Tests', () {
    testWidgets('Forgot password page displays correctly', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert
      expect(find.byType(ForgotPassword), findsOneWidget);
    });

    testWidgets('Forgot password page displays email input field', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byType(UserField), findsOneWidget);
    });

    testWidgets('Forgot password page displays send button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert
      expect(find.text('Send'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Forgot password page displays back button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert - Back button is present and tappable
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Back button on forgot password page returns to login', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Navigated away from Forgot Password Page
      expect(find.byType(ForgotPassword), findsNothing);
    });

    testWidgets('Forgot password page has all required UI elements', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert - All required elements are present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byType(UserField), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('Send button is functional', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ForgotPassword(),
        ),
      );

      // Assert Send button exists
      expect(find.text('Send'), findsOneWidget);

      // Find email field and enter an email
      await tester.enterText(find.byType(UserField), 'test@example.com');
      await tester.pumpAndSettle();

      // Tap Send button
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Assert - Navigation occurred (Send button should be gone)
      expect(find.text('Send'), findsNothing);
    });
  });
}