import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  group('SettingsScreen (feature)', () {
    setUp(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    testWidgets('shows screen sections and auth action button', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Accessibility Settings'), findsOneWidget);
      expect(find.text('Permission Management'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('keeps large text disabled until accessibility mode is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      await tester.ensureVisible(find.text('Large Text'));
      await tester.tap(find.text('Large Text'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);

      await tester.tap(find.text('Assessibility Mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large Text'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
    });
  });
}
