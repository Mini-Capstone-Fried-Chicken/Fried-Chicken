import 'package:campus_app/shared/widgets/building_info_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildingInfoPopup Widget Tests', () {
    late bool closePressed;
    late bool learnMorePressed;

    setUp(() {
      closePressed = false;
      learnMorePressed = false;
    });

    //pop up tests
    Widget createPopupUnderTest() {
      return MaterialApp(
        home: Scaffold(
          body: BuildingInfoPopup(
            title: 'Test Building',
            description: 'This is a test building description.',
            onClose: () {
              closePressed = true;
            },
            onLearnMore: () {
              learnMorePressed = true;
            },
          ),
        ),
      );
    }

    //clicking on building pop up
    Widget createBuildingWithPopup() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  key: const Key('buildingButton'),
                  child: const Text('Test Building Button'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BuildingInfoPopup(
                        title: 'Test Building',
                        description: 'This is a test building description.',
                        onClose: () {
                          closePressed = true;
                          Navigator.of(context).pop();
                        },
                        onLearnMore: () {
                          learnMorePressed = true;
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders title and description', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest());

      expect(find.text('Test Building'), findsOneWidget);
      expect(find.text('This is a test building description.'), findsOneWidget);
    });

    testWidgets('renders all buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest());

      expect(find.text('Get directions'), findsOneWidget);
      expect(find.text('Indoor map'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
    });

    testWidgets('close button triggers onClose callback', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest());

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pump();

      expect(closePressed, isTrue);
    });

    testWidgets('learn more button triggers onLearnMore callback', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest());

      final learnMoreButton = find.widgetWithText(ElevatedButton, 'Learn more');
      expect(learnMoreButton, findsOneWidget);

      await tester.tap(learnMoreButton);
      await tester.pump();

      expect(learnMorePressed, isTrue);
    });

    testWidgets('other buttons can be tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createPopupUnderTest());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Get directions'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Indoor map'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();
    });


    testWidgets('clicking a building opens popup with correct info',
        (WidgetTester tester) async {
      await tester.pumpWidget(createBuildingWithPopup());

      //tapping building button
      final buildingButton = find.byKey(const Key('buildingButton'));
      expect(buildingButton, findsOneWidget);
      await tester.tap(buildingButton);
      await tester.pumpAndSettle();

      //verify building information is displayed
      expect(find.text('Test Building'), findsOneWidget);
      expect(find.text('This is a test building description.'), findsOneWidget);

      //ensure all the buttons are in the pop up 
      expect(find.text('Get directions'), findsOneWidget);
      expect(find.text('Indoor map'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
    });

    testWidgets('popup can be closed after opening from building tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createBuildingWithPopup());

      await tester.tap(find.byKey(const Key('buildingButton')));
      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      //closing pop up
      expect(find.text('Test Building'), findsNothing);
      expect(closePressed, isTrue);
    });

    testWidgets('learn more button works when popup opened from building tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createBuildingWithPopup());

      await tester.tap(find.byKey(const Key('buildingButton')));
      await tester.pumpAndSettle();

      final learnMoreButton = find.widgetWithText(ElevatedButton, 'Learn more');
      await tester.tap(learnMoreButton);
      await tester.pump();

      expect(learnMorePressed, isTrue);
    });
  });
}
