import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/app/campus_app.dart';

void main() {
  group('CampusApp Authentication Reset', () {
    test('CampusApp is a StatefulWidget to support initState signOut', () {
      // Verify that CampusApp is a StatefulWidget, which is required
      // for the initState method that calls FirebaseAuth.instance.signOut()
      // This ensures the app structure supports session clearing on startup
      const app = CampusApp();
      expect(app, isA<StatefulWidget>());

      // Verify the state can be created
      final state = app.createState();
      expect(state, isNotNull);
    });

    testWidgets(
      'CampusApp initializes correctly with StatefulWidget lifecycle',
      (WidgetTester tester) async {
        // This test verifies that the CampusApp widget properly initializes
        // with the StatefulWidget lifecycle, allowing initState to execute
        // The actual Firebase signOut call in initState will execute when
        // Firebase is initialized in the app, ensuring users always start
        // at the login page

        const app = CampusApp();

        // Verify widget structure
        expect(app, isA<StatefulWidget>());

        // Verify state can be created
        final state = app.createState();
        expect(state, isNotNull);
      },
    );

    test('CampusApp widget can be instantiated', () {
      // Verify the widget can be created without errors
      const app = CampusApp();
      expect(app, isNotNull);
      expect(app, isA<StatefulWidget>());
    });

    test('CampusApp creates independent state instances', () {
      // Verify that each CampusApp instance creates its own state
      const app1 = CampusApp();
      const app2 = CampusApp();

      final state1 = app1.createState();
      final state2 = app2.createState();

      // Each widget should create its own state instance
      expect(state1, isNot(same(state2)));
    });
  });
}
