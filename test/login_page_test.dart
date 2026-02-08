import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';

void main() {
  group('LoginToggle', () {
    testWidgets('calls onLoginTap and onSignupTap', (tester) async {
      bool loginTapped = false;
      bool signupTapped = false;
      await tester.pumpWidget(MaterialApp(
        home: LoginToggle(
          isLogin: true,
          onLoginTap: () => loginTapped = true,
          onSignupTap: () => signupTapped = true,
        ),
      ));
      // Tap Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      expect(signupTapped, isTrue);
      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(loginTapped, isTrue);
    });
  });

  group('UserField', () {
    testWidgets('renders label and accepts input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UserField(label: 'Test Label', controller: controller),
        ),
      ));
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hello');
      expect(controller.text, 'hello');
    });
  });
}
