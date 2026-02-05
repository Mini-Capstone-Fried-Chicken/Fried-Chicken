// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart' show HomePage;

void main() {
  testWidgets('Home page displays welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      //Arrange - Act
    MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: const HomePage(isLoggedIn: true),
        ),
    )
    );
    //Assert
    expect(find.text('Welcome to Campus'), findsOneWidget);
    expect(find.text('your go-to map on campus'), findsOneWidget);
  });
}