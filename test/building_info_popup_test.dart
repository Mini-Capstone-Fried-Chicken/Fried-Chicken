import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/shared/widgets/building_info_popup.dart';

void main() {
  // Helper to wrap the widget in a MaterialApp with an Overlay for tooltips/labels
  Widget buildTestPopup({
    String title = 'Hall Building - HALL',
    String description = 'A main building on SGW campus.',
    bool accessibility = false,
    List<String> facilities = const [],
    bool isLoggedIn = false,
    VoidCallback? onClose,
    VoidCallback? onMore,
    VoidCallback? onIndoorMap,
    VoidCallback? onGetDirections,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: BuildingInfoPopup(
            title: title,
            description: description,
            accessibility: accessibility,
            facilities: facilities,
            isLoggedIn: isLoggedIn,
            onClose: onClose ?? () {},
            onMore: onMore,
            onIndoorMap: onIndoorMap,
            onGetDirections: onGetDirections ?? () {},
          ),
        ),
      ),
    );
  }

  group('BuildingInfoPopup', () {
    group('rendering', () {
      testWidgets('displays title and description', (tester) async {
        await tester.pumpWidget(
          buildTestPopup(
            title: 'EV Building - EV',
            description: 'Engineering and Visual Arts.',
          ),
        );

        expect(find.text('EV Building - EV'), findsOneWidget);
        expect(find.text('Engineering and Visual Arts.'), findsOneWidget);
      });

      testWidgets('displays More button', (tester) async {
        await tester.pumpWidget(buildTestPopup());

        expect(find.text('More'), findsOneWidget);
      });

      testWidgets('displays close button', (tester) async {
        await tester.pumpWidget(buildTestPopup());

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays directions icon', (tester) async {
        await tester.pumpWidget(buildTestPopup());

        expect(find.byIcon(Icons.directions), findsOneWidget);
      });

      testWidgets('displays indoor map icon', (tester) async {
        await tester.pumpWidget(buildTestPopup());

        expect(find.byIcon(Icons.map), findsOneWidget);
      });

      testWidgets('has correct container width of 300', (tester) async {
        await tester.pumpWidget(buildTestPopup());

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(BuildingInfoPopup),
            matching: find.byType(Container).first,
          ),
        );
        expect(container.constraints?.maxWidth, 300);
      });
    });

    group('logged-in state', () {
      testWidgets('shows bookmark icon when logged in', (tester) async {
        await tester.pumpWidget(buildTestPopup(isLoggedIn: true));

        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      });

      testWidgets('does not show bookmark icon when not logged in', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestPopup(isLoggedIn: false));

        expect(find.byIcon(Icons.bookmark_border), findsNothing);
        expect(find.byIcon(Icons.bookmark), findsNothing);
      });

      testWidgets('toggles bookmark on tap', (tester) async {
        await tester.pumpWidget(buildTestPopup(isLoggedIn: true));

        // Initially unsaved
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsNothing);

        // Tap to save
        await tester.tap(find.byIcon(Icons.bookmark_border));
        await tester.pump();

        // Now saved
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border), findsNothing);

        // Tap to unsave
        await tester.tap(find.byIcon(Icons.bookmark));
        await tester.pump();

        // Back to unsaved
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsNothing);
      });
    });

    group('callbacks', () {
      testWidgets('onClose is called when close button is tapped', (
        tester,
      ) async {
        bool closeCalled = false;
        await tester.pumpWidget(
          buildTestPopup(onClose: () => closeCalled = true),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(closeCalled, isTrue);
      });

      testWidgets('onGetDirections is called when directions icon is tapped', (
        tester,
      ) async {
        bool directionsCalled = false;
        await tester.pumpWidget(
          buildTestPopup(onGetDirections: () => directionsCalled = true),
        );

        await tester.tap(find.byIcon(Icons.directions));
        await tester.pump();

        expect(directionsCalled, isTrue);
      });

      testWidgets('onIndoorMap is called when map icon is tapped', (
        tester,
      ) async {
        bool indoorMapCalled = false;
        await tester.pumpWidget(
          buildTestPopup(onIndoorMap: () => indoorMapCalled = true),
        );

        await tester.tap(find.byIcon(Icons.map));
        await tester.pump();

        expect(indoorMapCalled, isTrue);
      });

      testWidgets('onMore is called when More button is tapped', (
        tester,
      ) async {
        bool moreCalled = false;
        await tester.pumpWidget(
          buildTestPopup(onMore: () => moreCalled = true),
        );

        await tester.tap(find.text('More'));
        await tester.pump();

        expect(moreCalled, isTrue);
      });

      testWidgets('indoor map button works with null onIndoorMap', (
        tester,
      ) async {
        // Should not throw when onIndoorMap is null
        await tester.pumpWidget(buildTestPopup(onIndoorMap: null));

        await tester.tap(find.byIcon(Icons.map));
        await tester.pump();

        // No crash = pass
      });

      testWidgets('More button works with null onMore', (tester) async {
        // Should not throw when onMore is null
        await tester.pumpWidget(buildTestPopup(onMore: null));

        await tester.tap(find.text('More'));
        await tester.pump();

        // No crash = pass
      });
    });

    group('accessibility icon', () {
      testWidgets('shows accessible icon when accessibility is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestPopup(accessibility: true));

        expect(find.byIcon(Icons.accessible), findsOneWidget);
      });

      testWidgets('hides accessible icon when accessibility is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestPopup(accessibility: false));

        expect(find.byIcon(Icons.accessible), findsNothing);
      });
    });

    group('facility icons', () {
      testWidgets('shows washroom icon for washroom facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Washrooms']));

        expect(find.byIcon(Icons.wc), findsOneWidget);
      });

      testWidgets('shows washroom icon for restroom facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Restroom']));

        expect(find.byIcon(Icons.wc), findsOneWidget);
      });

      testWidgets('shows washroom icon for toilet facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Toilet']));

        expect(find.byIcon(Icons.wc), findsOneWidget);
      });

      testWidgets('shows coffee icon for coffee facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Coffee Shop']));

        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      });

      testWidgets('shows coffee icon for cafe facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Cafe']));

        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      });

      testWidgets('shows restaurant icon for restaurant facility', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Restaurants']));

        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets('shows restaurant icon for food facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Food']));

        expect(find.byIcon(Icons.restaurant), findsOneWidget);
      });

      testWidgets('shows zen den icon for zen den facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Zen Den']));

        expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      });

      testWidgets('shows zen den icon for meditation facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Meditation']));

        expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      });

      testWidgets('shows metro icon for metro facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Metro']));

        expect(find.byIcon(Icons.subway), findsOneWidget);
      });

      testWidgets('shows metro icon for subway facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Subway']));

        expect(find.byIcon(Icons.subway), findsOneWidget);
      });

      testWidgets('shows parking icon for parking facility', (tester) async {
        await tester.pumpWidget(buildTestPopup(facilities: ['Parking']));

        expect(find.byIcon(Icons.local_parking), findsOneWidget);
      });

      testWidgets('shows no facility icons when facilities list is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestPopup(facilities: []));

        expect(find.byIcon(Icons.wc), findsNothing);
        expect(find.byIcon(Icons.local_cafe), findsNothing);
        expect(find.byIcon(Icons.restaurant), findsNothing);
        expect(find.byIcon(Icons.self_improvement), findsNothing);
        expect(find.byIcon(Icons.subway), findsNothing);
        expect(find.byIcon(Icons.local_parking), findsNothing);
      });

      testWidgets('shows multiple facility icons at once', (tester) async {
        await tester.pumpWidget(
          buildTestPopup(
            accessibility: true,
            facilities: [
              'Washrooms',
              'Coffee Shop',
              'Restaurant',
              'Parking',
              'Metro',
            ],
          ),
        );

        expect(find.byIcon(Icons.accessible), findsOneWidget);
        expect(find.byIcon(Icons.wc), findsOneWidget);
        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.local_parking), findsOneWidget);
        expect(find.byIcon(Icons.subway), findsOneWidget);
      });

      testWidgets('facility matching is case-insensitive', (tester) async {
        await tester.pumpWidget(
          buildTestPopup(facilities: ['WASHROOMS', 'COFFEE', 'PARKING']),
        );

        expect(find.byIcon(Icons.wc), findsOneWidget);
        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
        expect(find.byIcon(Icons.local_parking), findsOneWidget);
      });

      testWidgets('facility matching works with partial strings', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestPopup(
            facilities: ['Has washroom inside', 'Great coffee here'],
          ),
        );

        expect(find.byIcon(Icons.wc), findsOneWidget);
        expect(find.byIcon(Icons.local_cafe), findsOneWidget);
      });

      testWidgets('unrecognized facilities do not produce icons', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestPopup(facilities: ['Swimming Pool', 'Gym', 'Library']),
        );

        expect(find.byIcon(Icons.wc), findsNothing);
        expect(find.byIcon(Icons.local_cafe), findsNothing);
        expect(find.byIcon(Icons.restaurant), findsNothing);
        expect(find.byIcon(Icons.self_improvement), findsNothing);
        expect(find.byIcon(Icons.subway), findsNothing);
        expect(find.byIcon(Icons.local_parking), findsNothing);
      });
    });

    group('default parameter values', () {
      testWidgets('works with only required parameters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BuildingInfoPopup(
                title: 'Test',
                description: 'Desc',
                onClose: () {},
                isLoggedIn: false,
                onGetDirections: () {},
              ),
            ),
          ),
        );

        expect(find.text('Test'), findsOneWidget);
        expect(find.text('Desc'), findsOneWidget);
        // No accessibility icon by default
        expect(find.byIcon(Icons.accessible), findsNothing);
        // No facility icons by default
        expect(find.byIcon(Icons.wc), findsNothing);
      });
    });

    group('text styling', () {
      testWidgets('title has correct style', (tester) async {
        await tester.pumpWidget(buildTestPopup(title: 'My Title'));

        final titleWidget = tester.widget<Text>(find.text('My Title'));
        expect(titleWidget.textAlign, TextAlign.center);
        expect(titleWidget.style?.fontSize, 16);
        expect(titleWidget.style?.fontWeight, FontWeight.w700);
      });

      testWidgets('description has correct style', (tester) async {
        await tester.pumpWidget(
          buildTestPopup(description: 'Some description text'),
        );

        final descWidget = tester.widget<Text>(
          find.text('Some description text'),
        );
        expect(descWidget.textAlign, TextAlign.center);
        expect(descWidget.style?.fontSize, 12.5);
      });
    });
  });
}
