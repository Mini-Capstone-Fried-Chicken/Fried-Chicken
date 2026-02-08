import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Interactive map loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(45.4973, -73.5790),
              zoom: 14,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GoogleMap), findsOneWidget);
  });

  group('Map File Import Tests', () {
    test('MB1 floor plan JSON file can be loaded', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      expect(mapData, isNotNull);
      expect(mapData['building'], equals('MB'));
      expect(mapData['floor'], equals('MB1'));
    });

    test('MB1 floor plan has required fields', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      expect(mapData.containsKey('building'), isTrue);
      expect(mapData.containsKey('floor'), isTrue);
      expect(mapData.containsKey('classrooms'), isTrue);
      expect(mapData.containsKey('poi'), isTrue);
      expect(mapData.containsKey('svgWidth'), isTrue);
      expect(mapData.containsKey('svgHeight'), isTrue);
    });

    test('MB1 floor plan classrooms are properly formatted', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final List<dynamic> classrooms = mapData['classrooms'] as List<dynamic>;
      expect(classrooms.isNotEmpty, isTrue);

      for (var classroom in classrooms) {
        expect(classroom.containsKey('name'), isTrue);
        expect(classroom.containsKey('x'), isTrue);
        expect(classroom.containsKey('y'), isTrue);
        expect(classroom['name'], isNotNull);
        expect(classroom['x'], isNotNull);
        expect(classroom['y'], isNotNull);
      }
    });

    test('MB1 floor plan POI are properly formatted', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final List<dynamic> poi = mapData['poi'] as List<dynamic>;
      expect(poi.isNotEmpty, isTrue);

      for (var point in poi) {
        expect(point.containsKey('name'), isTrue);
        expect(point.containsKey('x'), isTrue);
        expect(point.containsKey('y'), isTrue);
      }
    });

    test('Indoor SVG files exist in assets', () async {
      try {
        await rootBundle.loadString('assets/indoor_svg/MB-1.svg');
        expect(true, isTrue); // File exists
      } catch (e) {
        expect(false, isTrue, reason: 'MB1.svg should exist');
      }
    });

    test('All map JSON files are valid JSON format', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');

      expect(() {
        jsonDecode(jsonContent);
      }, returnsNormally);
    });

    test('Floor plan dimensions are valid', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final int svgWidth = mapData['svgWidth'] as int;
      final int svgHeight = mapData['svgHeight'] as int;
      final int refWidth = mapData['refWidth'] as int;
      final int refHeight = mapData['refHeight'] as int;

      expect(svgWidth, greaterThan(0));
      expect(svgHeight, greaterThan(0));
      expect(refWidth, greaterThan(0));
      expect(refHeight, greaterThan(0));
    });

    test('Classroom coordinates are within valid bounds', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final int svgWidth = mapData['svgWidth'] as int;
      final int svgHeight = mapData['svgHeight'] as int;
      final List<dynamic> classrooms = mapData['classrooms'] as List<dynamic>;

      for (var classroom in classrooms) {
        final double x = (classroom['x'] as num).toDouble();
        final double y = (classroom['y'] as num).toDouble();

        expect(x, greaterThanOrEqualTo(0));
        expect(x, lessThanOrEqualTo(svgWidth));
        expect(y, greaterThanOrEqualTo(0));
        expect(y, lessThanOrEqualTo(svgHeight));
      }
    });

    test('POI coordinates are within valid bounds', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final int svgWidth = mapData['svgWidth'] as int;
      final int svgHeight = mapData['svgHeight'] as int;
      final List<dynamic> poi = mapData['poi'] as List<dynamic>;

      for (var point in poi) {
        final double x = (point['x'] as num).toDouble();
        final double y = (point['y'] as num).toDouble();

        expect(x, greaterThanOrEqualTo(0));
        expect(x, lessThanOrEqualTo(svgWidth));
        expect(y, greaterThanOrEqualTo(0));
        expect(y, lessThanOrEqualTo(svgHeight));
      }
    });

    test('Floor plan has unique classroom names', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final List<dynamic> classrooms = mapData['classrooms'] as List<dynamic>;
      final Set<String> names = {};

      for (var classroom in classrooms) {
        final String name = classroom['name'] as String;
        expect(names.contains(name), isFalse,
            reason: 'Duplicate classroom name found: $name');
        names.add(name);
      }
    });

    test('Floor plan has unique POI names', () async {
      final String jsonContent =
          await rootBundle.loadString('assets/json/mb1.json');
      final Map<String, dynamic> mapData = jsonDecode(jsonContent);

      final List<dynamic> poi = mapData['poi'] as List<dynamic>;
      final Set<String> names = {};

      for (var point in poi) {
        final String name = point['name'] as String;
        expect(names.contains(name), isFalse,
            reason: 'Duplicate POI name found: $name');
        names.add(name);
      }
    });
  });
}
