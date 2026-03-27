import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  await tester.pump();
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

    testWidgets('Hall label is uppercase and readable', (tester) async {
      final dynamic state = await pumpPageAndGetState(tester);

      final label = state.getBuildingLabel(hallBuilding) as String;

      expect(label, isNotEmpty);
      expect(label, equals(label.toUpperCase()));
    });

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
  });
}
