import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_event.dart';
import 'package:campus_app/features/calendar/services/google_calendar_session.dart';
import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/services/location/googlemaps_livelocation.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: OutdoorMapPage(
        initialCampus: Campus.sgw,
        isLoggedIn: true,
        debugDisableMap: true,
        debugDisableLocation: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MapSearchBar _readSearchBar(WidgetTester tester) {
  return tester.widget<MapSearchBar>(find.byType(MapSearchBar));
}

void main() {
  setUp(() {
    SavedDirectionsController.clear();
    GoogleCalendarSession.instance.events = [];
    GoogleCalendarSession.instance.selectedCalendarIds = {};
    GoogleCalendarSession.instance.isConnected = false;
  });

  testWidgets('Concordia suggestion callback opens building selection flow', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    final searchBar = _readSearchBar(tester);
    final callback = searchBar.onSuggestionSelected;
    expect(callback, isNotNull);

    await callback!(
      SearchSuggestion.fromConcordiaBuilding(concordiaBuildingNames.first),
    );
    await tester.pumpAndSettle();

    final updatedSearchBar = _readSearchBar(tester);
    expect(updatedSearchBar.selectedBuildingCode, isNotNull);
  });

  testWidgets('Place suggestion callback safely ignores null place id', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    final searchBar = _readSearchBar(tester);
    final callback = searchBar.onSuggestionSelected;
    expect(callback, isNotNull);

    await callback!(
      const SearchSuggestion(
        name: 'No Place Id',
        isConcordiaBuilding: false,
        placeId: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(SavedDirectionsController.notifier.value, isNull);
  });

  testWidgets(
    'Next-class action suggestion triggers saved directions request',
    (WidgetTester tester) async {
      GoogleCalendarSession.instance.events = [
        GoogleCalendarEvent(
          id: 'evt-1',
          title: 'SOEN 341',
          start: DateTime.now().add(const Duration(hours: 1)),
          end: DateTime.now().add(const Duration(hours: 2)),
          location: 'MB-1.210',
          description: '820',
          calendarId: 'cal-1',
          calendarName: 'Classes',
          color: Colors.blue,
        ),
      ];

      await _pumpPage(tester);

      final searchBar = _readSearchBar(tester);
      final focusCallback = searchBar.onFocus;
      expect(focusCallback, isNotNull);

      focusCallback!();
      await tester.pumpAndSettle();

      final refreshedSearchBar = _readSearchBar(tester);
      final selectCallback = refreshedSearchBar.onSuggestionSelected;
      expect(selectCallback, isNotNull);

      await selectCallback!(
        const SearchSuggestion(
          name: 'Directions to next class: SOEN 341',
          subtitle: 'soon',
          isConcordiaBuilding: false,
          placeId: '__action_next_class__',
        ),
      );
      await tester.pumpAndSettle();

      final SavedPlace? requested = SavedDirectionsController.notifier.value;
      expect(requested, isNotNull);
      expect(requested!.id, 'MB');
      expect(requested.roomCode, '820');
    },
  );

  testWidgets('Next-class action suggestion no-ops without recommendation', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester);

    final searchBar = _readSearchBar(tester);
    final selectCallback = searchBar.onSuggestionSelected;
    expect(selectCallback, isNotNull);

    await selectCallback!(
      const SearchSuggestion(
        name: 'Directions to next class: none',
        subtitle: 'none',
        isConcordiaBuilding: false,
        placeId: '__action_next_class__',
      ),
    );
    await tester.pumpAndSettle();

    expect(SavedDirectionsController.notifier.value, isNull);
  });

  testWidgets(
    'Next-class action uses building-only directions when room is empty',
    (WidgetTester tester) async {
      GoogleCalendarSession.instance.events = [
        GoogleCalendarEvent(
          id: 'evt-2',
          title: 'COMP 472',
          start: DateTime.now().add(const Duration(hours: 1)),
          end: DateTime.now().add(const Duration(hours: 2)),
          location: 'MB-1.210',
          description: '   ',
          calendarId: 'cal-1',
          calendarName: 'Classes',
          color: Colors.red,
        ),
      ];

      await _pumpPage(tester);

      final searchBar = _readSearchBar(tester);
      final focusCallback = searchBar.onFocus;
      expect(focusCallback, isNotNull);

      focusCallback!();
      await tester.pumpAndSettle();

      final refreshedSearchBar = _readSearchBar(tester);
      final selectCallback = refreshedSearchBar.onSuggestionSelected;
      expect(selectCallback, isNotNull);

      await selectCallback!(
        const SearchSuggestion(
          name: 'Directions to next class: COMP 472',
          subtitle: 'soon',
          isConcordiaBuilding: false,
          placeId: '__action_next_class__',
        ),
      );
      await tester.pumpAndSettle();

      final SavedPlace? requested = SavedDirectionsController.notifier.value;
      expect(requested, isNotNull);
      expect(requested!.id, 'MB');
      expect(requested.roomCode, isNull);
    },
  );
}
