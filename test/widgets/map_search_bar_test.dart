import 'package:campus_app/data/building_names.dart';
import 'package:campus_app/shared/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows suggestions when focused and suggestions exist',
      (WidgetTester tester) async {
    final controller = TextEditingController();
    final suggestions = <BuildingName>[
      concordiaBuildingNames.first,
      concordiaBuildingNames[1],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: suggestions,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text(suggestions.first.name), findsOneWidget);
    expect(find.text(suggestions[1].name), findsOneWidget);
  });

  testWidgets('Selecting a suggestion updates text and calls callback',
      (WidgetTester tester) async {
    final controller = TextEditingController();
    final selected = <BuildingName>[];
    final suggestion = concordiaBuildingNames.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [suggestion],
            onSuggestionSelected: (value) => selected.add(value),
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

  testWidgets('onFocus fires when search field gains focus',
      (WidgetTester tester) async {
    final controller = TextEditingController();
    var focusCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [concordiaBuildingNames.first],
            onFocus: () => focusCalled = true,
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
    final suggestion = concordiaBuildingNames.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            controller: controller,
            suggestions: [suggestion],
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
}
