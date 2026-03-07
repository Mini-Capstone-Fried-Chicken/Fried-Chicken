import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_app/features/indoor/ui/pages/indoor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String svgAsset = '''
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <rect x="0" y="0" width="100" height="100" fill="white"/>
</svg>
''';

  Future<void> mockAssets(Map<String, String> assets) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          if (message == null) return null;

          final key = utf8.decode(message.buffer.asUint8List());

          if (!assets.containsKey(key)) {
            return null;
          }

          final bytes = Uint8List.fromList(utf8.encode(assets[key]!));
          return ByteData.view(bytes.buffer);
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  Widget makeTestable(Widget child) {
    return MaterialApp(home: child);
  }

  group('IndoorPage widget tests', () {
    testWidgets(
      'renders page and opens fallback building info when JSON does not exist',
      (tester) async {
        await mockAssets({'assets/maps/test_floor.svg': svgAsset});

        await tester.pumpWidget(
          makeTestable(
            const IndoorPage(
              id: 'ZZ-1',
              assetPath: 'assets/maps/test_floor.svg',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('indoor_page')), findsOneWidget);
        expect(find.text('Indoor Map - ZZ-1'), findsOneWidget);
        expect(find.byKey(const Key('indoor_map_stack')), findsOneWidget);

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('building_bottomsheet_title')),
          findsOneWidget,
        );
        expect(find.text('ZZ'), findsOneWidget);
        expect(find.text('No description yet.'), findsOneWidget);
        expect(find.text('Campus: Unknown'), findsOneWidget);
        expect(find.text('Floors: N/A'), findsOneWidget);
      },
    );

    testWidgets(
      'loads JSON markers and shows room bottom sheet when marker is tapped',
      (tester) async {
        await mockAssets({
          'assets/maps/test_floor.svg': svgAsset,
          'assets/json/mb1.json': jsonEncode({
            'building': 'MB',
            'refWidth': 1000,
            'refHeight': 1000,
            'svgWidth': 1000,
            'svgHeight': 1000,
            'classrooms': [
              {'name': 'MB-101', 'x': 200, 'y': 300},
            ],
            'poi': [
              {'name': 'Elevator', 'x': 500, 'y': 600},
            ],
          }),
        });

        await tester.pumpWidget(
          makeTestable(
            const IndoorPage(
              id: 'MB-1',
              assetPath: 'assets/maps/test_floor.svg',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('marker_MB-101')), findsOneWidget);
        expect(find.byKey(const Key('marker_Elevator')), findsOneWidget);

        await tester.tap(find.byKey(const Key('marker_MB-101')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('room_bottomsheet_text')), findsOneWidget);
        expect(find.text('MB-101'), findsOneWidget);
      },
    );

    testWidgets(
      'shows building info when map is tapped and JSON building field exists',
      (tester) async {
        await mockAssets({
          'assets/maps/test_floor.svg': svgAsset,
          'assets/json/hall8.json': jsonEncode({
            'building': 'HALL',
            'refWidth': 1200,
            'refHeight': 800,
            'svgWidth': 1200,
            'svgHeight': 800,
            'classrooms': [],
            'poi': [],
          }),
        });

        await tester.pumpWidget(
          makeTestable(
            const IndoorPage(
              id: 'Hall-8',
              assetPath: 'assets/maps/test_floor.svg',
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('building_bottomsheet_title')),
          findsOneWidget,
        );
      },
    );

    testWidgets('wraps content in Transform when flipHorizontally is true', (
      tester,
    ) async {
      await mockAssets({
        'assets/maps/test_floor.svg': svgAsset,
        'assets/json/lb2.json': jsonEncode({
          'building': 'LB',
          'refWidth': 1000,
          'refHeight': 1000,
          'svgWidth': 1000,
          'svgHeight': 1000,
          'flipHorizontally': true,
          'classrooms': [
            {'name': 'LB-201', 'x': 100, 'y': 100},
          ],
          'poi': [],
        }),
      });

      await tester.pumpWidget(
        makeTestable(
          const IndoorPage(id: 'LB-2', assetPath: 'assets/maps/test_floor.svg'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Transform), findsWidgets);
      expect(find.byKey(const Key('marker_LB-201')), findsOneWidget);
    });
  });
}
