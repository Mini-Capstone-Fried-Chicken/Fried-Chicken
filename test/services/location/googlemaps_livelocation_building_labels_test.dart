import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/data/building_polygons.dart';

Future<dynamic> pumpPageAndGetState(
  WidgetTester tester, {
  Campus initialCampus = Campus.sgw,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OutdoorMapPage(
        initialCampus: initialCampus,
        isLoggedIn: false,
        debugDisableMap: true,
        debugDisableLocation: true,
      ),
    ),
  );

  await tester.pumpAndSettle();
  return tester.state(find.byType(OutdoorMapPage));
}

BuildingPolygon get hallBuilding {
  return buildingPolygons.firstWhere(
    (b) => b.code.toUpperCase() == 'H',
    orElse: () => buildingPolygons.firstWhere(
      (b) => b.name.toUpperCase().contains('HALL'),
    ),
  );
}

BuildingPolygon get lbBuilding {
  return buildingPolygons.firstWhere((b) => b.code.toUpperCase() == 'LB');
}

BuildingPolygon get sgwBuilding {
  return buildingPolygons.firstWhere(
    (b) => detectCampus(b.center) == Campus.sgw,
  );
}

BuildingPolygon get loyolaBuilding {
  return buildingPolygons.firstWhere(
    (b) => detectCampus(b.center) == Campus.loyola,
  );
}

void main() {
  group('Building label helpers', () {
    testWidgets('getBuildingLabel returns uppercase non-empty text', (
      tester,
    ) async {
      final dynamic state = await pumpPageAndGetState(tester);

      final label = state.getBuildingLabel(hallBuilding) as String;

      expect(label, isNotEmpty);
      expect(label, equals(label.toUpperCase()));
    });

    testWidgets('LB label uses building code', (tester) async {
      final dynamic state = await pumpPageAndGetState(tester);

      final label = state.getBuildingLabel(lbBuilding) as String;

      expect(label, isNotEmpty);
      expect(label, equals(label.toUpperCase()));
      expect(label, equals(lbBuilding.code.toUpperCase()));
    });

    testWidgets(
      'getBuildingLabel strips generic words like BUILDING/PAVILION',
      (tester) async {
        final dynamic state = await pumpPageAndGetState(tester);

        final label = state.getBuildingLabel(hallBuilding) as String;

        expect(label.contains('BUILDING'), isFalse);
        expect(label.contains('PAVILION'), isFalse);
      },
    );

    testWidgets(
      'shouldShowBuildingLabel keeps only SGW buildings on SGW campus',
      (tester) async {
        final dynamic state = await pumpPageAndGetState(
          tester,
          initialCampus: Campus.sgw,
        );

        expect(state.shouldShowBuildingLabel(sgwBuilding), isTrue);
        expect(state.shouldShowBuildingLabel(loyolaBuilding), isFalse);
      },
    );

    testWidgets(
      'shouldShowBuildingLabel keeps only Loyola buildings on Loyola campus',
      (tester) async {
        final dynamic state = await pumpPageAndGetState(
          tester,
          initialCampus: Campus.loyola,
        );

        expect(state.shouldShowBuildingLabel(loyolaBuilding), isTrue);
        expect(state.shouldShowBuildingLabel(sgwBuilding), isFalse);
      },
    );

    testWidgets('addBuildingLabelMarkers adds building label markers', (
      tester,
    ) async {
      final dynamic state = await pumpPageAndGetState(
        tester,
        initialCampus: Campus.sgw,
      );

      await state.initBuildingLabelIcons();

      final markers = <Marker>{};
      state.addBuildingLabelMarkers(markers);

      expect(markers, isNotEmpty);
      expect(
        markers.every((m) => m.markerId.value.startsWith('building_label_')),
        isTrue,
      );
    });

    testWidgets('building label markers are created for current campus only', (
      tester,
    ) async {
      final dynamic state = await pumpPageAndGetState(
        tester,
        initialCampus: Campus.sgw,
      );

      await state.initBuildingLabelIcons();

      final markers = <Marker>{};
      state.addBuildingLabelMarkers(markers);

      expect(
        markers.any(
          (m) => m.markerId.value == 'building_label_${sgwBuilding.code}',
        ),
        isTrue,
      );
    });
  });
}
