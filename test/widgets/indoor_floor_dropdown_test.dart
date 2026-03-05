import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/shared/widgets/indoor_floor_dropdown.dart';
import 'package:campus_app/services/indoor_maps/indoor_floor_config.dart'; 

void main() {
  testWidgets('IndoorFloorDropdown shows items and calls onChanged',
      (tester) async {
    final floors = <IndoorFloorOption>[
      const IndoorFloorOption(label: 'Floor 1', assetPath: 'assets/f1.geojson'),
      const IndoorFloorOption(label: 'Floor 2', assetPath: 'assets/f2.geojson'),
    ];

    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndoorFloorDropdown(
            visible: true,
            floors: floors,
            selectedAssetPath: floors.first.assetPath,
            onChanged: (asset) {
              selected = asset;
            },
          ),
        ),
      ),
    );

    expect(find.byType(IndoorFloorDropdown), findsOneWidget);

    await tester.tap(find.text('Floor 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Floor 2').last);
    await tester.pumpAndSettle();

    expect(selected, equals('assets/f2.geojson'));
  });
}