import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/app/campus_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CampusApp Widget Tests', () {
    test('CampusApp is a StatefulWidget', () {
      const app = CampusApp();
      expect(app, isA<StatefulWidget>());

      final state = app.createState();
      expect(state, isNotNull);
      expect(state.runtimeType.toString(), contains('CampusAppState'));
    });

    test('CampusApp createState method returns proper state instance', () {
      const app = CampusApp();

      final state1 = app.createState();
      final state2 = app.createState();
      final state3 = app.createState();

      expect(state1, isNotNull);
      expect(state2, isNotNull);
      expect(state3, isNotNull);

      // Verify each call creates a new instance
      expect(state1, isNot(same(state2)));
      expect(state2, isNot(same(state3)));
      expect(state1, isNot(same(state3)));
    });


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

    test('CampusApp state has correct runtimeType', () {
      // Verify the state type matches expected class name
      const app = CampusApp();
      final state = app.createState();

      expect(state.runtimeType.toString(), contains('CampusAppState'));
    });
  });
}
