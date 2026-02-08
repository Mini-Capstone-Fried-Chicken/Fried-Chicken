import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:campus_app/app/app_shell.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/explore/ui/explore_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can log in and reach dashboard', (tester) async {

    //runApp(const MaterialApp(home: SignInPage()));
    app.main();

    await tester.pumpAndSettle(const Duration(seconds: 5));

    final emailField = find.byKey(const Key('login_email'));
    final passwordField = find.byKey(const Key('login_password'));
    final loginButton = find.byKey(const Key('login_button'));

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    // Enter login credentials
    await tester.enterText(emailField, 'hiba.tal05@gmail.com');
    await tester.enterText(passwordField, '123');
    await tester.pumpAndSettle();
    await tester.ensureVisible(loginButton);

    // Tap login button
    await tester.tap(loginButton);

    // Wait for navigation / dashboard load
    //await tester.pumpAndSettle(const Duration(seconds: 5));


    await tester.runAsync(() async {
      await Future.delayed(const Duration(seconds: 5));
    });

    await tester.pump();
    
    // Verify dashboard loaded
    expect(find.byType(AppShell), findsOneWidget);
    //expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

  });
}
