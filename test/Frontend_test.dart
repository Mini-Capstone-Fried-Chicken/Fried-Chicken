import 'package:campus_app/features/auth/ui/forgot_password_page.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Welcome Page Tests", () {
    testWidgets("Welcome page displays logo", (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image.toString().contains("logo.png"),
        ),
        findsWidgets,
      );
    });

    testWidgets("Welcome page displays get started button",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      expect(find.text("Get started"), findsOneWidget);
      expect(find.byType(AppButton), findsWidgets);
    });

    testWidgets("Welcome page displays welcome message",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      expect(find.text("Welcome to Campus"), findsOneWidget);
      expect(find.text("your go-to map on campus"), findsOneWidget);
    });

    testWidgets("Get started button is tappable",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      await tester.tap(find.text("Get started"));
      await tester.pump();
    });
  });

  group("Login Page Tests", () {
    testWidgets("Login page displays sign in tab initially",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignInPage(),
        ),
      );

      expect(find.text("Sign In"), findsWidgets);
      expect(find.text("Welcome to Campus"), findsOneWidget);
      expect(find.text("Email address"), findsOneWidget);
      expect(find.text("Password"), findsWidgets);
    });

    testWidgets("Login page toggle switches to sign up mode",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: SignInPage()),
      );

      await tester.tap(find.text("Sign Up").first);
      await tester.pumpAndSettle();

      expect(find.text("Name"), findsOneWidget);
      expect(find.text("Confirm your password"), findsOneWidget);
    });

    testWidgets("Login page displays all form fields for sign in",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: SignInPage()),
      );

      expect(find.byType(UserField), findsWidgets);
    });

    testWidgets("Login page displays logo", (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: SignInPage()),
      );

      expect(find.byType(AppLogo), findsOneWidget);
    });
    testWidgets('Login page displays forgot password button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
  });

  group("Sign Up Page Tests", () {
    testWidgets("Sign up page displays all signup fields",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: SignInPage()),
      );

      await tester.tap(find.text("Sign Up").first);
      await tester.pumpAndSettle();

      expect(find.text("Name"), findsOneWidget);
      expect(find.text("Email address"), findsOneWidget);
      expect(find.text("Confirm your password"), findsOneWidget);
    });
  });

  group("Forgot Password Page Tests", () {
    testWidgets("Forgot password page displays correctly",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: ForgotPassword()),
      );

      expect(find.byType(ForgotPassword), findsOneWidget);
      expect(find.text("Email address"), findsOneWidget);
      expect(find.text("Verify"), findsOneWidget);
    });

    testWidgets("Back button exists",
        (WidgetTester tester) async {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);

      await tester.pumpWidget(
        const MaterialApp(home: ForgotPassword()),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
