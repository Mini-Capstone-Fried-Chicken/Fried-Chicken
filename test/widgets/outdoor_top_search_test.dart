import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/shared/widgets/outdoor/outdoor_top_search.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:campus_app/shared/widgets/indoor_floor_dropdown.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';
import 'package:campus_app/data/search_suggestion.dart';

void main() {
  Widget _wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(children: [child]),
      ),
    );
  }

  testWidgets('does NOT show IndoorFloorDropdown when showIndoor=false',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(
        OutdoorTopSearch(
          campusLabel: 'SGW',
          controller: controller,
          onSubmitted: (_) {},
          suggestions: const <SearchSuggestion>[],
          onSuggestionSelected: (_) {},
          onFocus: () {},
          showIndoor: false,
          floors: const <IndoorFloorOption>[
            IndoorFloorOption(
              label: 'Floor 1',
              assetPath: 'assets/floor1.json',
            ),
          ],
          selectedAssetPath: 'assets/floor1.json',
          onFloorChanged: (_) async {},
        ),
      ),
    );

    expect(find.byType(MapSearchBar), findsOneWidget);
    expect(find.byType(IndoorFloorDropdown), findsNothing);
  });

  testWidgets('does NOT show IndoorFloorDropdown when floors is empty',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrap(
        OutdoorTopSearch(
          campusLabel: 'SGW',
          controller: controller,
          onSubmitted: (_) {},
          suggestions: const <SearchSuggestion>[],
          onSuggestionSelected: (_) {},
          onFocus: () {},
          showIndoor: true,
          floors: const <IndoorFloorOption>[],
          selectedAssetPath: null,
          onFloorChanged: (_) async {},
        ),
      ),
    );

    expect(find.byType(MapSearchBar), findsOneWidget);
    expect(find.byType(IndoorFloorDropdown), findsNothing);
  });

  testWidgets(
  'shows IndoorFloorDropdown when showIndoor=true and floors not empty, and calls onFloorChanged',
  (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    String? changedTo;

    const floors = <IndoorFloorOption>[
      IndoorFloorOption(label: 'Floor 1', assetPath: 'assets/floor1.json'),
      IndoorFloorOption(label: 'Floor 2', assetPath: 'assets/floor2.json'),
    ];

    await tester.pumpWidget(
      _wrap(
        OutdoorTopSearch(
          campusLabel: 'SGW',
          controller: controller,
          onSubmitted: (_) {},
          suggestions: const <SearchSuggestion>[],
          onSuggestionSelected: (_) {},
          onFocus: () {},
          showIndoor: true,
          floors: floors,
          selectedAssetPath: 'assets/floor1.json',
          onFloorChanged: (assetPath) async {
            changedTo = assetPath;
          },
        ),
      ),
    );

    expect(find.byType(IndoorFloorDropdown), findsOneWidget);

    final dropdown = tester.widget<IndoorFloorDropdown>(
      find.byType(IndoorFloorDropdown),
    );
    dropdown.onChanged('assets/floor2.json');
    await tester.pump();

    expect(changedTo, equals('assets/floor2.json'));
  },
);
}