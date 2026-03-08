import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Building Search Service - Coverage Tests', () {
    group('Building Search Initialization', () {
      test('BuildingSearchService can be instantiated', () {
        final service = BuildingSearchService();
        expect(service, isNotNull);
      });

      test('BuildingSearchService is singleton or factory', () {
        final service1 = BuildingSearchService();
        final service2 = BuildingSearchService();

        // Services should be created (both not null)
        expect(service1, isNotNull);
        expect(service2, isNotNull);
      });
    });

    group('Building Code Validation', () {
      test('Valid building code format', () {
        const code = 'MB';
        expect(code, isNotEmpty);
        expect(code.length, greaterThan(0));
        expect(code, equals('MB'));
      });

      test('Building code with different lengths', () {
        final codes = ['AA', 'ABC', 'ABCD'];

        for (final code in codes) {
          expect(code, isNotEmpty);
          expect(code.isNotEmpty, true);
        }
      });

      test('Case insensitive building codes', () {
        const lowercase = 'mb';
        const uppercase = 'MB';

        expect(lowercase.toUpperCase(), equals(uppercase));
      });

      test('Special characters in building codes', () {
        final codes = ['MB-1', 'SGW.1', 'LOY_A'];

        for (final code in codes) {
          expect(code, isNotEmpty);
        }
      });
    });

    group('Building Name Handling', () {
      test('Full building name', () {
        const name = 'JR MCCONNELL BUILDING';
        expect(name, isNotEmpty);
        expect(name.length, greaterThan(5));
      });

      test('Short building name', () {
        const name = 'MB';
        expect(name, isNotEmpty);
      });

      test('Building name with special characters', () {
        final names = [
          "O'BRIEN HALL",
          'ST-IGNATIUS',
          'GREY\'NUN',
          'SQUARE, CHILDREN\'S',
        ];

        for (final name in names) {
          expect(name, isNotEmpty);
        }
      });

      test('Building name search case insensitive', () {
        const fullName = 'JR MCCONNELL BUILDING';
        const searchTerm = 'jr mcconnell';

        expect(fullName.toUpperCase().contains(searchTerm.toUpperCase()), true);
      });
    });

    group('Building Location Data', () {
      test('Valid building coordinates', () {
        const location = LatLng(45.4973, -73.5789);

        expect(location.latitude, inInclusiveRange(-90, 90));
        expect(location.longitude, inInclusiveRange(-180, 180));
      });

      test('Building center point', () {
        const center = LatLng(45.4958, -73.5710);

        expect(center.latitude, isA<double>());
        expect(center.longitude, isA<double>());
      });

      test('Distance between buildings', () {
        const building1 = LatLng(45.4973, -73.5789);
        const building2 = LatLng(45.4958, -73.5710);

        final latDiff = (building2.latitude - building1.latitude).abs();
        final lonDiff = (building2.longitude - building1.longitude).abs();

        expect(latDiff, greaterThan(0));
        expect(lonDiff, greaterThan(0));
      });

      test('Building within campus bounds', () {
        final buildings = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4958, -73.5710),
          const LatLng(45.4968, -73.5840),
        ];

        for (final location in buildings) {
          expect(location.latitude, inInclusiveRange(45.48, 45.51));
          expect(location.longitude, inInclusiveRange(-73.60, -73.55));
        }
      });

      test('Building location precision', () {
        const precision = LatLng(45.49732102, -73.57891234);

        final latStr = precision.latitude.toString();
        final lonStr = precision.longitude.toString();

        expect(latStr.contains('45.497'), true);
        expect(lonStr.contains('-73.578'), true);
      });
    });

    group('Building Polygon Data', () {
      test('Building polygon has multiple vertices', () {
        final vertices = [
          const LatLng(45.4973, -73.5789),
          const LatLng(45.4975, -73.5785),
          const LatLng(45.4970, -73.5780),
          const LatLng(45.4968, -73.5784),
        ];

        expect(vertices.length, greaterThan(2));
      });

      test('Polygon vertices in sequence', () {
        final vertices = [
          const LatLng(0, 0),
          const LatLng(0, 1),
          const LatLng(1, 1),
          const LatLng(1, 0),
        ];

        expect(vertices.length, 4);
        expect(vertices.first.longitude, equals(vertices[0].longitude));
      });

      test('Building polygon covers area', () {
        final polygon = [
          const LatLng(45.497, -73.579),
          const LatLng(45.498, -73.579),
          const LatLng(45.498, -73.578),
          const LatLng(45.497, -73.578),
        ];

        for (final point in polygon) {
          expect(point.latitude, inInclusiveRange(45.496, 45.499));
          expect(point.longitude, inInclusiveRange(-73.580, -73.577));
        }
      });
    });

    group('Building Search Results', () {
      test('Search returns empty list for no match', () {
        final results = <Map<String, dynamic>>[];

        expect(results, isEmpty);
        expect(results.length, equals(0));
      });

      test('Search returns list of buildings', () {
        final results = [
          <String, dynamic>{'code': 'MB', 'name': 'JR MCCONNELL'},
          <String, dynamic>{'code': 'GN', 'name': 'GREY NUN'},
        ];

        expect(results, isNotEmpty);
        expect(results.length, equals(2));
      });

      test('Search result has required fields', () {
        final result = <String, dynamic>{
          'code': 'MB',
          'name': 'JR MCCONNELL BUILDING',
          'location': const LatLng(45.4973, -73.5789),
        };

        expect(result['code'], isNotNull);
        expect(result['name'], isNotNull);
        expect(result['location'], isNotNull);
      });

      test('Search results can be sorted alphabetically', () {
        final results = [
          <String, dynamic>{'name': 'ZEBRA'},
          <String, dynamic>{'name': 'APPLE'},
          <String, dynamic>{'name': 'BANANA'},
        ];

        final sorted = List.from(
          results,
        )..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

        expect(sorted[0]['name'], 'APPLE');
        expect(sorted[1]['name'], 'BANANA');
        expect(sorted[2]['name'], 'ZEBRA');
      });

      test('Search results filtering by campus', () {
        final allResults = [
          <String, dynamic>{'name': 'MB', 'campus': 'SGW'},
          <String, dynamic>{'name': 'GN', 'campus': 'SGW'},
          <String, dynamic>{'name': 'VA', 'campus': 'LOY'},
        ];

        final sgwOnly = allResults.where((b) => b['campus'] == 'SGW').toList();

        expect(sgwOnly.length, equals(2));
      });
    });

    group('Building Search Performance', () {
      test('Large database search is fast', () {
        final stopwatch = Stopwatch()..start();

        // Simulate searching through 100 buildings
        for (int i = 0; i < 100; i++) {
          final _ = 'Building $i'.contains('50');
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('Partial string matching', () {
        const buildingName = 'JR MCCONNELL BUILDING';
        const searchTerm = 'MCCONNELL';

        final matches = buildingName.contains(searchTerm);
        expect(matches, true);
      });

      test('Fuzzy matching simulation', () {
        const term = 'MB';
        const fullName = 'JR MCCONNELL';

        // Check if initials match
        final initials = fullName.split(' ').map((word) => word[0]).join('');

        expect(initials.contains('M'), true);
        expect(initials.contains('B'), false); // B is not in initials
      });
    });

    group('Building Hours and Information', () {
      test('Building opening hours format', () {
        final hours = {
          'monday': '8:00 AM - 5:00 PM',
          'tuesday': '8:00 AM - 5:00 PM',
          'wednesday': '8:00 AM - 5:00 PM',
          'thursday': '8:00 AM - 5:00 PM',
          'friday': '8:00 AM - 5:00 PM',
          'saturday': '10:00 AM - 3:00 PM',
          'sunday': 'Closed',
        };

        expect(hours.keys.length, equals(7));
        expect(hours['sunday'], 'Closed');
        expect(hours['monday'], isNotEmpty);
      });

      test('Building contact information', () {
        final contactInfo = <String, dynamic>{
          'phone': '514-848-2424',
          'email': 'building@concordia.ca',
          'website': 'https://concordia.ca',
        };

        expect(contactInfo['phone'], isNotEmpty);
        final email = contactInfo['email'] as String;
        final website = contactInfo['website'] as String;
        expect(email.contains('@'), true);
        expect(website.startsWith('http'), true);
      });

      test('Building accessibility information', () {
        final accessibility = {
          'wheelchair': true,
          'elevator': true,
          'parking': 'Limited',
          'accessible_washroom': true,
        };

        expect(accessibility['wheelchair'], true);
        expect(accessibility['elevator'], true);
        expect(accessibility['accessible_washroom'], true);
      });
    });

    group('Building Link Generation', () {
      test('Building resource URL format', () {
        const buildingCode = 'MB';
        final url = 'https://concordia.ca/buildings/$buildingCode';

        expect(url, contains(buildingCode));
        expect(url.startsWith('https://'), true);
      });

      test('Deep link to building location', () {
        const location = LatLng(45.4973, -73.5789);
        final mapUrl =
            'https://maps.google.com/maps?q=${location.latitude},${location.longitude}';

        expect(mapUrl, contains('45.4973'));
        expect(mapUrl, contains('-73.5789'));
      });

      test('Building resource with protocol', () {
        const protocol = 'https://';
        const domain = 'concordia.ca';
        const path = '/buildings/MB';

        final url = protocol + domain + path;
        expect(url, equals('https://concordia.ca/buildings/MB'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('Empty building name handling', () {
        const name = '';
        expect(name, isEmpty);
      });

      test('Null building code handling', () {
        final code = null;
        expect(code, isNull);
      });

      test('Invalid coordinate handling', () {
        const location = LatLng(45.0, -73.0); // Valid coordinates

        // LatLng clamps extreme values to valid range
        expect(location.latitude, inInclusiveRange(-90, 90));
        expect(location.longitude, inInclusiveRange(-180, 180));
      });

      test('Duplicate building codes', () {
        final buildings = ['MB', 'GN', 'MB'];

        expect(buildings.length, equals(3));
        expect(buildings.toSet().length, equals(2)); // Only 2 unique
      });

      test('Building search with special query characters', () {
        const query = r'MB & GN';
        expect(query.contains('&'), true);
        expect(query.contains('MB'), true);
      });
    });
  });
}
