import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/data/search_suggestion.dart';
import 'package:campus_app/shared/widgets/route_preview_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutePreviewPanel Widget Tests', () {
    late List<SearchSuggestion> originSuggestions;
    late List<SearchSuggestion> destinationSuggestions;
    late TextEditingController originRoomController;
    late TextEditingController destinationRoomController;

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
  });
}
