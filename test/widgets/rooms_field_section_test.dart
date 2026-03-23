import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
import 'package:campus_app/services/indoors_routing/core/indoor_route_plan_models.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeIndoorMapRepository extends IndoorMapRepository {
  @override
  Future<bool> roomExists(String buildingCode, String room) async {
    return room == '101';
  }
}

void main() {
  late TextEditingController originController;
  late TextEditingController destinationController;
  late bool originValidCalled;
  late bool destinationValidCalled;
  late bool destinationSubmittedCalled;
  IndoorTransitionMode? selectedMode;

  Widget buildTestWidget({
    bool originEnabled = true,
    bool destinationEnabled = true,
    String originBuildingCode = 'ORIGIN',
    String destinationBuildingCode = 'DEST',
    bool wheelchairRoutingDefaultEnabled = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RoomFieldsSection(
          originBuildingCode: originBuildingCode,
          destinationBuildingCode: destinationBuildingCode,
          originRoomController: originController,
          destinationRoomController: destinationController,
          originEnabled: originEnabled,
          destinationEnabled: destinationEnabled,
          onOriginValid: (_, __) => originValidCalled = true,
          onDestinationValid: (_, __) => destinationValidCalled = true,
          onDestinationRoomSubmitted: (_, __) =>
              destinationSubmittedCalled = true,
          indoorRepository: FakeIndoorMapRepository(),
          selectedTransitionMode: selectedMode,
          onTransitionModeChanged: (mode) => selectedMode = mode,
          wheelchairRoutingDefaultEnabled: wheelchairRoutingDefaultEnabled,
        ),
      ),
    );
  }

  setUp(() {
    originController = TextEditingController();
    destinationController = TextEditingController();
    originValidCalled = false;
    destinationValidCalled = false;
    destinationSubmittedCalled = false;
    selectedMode = null;
  });

  testWidgets('Invalid origin room clears input', (tester) async {
    await tester.pumpWidget(buildTestWidget(originEnabled: true));
    await tester.enterText(find.byType(TextField).first, '999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(originController.text, '');
    expect(originValidCalled, isFalse);
  });

  testWidgets('Valid origin room keeps input and triggers callback', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(originEnabled: true));
    await tester.enterText(find.byType(TextField).first, '101');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(originController.text, '101');
    expect(originValidCalled, isTrue);
  });

  testWidgets(
    'Invalid destination room clears input and does not call callbacks',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(destinationEnabled: true));
      await tester.enterText(find.byType(TextField).last, '999');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(destinationController.text, '');
      expect(destinationValidCalled, isFalse);
      expect(destinationSubmittedCalled, isFalse);
    },
  );

  testWidgets('Valid destination room keeps input and calls callbacks', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(destinationEnabled: true));
    await tester.enterText(find.byType(TextField).last, '101');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(destinationController.text, '101');
    expect(destinationValidCalled, isTrue);
    expect(destinationSubmittedCalled, isTrue);
  });

  testWidgets('disabled origin room clears input', (tester) async {
    await tester.pumpWidget(buildTestWidget(originEnabled: false));
    await tester.enterText(find.byType(TextField).first, '101');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(originController.text, '');
  });

  testWidgets('Initial validity state is respected', (tester) async {
    final originController = TextEditingController(text: '101');
    final destinationController = TextEditingController(text: '101');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomFieldsSection(
            originBuildingCode: 'ORIGIN',
            destinationBuildingCode: 'DEST',
            originRoomController: originController,
            destinationRoomController: destinationController,
            originEnabled: true,
            destinationEnabled: true,
            initialOriginValid: true,
            initialDestinationValid: true,
            indoorRepository: FakeIndoorMapRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });

  testWidgets('shows floor transition selector for same-building routing', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(originBuildingCode: 'H', destinationBuildingCode: 'h'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Switch floors by'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Elevator'), findsOneWidget);
  });

  testWidgets('selecting elevator notifies parent state', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(originBuildingCode: 'H', destinationBuildingCode: 'H'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Elevator'));
    await tester.pumpAndSettle();

    expect(selectedMode, IndoorTransitionMode.elevator);
  });

  testWidgets('wheelchair routing disables stairs selection', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        originBuildingCode: 'H',
        destinationBuildingCode: 'H',
        wheelchairRoutingDefaultEnabled: true,
      ),
    );
    await tester.pumpAndSettle();

    final stairsChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Stairs'),
    );
    final elevatorChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Elevator'),
    );

    expect(stairsChip.onSelected, isNull);
    expect(elevatorChip.selected, isTrue);
  });
}
