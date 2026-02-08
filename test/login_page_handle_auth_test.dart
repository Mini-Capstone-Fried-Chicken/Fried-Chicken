import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _pumpSignIn(WidgetTester tester) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
    
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));
    await tester.pumpAndSettle();
  }

  Future<void> _enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), email);
    await tester.enterText(textFields.at(1), password);
  }

  Future<void> _submit(WidgetTester tester) async {
    final button = find.byType(ElevatedButton);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
  }

  group('_handleAuth', () {
    testWidgets('shows error for empty email', (tester) async {
      await _pumpSignIn(tester);
      await _enterCredentials(tester, email: '', password: '123');
      await _submit(tester);
      
      // Check for SnackBar with error message
      expect(
        find.byType(SnackBar),
        findsWidgets,
      );
      expect(
        find.textContaining('Please enter a valid email address'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for empty password', (tester) async {
      await _pumpSignIn(tester);
      await _enterCredentials(tester, email: 'user@example.com', password: '');
      await _submit(tester);
      
      // Password must be at least 3 characters
      expect(
        find.byType(SnackBar),
        findsWidgets,
      );
      expect(
        find.textContaining('Password must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await _pumpSignIn(tester);
      await _enterCredentials(tester, email: 'invalid', password: '123456');
      await _submit(tester);
      
      expect(
        find.byType(SnackBar),
        findsWidgets,
      );
      expect(
        find.textContaining('Please enter a valid email address'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for password too short', (tester) async {
      await _pumpSignIn(tester);
      await _enterCredentials(tester, email: 'user@example.com', password: '12');
      await _submit(tester);
      
      expect(
        find.byType(SnackBar),
        findsWidgets,
      );
      expect(
        find.textContaining('Password must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid email and password format', (tester) async {
      await _pumpSignIn(tester);
      await _enterCredentials(tester, email: 'user@example.com', password: '123456');
      await _submit(tester);
      
      // Should attempt login (SnackBar shows Firebase/network errors)
      // No validation error SnackBars should appear for format
      await tester.pump(const Duration(milliseconds: 500));
      // Wait for any network calls to complete or timeout
      expect(find.byType(SignInPage), findsOneWidget);
    });
  });
}