import 'package:campus_app/shared/widgets/learn_more_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearnMorePopup Widget Tests', () {
    late bool closePressed;

    setUp(() {
      closePressed = false;
    });

    Widget createWidgetUnderTest({
      String? purpose,
      String? facilities,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LearnMorePopup(
            onClose: () {
              closePressed = true;
            },
            purposeText: purpose ?? 'No purpose available.',
            facilitiesText: facilities ?? 'No facilities available.',
          ),
        ),
      );
    }

    testWidgets('renders default purpose and facilities text when none provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check header
      expect(find.text('Additional Information:'), findsOneWidget);

      // Check RichText contains default purpose and facilities
      final purposeFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Purpose: No purpose available.');
        }
        return false;
      });
      final facilitiesFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Facilities: No facilities available.');
        }
        return false;
      });

      expect(purposeFinder, findsOneWidget);
      expect(facilitiesFinder, findsOneWidget);
    });

    testWidgets('renders provided purpose and facilities text',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        purpose: 'This is the building purpose.',
        facilities: 'Restrooms, Elevators, Parking',
      ));

      final purposeFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Purpose: This is the building purpose.');
        }
        return false;
      });
      final facilitiesFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Facilities: Restrooms, Elevators, Parking');
        }
        return false;
      });

      expect(purposeFinder, findsOneWidget);
      expect(facilitiesFinder, findsOneWidget);
    });

    testWidgets('close button triggers onClose callback', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pump();

      expect(closePressed, isTrue);
    });

    testWidgets('RichText widgets exist for purpose and facilities',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.startsWith('Purpose:') || text.startsWith('Facilities:');
        }
        return false;
      });

      expect(richTextFinder, findsNWidgets(2));
    });
  });
}
