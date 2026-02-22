import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

//  run using:
// flutter run integration_test/us_5_1_indoor_map_test.dart -d R5CWA1BZZSE 
  testWidgets('US-5.1 Indoor Map loads correctly',
      (WidgetTester tester) async {

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // find the continue as guest button on the login screen
    final continueAsGuestButton = find.byKey(const Key('continue_as_guest_button'));
    // tap 
    //await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    //await tester.pumpAndSettle();
    await tester.tap(continueAsGuestButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    //final guestButton = find.text('Continue as Guest');
    //expect(guestButton, findsOneWidget);

    // Skip permission dialog if present
    final allowButton = find.text('Allow');
    if (allowButton.evaluate().isNotEmpty) {
      await tester.tap(allowButton);
      await tester.pumpAndSettle();
    }

  });
}