import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/services/google_places_service.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _MockHttpClient extends http.BaseClient {
  final http.Response Function(http.Request request) handler;

  _MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SavedPlacesController.debugSetUserIdResolver(() => null);
    SavedPlacesController.notifier.value = const <SavedPlace>[];
  });

  tearDown(() {
    SavedPlacesController.debugResetUserIdResolver();
    SavedPlacesController.notifier.value = const <SavedPlace>[];
  });

  testWidgets('Shows suggestions when focused and suggestions exist', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final suggestions = <BuildingName>[
      concordiaBuildingNames.first,
      concordiaBuildingNames[1],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: suggestions
                .map((b) => SearchSuggestion.fromConcordiaBuilding(b))
                .toList(),
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text(suggestions.first.name), findsOneWidget);
    expect(find.text(suggestions[1].name), findsOneWidget);
  });

  testWidgets('Selecting a suggestion updates text and calls callback', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final selected = <BuildingName>[];
    final suggestion = concordiaBuildingNames.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [
              suggestion,
            ].map((s) => SearchSuggestion.fromConcordiaBuilding(s)).toList(),
            onSuggestionSelected: (value) => selected.add(value.buildingName!),
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.tap(find.text(suggestion.name));
    await tester.pumpAndSettle();

    expect(controller.text, suggestion.name);
    expect(selected.single, suggestion);
    expect(find.widgetWithText(ListTile, suggestion.name), findsNothing);
  });

  testWidgets('onFocus fires when search field gains focus', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    var focusCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [
              SearchSuggestion.fromConcordiaBuilding(
                concordiaBuildingNames.first,
              ),
            ],
            onFocus: () => focusCalled = true,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(focusCalled, isTrue);
  });

  testWidgets('Tapping outside hides suggestions', (WidgetTester tester) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final suggestion = concordiaBuildingNames.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [SearchSuggestion.fromConcordiaBuilding(suggestion)],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text(suggestion.name), findsOneWidget);

    final scaffold = find.byType(Scaffold);
    final scaffoldRect = tester.getRect(scaffold);
    await tester.tapAt(Offset(scaffoldRect.right - 5, scaffoldRect.bottom - 5));
    await tester.pumpAndSettle();

    expect(find.text(suggestion.name), findsNothing);
  });

  testWidgets('No suggestions list when there are no suggestions', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: const [],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('Hint text includes campus label when provided', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            campusLabel: 'SGW',
            controller: controller,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    expect(find.text('Search anywhere near SGW'), findsOneWidget);
  });

  testWidgets('Hint text falls back when campus label is empty', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            campusLabel: '   ',
            controller: controller,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    expect(find.text('Search anywhere'), findsOneWidget);
  });

  testWidgets('onSubmitted callback fires from text field submit', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            onSubmitted: (v) => submitted = v,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('map_search_input')), 'Hall');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submitted, 'Hall');
  });

  testWidgets('RoomFieldsSection hidden when no concordia context', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            currentBuildingCode: '',
            selectedBuildingCode: '',
            isConcordiaBuilding: (_) => false,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    expect(find.byType(RoomFieldsSection), findsNothing);
  });

  testWidgets('RoomFieldsSection shown when selected building is concordia', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            currentBuildingCode: 'H',
            selectedBuildingCode: 'MB',
            isConcordiaBuilding: (_) => true,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    expect(find.byType(RoomFieldsSection), findsOneWidget);
    expect(find.text('Origin Room'), findsOneWidget);
    expect(find.text('Destination Room'), findsOneWidget);
  });

  testWidgets('High contrast mode uses dark text in search field', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            highContrastMode: true,
            controller: controller,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.style?.color, Colors.black);
  });

  testWidgets('Saved icon renders as bookmarked for saved suggestion id', (
    WidgetTester tester,
  ) async {
    await SavedPlacesController.ensureInitialized();
    await SavedPlacesController.savePlace(
      const SavedPlace(
        id: 'MB',
        name: 'John Molson School of Business',
        category: 'concordia building',
        latitude: 45.4958,
        longitude: -73.5793,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    );

    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final suggestion = concordiaBuildingNames.firstWhere((b) => b.code == 'MB');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [SearchSuggestion.fromConcordiaBuilding(suggestion)],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('Tapping remove from saved updates icon to unsaved', (
    WidgetTester tester,
  ) async {
    await SavedPlacesController.ensureInitialized();
    await SavedPlacesController.savePlace(
      const SavedPlace(
        id: 'MB',
        name: 'John Molson School of Business',
        category: 'concordia building',
        latitude: 45.4958,
        longitude: -73.5793,
        openingHoursToday: 'Open today: Hours unavailable',
      ),
    );

    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final suggestion = concordiaBuildingNames.firstWhere((b) => b.code == 'MB');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [SearchSuggestion.fromConcordiaBuilding(suggestion)],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from saved'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('Add to saved no-op for non-concordia suggestion without place id', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    const suggestion = SearchSuggestion(
      name: 'Unknown Place',
      subtitle: 'No place id',
      isConcordiaBuilding: false,
      placeId: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: const [suggestion],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to saved'));
    await tester.pumpAndSettle();

    expect(SavedPlacesController.notifier.value, isEmpty);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('Add to saved stores valid concordia suggestion', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();
    final suggestion = concordiaBuildingNames.firstWhere((b) => b.code == 'MB');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [SearchSuggestion.fromConcordiaBuilding(suggestion)],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to saved'));
    await tester.pumpAndSettle();

    expect(SavedPlacesController.isSaved('MB'), isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('Add to saved stores valid non-concordia suggestion with injected places service', (
    WidgetTester tester,
  ) async {
    final mockClient = _MockHttpClient((request) {
      return http.Response(
        '{"id":"place_123","displayName":{"text":"Injected Place"},"location":{"latitude":45.501,"longitude":-73.571},"primaryType":"cafe","types":["cafe"]}',
        200,
      );
    });
    final injectedPlacesService = GooglePlacesService(client: mockClient);

    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    final suggestion = SearchSuggestion.fromGooglePlace(
      name: 'Injected Place',
      subtitle: 'Montreal',
      placeId: 'place_123',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [suggestion],
            placesService: injectedPlacesService,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to saved'));
    await tester.pumpAndSettle();

    expect(SavedPlacesController.isSaved('place_123'), isTrue);
    final saved = SavedPlacesController.notifier.value.firstWhere(
      (p) => p.id == 'place_123',
    );
    expect(saved.name, 'Injected Place');
    expect(saved.googlePlaceType, 'cafe');
  });

  testWidgets('External room controller changes rebuild without crashing', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            currentBuildingCode: 'H',
            selectedBuildingCode: 'MB',
            isConcordiaBuilding: (_) => true,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    originRoomController.text = '101';
    destinationRoomController.text = '202';
    await tester.pumpAndSettle();

    expect(find.byType(RoomFieldsSection), findsOneWidget);
  });

  testWidgets('Add to saved no-op for concordia suggestion without building payload', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    const suggestion = SearchSuggestion(
      name: 'Broken Concordia Suggestion',
      subtitle: 'No building model',
      isConcordiaBuilding: true,
      buildingName: null,
      placeId: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: const [suggestion],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to saved'));
    await tester.pumpAndSettle();

    expect(SavedPlacesController.notifier.value, isEmpty);
  });

  testWidgets('Add to saved no-op when concordia building code is not in polygon list', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final originRoomController = TextEditingController();
    final destinationRoomController = TextEditingController();

    const fakeBuilding = BuildingName(
      code: 'ZZZ999',
      name: 'Unknown Concordia Building',
    );

    final suggestion = SearchSuggestion.fromConcordiaBuilding(fakeBuilding);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [suggestion],
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to saved'));
    await tester.pumpAndSettle();

    expect(SavedPlacesController.notifier.value, isEmpty);
  });
}
