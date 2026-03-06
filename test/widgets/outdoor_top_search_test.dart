import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/shared/widgets/outdoor/outdoor_top_search.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:campus_app/shared/widgets/indoor_floor_dropdown.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart';
import 'package:campus_app/data/search_suggestion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(children: [child]),
      ),
    );
  }

  group('OutdoorTopSearch', () {
    late TextEditingController searchController;
    late TextEditingController originRoomController;
    late TextEditingController destinationRoomController;

    setUp(() {
      searchController = TextEditingController();
      originRoomController = TextEditingController();
      destinationRoomController = TextEditingController();
    });

    tearDown(() {
      searchController.dispose();
      originRoomController.dispose();
      destinationRoomController.dispose();
    });

    testWidgets('renders MapSearchBar', (tester) async {
      await tester.pumpWidget(
        wrap(
          OutdoorTopSearch(
            campusLabel: 'SGW',
            controller: searchController,
            onSubmitted: (_) {},
            suggestions: const <SearchSuggestion>[],
            onSuggestionSelected: (_) {},
            onFocus: () {},
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
            onOriginRoomSubmitted: (_, __) {},
            onDestinationRoomSubmitted: (_, __) {},
            selectedBuildingCode: null,
            currentBuildingCode: null,
            userLocation: const LatLng(45.4973, -73.5789),
            isConcordiaBuilding: (_) => false,
            showIndoor: false,
            floors: const <IndoorFloorOption>[],
            selectedAssetPath: null,
            onFloorChanged: (_) async {},
          ),
        ),
      );

      expect(find.byType(MapSearchBar), findsOneWidget);
      expect(find.byKey(const Key('destination_search_bar')), findsOneWidget);
      expect(find.byType(IndoorFloorDropdown), findsNothing);
    });

    testWidgets('shows dropdown when indoor is visible and floors exist', (
      tester,
    ) async {
      const floors = <IndoorFloorOption>[
        IndoorFloorOption(
          label: 'Floor 1',
          assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
        ),
      ];

      await tester.pumpWidget(
        wrap(
          OutdoorTopSearch(
            campusLabel: 'SGW',
            controller: searchController,
            onSubmitted: (_) {},
            suggestions: const <SearchSuggestion>[],
            onSuggestionSelected: (_) {},
            onFocus: () {},
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
            onOriginRoomSubmitted: (_, __) {},
            onDestinationRoomSubmitted: (_, __) {},
            selectedBuildingCode: 'HALL',
            currentBuildingCode: 'HALL',
            userLocation: const LatLng(45.4973, -73.5789),
            isConcordiaBuilding: (_) => true,
            showIndoor: true,
            floors: floors,
            selectedAssetPath: floors.first.assetPath,
            onFloorChanged: (_) async {},
          ),
        ),
      );

      expect(find.byType(MapSearchBar), findsOneWidget);
      expect(find.byType(IndoorFloorDropdown), findsOneWidget);
    });

    testWidgets('hides dropdown when floors list is empty', (tester) async {
      await tester.pumpWidget(
        wrap(
          OutdoorTopSearch(
            campusLabel: 'SGW',
            controller: searchController,
            onSubmitted: (_) {},
            suggestions: const <SearchSuggestion>[],
            onSuggestionSelected: (_) {},
            onFocus: () {},
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
            onOriginRoomSubmitted: (_, __) {},
            onDestinationRoomSubmitted: (_, __) {},
            selectedBuildingCode: null,
            currentBuildingCode: null,
            userLocation: const LatLng(45.4973, -73.5789),
            isConcordiaBuilding: (_) => false,
            showIndoor: true,
            floors: const <IndoorFloorOption>[],
            selectedAssetPath: null,
            onFloorChanged: (_) async {},
          ),
        ),
      );

      expect(find.byType(IndoorFloorDropdown), findsNothing);
    });

    testWidgets('calls onFloorChanged when dropdown callback is triggered', (
      tester,
    ) async {
      const floors = <IndoorFloorOption>[
        IndoorFloorOption(
          label: 'Floor 1',
          assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
        ),
        IndoorFloorOption(
          label: 'Floor 2',
          assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json',
        ),
      ];

      String? changedTo;

      await tester.pumpWidget(
        wrap(
          OutdoorTopSearch(
            campusLabel: 'SGW',
            controller: searchController,
            onSubmitted: (_) {},
            suggestions: const <SearchSuggestion>[],
            onSuggestionSelected: (_) {},
            onFocus: () {},
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
            onOriginRoomSubmitted: (_, __) {},
            onDestinationRoomSubmitted: (_, __) {},
            selectedBuildingCode: 'HALL',
            currentBuildingCode: 'HALL',
            userLocation: const LatLng(45.4973, -73.5789),
            isConcordiaBuilding: (_) => true,
            showIndoor: true,
            floors: floors,
            selectedAssetPath: floors.first.assetPath,
            onFloorChanged: (assetPath) async {
              changedTo = assetPath;
            },
          ),
        ),
      );

      final dropdown = tester.widget<IndoorFloorDropdown>(
        find.byType(IndoorFloorDropdown),
      );

      dropdown.onChanged(floors[1].assetPath);
      await tester.pump();

      expect(changedTo, floors[1].assetPath);
    });
  });
}