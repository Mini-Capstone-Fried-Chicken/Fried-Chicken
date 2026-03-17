import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/services/indoor_maps/indoor_map_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FakeIndoorMapRepository extends IndoorMapRepository {
  Map<String, List<String>> validRooms = {};

  FakeIndoorMapRepository({Map<String, List<String>>? initialRooms}) {
    if (initialRooms != null) validRooms = initialRooms;
  }

  @override
  Future<List<String>> getRoomCodesForBuilding(String buildingCode) async =>
      validRooms[buildingCode.toUpperCase()] ?? [];

  @override
  Future<LatLng?> getRoomLocation(String buildingCode, String roomCode) async {
    // Stub location for tests
    return const LatLng(0, 0);
  }

  @override
  Future<bool> roomExists(String buildingCode, String roomCode) async {
    final rooms = validRooms[buildingCode.toUpperCase()] ?? [];
    return rooms.contains(roomCode.toUpperCase());
  }

  @override
  List<String> getAssetPathsForBuilding(String buildingCode) => [];

  @override
  Future<Map<String, dynamic>> loadGeoJsonAsset(String assetPath) async => {};
}

void main() {
  group('RoutePreviewPanel Widget Tests', () {
    late List<SearchSuggestion> originSuggestions;
    late List<SearchSuggestion> destinationSuggestions;
    late TextEditingController originRoomController;
    late TextEditingController destinationRoomController;
    late FakeIndoorMapRepository indoorRepository;

    setUp(() {
      originSuggestions = [
        SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
        SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[1]),
      ];

      destinationSuggestions = [
        SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[2]),
        SearchSuggestion.fromGooglePlace(
          name: 'Test Place',
          subtitle: 'Test Address',
          placeId: 'test_id',
        ),
      ];
      originRoomController = TextEditingController();
      destinationRoomController = TextEditingController();
      indoorRepository = FakeIndoorMapRepository(
        initialRooms: {
          'HALL': ['101', '102'],
          'VE': ['201', '202'],
        },
      );
      originRoomController.clear();
      destinationRoomController.clear();
    });

    tearDown(() {
      originRoomController.dispose();
      destinationRoomController.dispose();
    });

    testWidgets('RoutePreviewPanel displays with initial text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Current location',
              destinationText: 'Hall Building - HALL',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      expect(find.text('Current location'), findsOneWidget);
      expect(find.text('Hall Building - HALL'), findsOneWidget);
    });

    testWidgets('RoutePreviewPanel shows my_location and place icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Current location',
              destinationText: 'Hall Building',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('Close button calls onClose callback', (
      WidgetTester tester,
    ) async {
      var closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Current location',
              destinationText: 'Hall Building',
              onClose: () => closeCalled = true,
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closeCalled, isTrue);
    });

    testWidgets('Switch button calls onSwitch callback', (
      WidgetTester tester,
    ) async {
      var switchCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Current location',
              destinationText: 'Hall Building',
              onClose: () {},
              onSwitch: () => switchCalled = true,
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      expect(switchCalled, isTrue);
    });

    testWidgets('Typing in origin field calls onOriginChanged', (
      WidgetTester tester,
    ) async {
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (text) => changedText = text,
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Find the origin text field by its hint text
      final originField = find.widgetWithText(TextField, 'Starting location');
      await tester.tap(originField);
      await tester.enterText(originField, 'Hall Building');
      await tester.pumpAndSettle();

      expect(changedText, 'Hall Building');
    });

    testWidgets('Typing in destination field calls onDestinationChanged', (
      WidgetTester tester,
    ) async {
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (text) => changedText = text,
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Find the destination text field by its hint text
      final destField = find.widgetWithText(TextField, 'Choose destination');
      await tester.tap(destField);
      await tester.enterText(destField, 'EV Building');
      await tester.pumpAndSettle();

      expect(changedText, 'EV Building');
    });

    testWidgets('Origin suggestions appear when origin field is focused', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: originSuggestions,
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Tap on origin field to focus
      final originField = find.widgetWithText(TextField, 'Starting location');
      await tester.tap(originField);
      await tester.pumpAndSettle();

      // Verify suggestions appear
      expect(find.text(originSuggestions[0].name), findsOneWidget);
      expect(find.text(originSuggestions[1].name), findsOneWidget);
    });

    testWidgets(
      'Destination suggestions appear when destination field is focused',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoutePreviewPanel(
                originText: '',
                destinationText: '',
                onClose: () {},
                onSwitch: () {},
                onOriginChanged: (_) {},
                onDestinationChanged: (_) {},
                onOriginSelected: (_) {},
                onDestinationSelected: (_) {},
                originSuggestions: const [],
                destinationSuggestions: destinationSuggestions,
                originRoomController: originRoomController,
                destinationRoomController: destinationRoomController,
              ),
            ),
          ),
        );

        // Tap on destination field to focus
        final destField = find.widgetWithText(TextField, 'Choose destination');
        await tester.tap(destField);
        await tester.pumpAndSettle();

        // Verify suggestions appear
        expect(find.text(destinationSuggestions[0].name), findsOneWidget);
        expect(find.text('Test Place'), findsOneWidget);
      },
    );

    testWidgets('Selecting origin suggestion calls onOriginSelected', (
      WidgetTester tester,
    ) async {
      SearchSuggestion? selectedSuggestion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (suggestion) => selectedSuggestion = suggestion,
              onDestinationSelected: (_) {},
              originSuggestions: originSuggestions,
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Focus origin field
      final originField = find.widgetWithText(TextField, 'Starting location');
      await tester.tap(originField);
      await tester.pumpAndSettle();

      // Tap on first suggestion
      await tester.tap(find.text(originSuggestions[0].name));
      await tester.pumpAndSettle();

      expect(selectedSuggestion, isNotNull);
      expect(selectedSuggestion?.name, originSuggestions[0].name);
    });

    testWidgets(
      'Selecting destination suggestion calls onDestinationSelected',
      (WidgetTester tester) async {
        SearchSuggestion? selectedSuggestion;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoutePreviewPanel(
                originText: '',
                destinationText: '',
                onClose: () {},
                onSwitch: () {},
                onOriginChanged: (_) {},
                onDestinationChanged: (_) {},
                onOriginSelected: (_) {},
                onDestinationSelected: (suggestion) =>
                    selectedSuggestion = suggestion,
                originSuggestions: const [],
                destinationSuggestions: destinationSuggestions,
                originRoomController: originRoomController,
                destinationRoomController: destinationRoomController,
              ),
            ),
          ),
        );

        // Focus destination field
        final destField = find.widgetWithText(TextField, 'Choose destination');
        await tester.tap(destField);
        await tester.pumpAndSettle();

        // Tap on first suggestion
        await tester.tap(find.text(destinationSuggestions[0].name));
        await tester.pumpAndSettle();

        expect(selectedSuggestion, isNotNull);
        expect(selectedSuggestion?.name, destinationSuggestions[0].name);
      },
    );

    testWidgets(
      'Suggestions show correct icons for Concordia vs non-Concordia',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoutePreviewPanel(
                originText: '',
                destinationText: '',
                onClose: () {},
                onSwitch: () {},
                onOriginChanged: (_) {},
                onDestinationChanged: (_) {},
                onOriginSelected: (_) {},
                onDestinationSelected: (_) {},
                originSuggestions: const [],
                destinationSuggestions: destinationSuggestions,
                originRoomController: originRoomController,
                destinationRoomController: destinationRoomController,
              ),
            ),
          ),
        );

        // Focus destination field to show suggestions
        final destField = find.widgetWithText(TextField, 'Choose destination');
        await tester.tap(destField);
        await tester.pumpAndSettle();

        // Check for school icon (Concordia building)
        expect(find.byIcon(Icons.school), findsOneWidget);
        // Check for place icon (non-Concordia place)
        expect(find.byIcon(Icons.place), findsWidgets);
      },
    );

    testWidgets('RoutePreviewPanel updates text when props change', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin 1',
              destinationText: 'Destination 1',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      expect(find.text('Origin 1'), findsOneWidget);
      expect(find.text('Destination 1'), findsOneWidget);

      // Update with new props
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin 2',
              destinationText: 'Destination 2',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Origin 2'), findsOneWidget);
      expect(find.text('Destination 2'), findsOneWidget);
    });

    testWidgets('didUpdateWidget updates origin controller when originText changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin A',
              destinationText: 'Destination A',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin B',
              destinationText: 'Destination A',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final startField = tester.widget<TextField>(find.byKey(const Key('start_field')));
      expect(startField.controller?.text, 'Origin B');
    });

    testWidgets('didUpdateWidget updates destination controller when destinationText changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin A',
              destinationText: 'Destination A',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: 'Origin A',
              destinationText: 'Destination B',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final destinationField = tester.widget<TextField>(
        find.byKey(const Key('destination_field')),
      );
      expect(destinationField.controller?.text, 'Destination B');
    });

    testWidgets('didUpdateWidget updates origin suggestions visibility when list changes', (
      WidgetTester tester,
    ) async {
      final updatedOriginSuggestions = [
        SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames[0]),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('start_field')));
      await tester.pumpAndSettle();
      expect(find.text(updatedOriginSuggestions.first.name), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: updatedOriginSuggestions,
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(updatedOriginSuggestions.first.name), findsOneWidget);
    });

    testWidgets('didUpdateWidget updates destination suggestions visibility when list changes', (
      WidgetTester tester,
    ) async {
      final updatedDestinationSuggestions = [
        SearchSuggestion.fromGooglePlace(
          name: 'Updated Place',
          subtitle: 'Updated Address',
          placeId: 'updated_place_id',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('destination_field')));
      await tester.pumpAndSettle();
      expect(find.text('Updated Place'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: updatedDestinationSuggestions,
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Updated Place'), findsOneWidget);
    });

    testWidgets('RoutePreviewPanel shows hint texts when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      expect(find.text('Starting location'), findsOneWidget);
      expect(find.text('Choose destination'), findsOneWidget);
    });

    testWidgets('Suggestions list has constrained height', (
      WidgetTester tester,
    ) async {
      // Create many suggestions
      final manySuggestions = List.generate(
        20,
        (i) => SearchSuggestion.fromConcordiaBuilding(
          concordiaBuildingNames[i % concordiaBuildingNames.length],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: manySuggestions,
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Focus origin field
      final originField = find.widgetWithText(TextField, 'Starting location');
      await tester.tap(originField);
      await tester.pumpAndSettle();

      // Find the suggestions container
      final container = find
          .ancestor(of: find.byType(ListView), matching: find.byType(Container))
          .first;

      final containerWidget = tester.widget<Container>(container);
      final constraints = containerWidget.constraints as BoxConstraints;
      expect(constraints.maxHeight, 250);
    });

    testWidgets('Selecting suggestion hides suggestions list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: originSuggestions,
              destinationSuggestions: const [],
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Focus origin field
      final originField = find.widgetWithText(TextField, 'Starting location');
      await tester.tap(originField);
      await tester.pumpAndSettle();

      // Verify suggestions are visible
      expect(find.byType(ListView), findsOneWidget);

      // Tap on first suggestion
      await tester.tap(find.text(originSuggestions[0].name));
      await tester.pumpAndSettle();

      // Verify suggestions are hidden
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Suggestions display subtitles correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: destinationSuggestions,
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
            ),
          ),
        ),
      );

      // Focus destination field
      final destField = find.widgetWithText(TextField, 'Choose destination');
      await tester.tap(destField);
      await tester.pumpAndSettle();

      // Verify subtitles are displayed
      expect(find.text(destinationSuggestions[0].subtitle!), findsOneWidget);
      expect(find.text('Test Address'), findsOneWidget);
    });
    testWidgets('Invalid origin room clears input and does not call callback', (
      tester,
    ) async {
      bool originValidCalled = false;
      final indoorRepo = FakeIndoorMapRepository(
        initialRooms: {
          'ORIGIN': ['101', '102'],
          'DEST': ['201', '202'],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originBuildingCode: 'ORIGIN',
              destinationBuildingCode: 'DEST',
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
              onStartValid: (_, __) => originValidCalled = true,
              isConcordiaBuilding:
                  (buildingCode) => // ✅ ADD THIS
                      buildingCode == 'ORIGIN' || buildingCode == 'DEST',
              indoorRepository: indoorRepo,
            ),
          ),
        ),
      );

      final originRoomField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller == originRoomController,
      );

      expect(originRoomField, findsOneWidget);

      await tester.tap(originRoomField);
      await tester.enterText(originRoomField, '999');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(originRoomController.text, '');
      expect(originValidCalled, isFalse);
    });

    testWidgets('Valid origin room keeps input and calls callback', (
      tester,
    ) async {
      bool originValidCalled = false;
      final indoorRepo = FakeIndoorMapRepository(
        initialRooms: {
          'ORIGIN': ['101'],
          'DEST': ['201'],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originBuildingCode: 'ORIGIN',
              destinationBuildingCode: 'DEST',
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
              onStartValid: (_, __) => originValidCalled = true,
              isConcordiaBuilding: (buildingCode) =>
                  buildingCode == 'ORIGIN' || buildingCode == 'DEST',
              indoorRepository: indoorRepo,
            ),
          ),
        ),
      );

      final originRoomField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.controller == originRoomController,
      );

      await tester.tap(originRoomField);
      await tester.enterText(originRoomField, '101');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(originRoomController.text, '101');
      expect(originValidCalled, isTrue);
    });

    testWidgets(
      'Invalid destination room clears input and does not call callbacks',
      (tester) async {
        bool destinationValidCalled = false;
        bool destinationSubmittedCalled = false;
        final indoorRepo = FakeIndoorMapRepository(
          initialRooms: {
            'ORIGIN': ['101'],
            'DEST': ['201', '202'],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RoutePreviewPanel(
                originText: '',
                destinationText: '',
                onClose: () {},
                onSwitch: () {},
                onOriginChanged: (_) {},
                onDestinationChanged: (_) {},
                onOriginSelected: (_) {},
                onDestinationSelected: (_) {},
                originSuggestions: const [],
                destinationSuggestions: const [],
                originBuildingCode: 'ORIGIN',
                destinationBuildingCode: 'DEST',
                originRoomController: originRoomController,
                destinationRoomController: destinationRoomController,
                onDestinationValid: (_, __) => destinationValidCalled = true,
                onDestinationRoomSubmitted: (_, __) =>
                    destinationSubmittedCalled = true,
                isConcordiaBuilding: (buildingCode) =>
                    buildingCode == 'ORIGIN' || buildingCode == 'DEST',
                indoorRepository: indoorRepo,
              ),
            ),
          ),
        );

        final destRoomField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.controller == destinationRoomController,
        );

        await tester.tap(destRoomField);
        await tester.enterText(destRoomField, '999');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(destinationRoomController.text, '');
        expect(destinationValidCalled, isFalse);
        expect(destinationSubmittedCalled, isFalse);
      },
    );

    testWidgets('Valid destination room keeps input and calls callbacks', (
      tester,
    ) async {
      bool destinationValidCalled = false;
      bool destinationSubmittedCalled = false;
      final indoorRepo = FakeIndoorMapRepository(
        initialRooms: {
          'ORIGIN': ['101'],
          'DEST': ['201'],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePreviewPanel(
              originText: '',
              destinationText: '',
              onClose: () {},
              onSwitch: () {},
              onOriginChanged: (_) {},
              onDestinationChanged: (_) {},
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
              originSuggestions: const [],
              destinationSuggestions: const [],
              originBuildingCode: 'ORIGIN',
              destinationBuildingCode: 'DEST',
              originRoomController: originRoomController,
              destinationRoomController: destinationRoomController,
              onDestinationValid: (_, __) => destinationValidCalled = true,
              onDestinationRoomSubmitted: (_, __) =>
                  destinationSubmittedCalled = true,
              isConcordiaBuilding: (buildingCode) =>
                  buildingCode == 'ORIGIN' || buildingCode == 'DEST',
              indoorRepository: indoorRepo,
            ),
          ),
        ),
      );

      final destRoomField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller == destinationRoomController,
      );

      await tester.tap(destRoomField);
      await tester.enterText(destRoomField, '201');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(destinationRoomController.text, '201');
      expect(destinationValidCalled, isTrue);
      expect(destinationSubmittedCalled, isTrue);
    });
  });
}
