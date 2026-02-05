import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_app/main.dart' show HomePage, AppLogo, AppButton;

void main() {
  group('Welcome Page Tests', () {
    testWidgets('Welcome page displays logo', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byWidgetPredicate(
        (widget) => widget is Image && widget.image.toString().contains('logo.png'),
      ), findsWidgets);
    });

    testWidgets('Welcome page displays get started button', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.text('Get started'), findsOneWidget);
      expect(find.byType(AppButton), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Welcome page displays welcome message', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert
      expect(find.text('Welcome to Campus'), findsOneWidget);
      expect(find.text('your go-to map on campus'), findsOneWidget);
    });

    testWidgets('Get started button is functional', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert button exists and is enabled
      final getStartedButton = find.byType(AppButton);
      expect(getStartedButton, findsWidgets);

      // Tap the button
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Verify navigation occurred by checking if new route was pushed
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('Welcome page has all required UI elements', (WidgetTester tester) async {
      // Set device size to avoid layout overflow
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(1080, 3000);
      
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomePage(isLoggedIn: false),
        ),
      );

      // Assert - Logo is present
      expect(find.byType(AppLogo), findsOneWidget);

      // Assert - Get started button is present
      expect(find.text('Get started'), findsOneWidget);

      // Assert - Welcome text is present
      expect(find.text('Welcome to Campus'), findsOneWidget);

      // Assert - Descriptive text is present
      expect(find.text('your go-to map on campus'), findsOneWidget);
    });
  });
}
