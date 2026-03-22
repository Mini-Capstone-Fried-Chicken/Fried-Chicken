import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
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

  Widget buildTestWidget({
    bool originEnabled = true,
    bool destinationEnabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RoomFieldsSection(
          originBuildingCode: 'ORIGIN',
          destinationBuildingCode: 'DEST',
          originRoomController: originController,
          destinationRoomController: destinationController,
          originEnabled: originEnabled,
          destinationEnabled: destinationEnabled,
          onOriginValid: (_, __) => originValidCalled = true,
          onDestinationValid: (_, __) => destinationValidCalled = true,
          onDestinationRoomSubmitted: (_, __) =>
              destinationSubmittedCalled = true,
          indoorRepository: FakeIndoorMapRepository(),
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
}
