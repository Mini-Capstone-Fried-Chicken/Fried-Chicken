import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  group('SettingsScreen', () {
    setUp(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    testWidgets(
      'renders sectioned settings layout and sign out button when logged in',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        expect(find.text('General Settings'), findsOneWidget);
        expect(find.text('Accessibility Settings'), findsOneWidget);
        expect(find.text('Default Campus'), findsOneWidget);
        expect(find.text('Calendar Access'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.text('Sign In'), findsNothing);
      },
    );

    testWidgets('renders sign in button when user is not logged in', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: false)),
      );

      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
    });

    testWidgets(
      'accessibility controls are gated until accessibility mode is enabled',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        await tester.ensureVisible(find.text('High Contrast mode'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('High Contrast mode'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.highContrastModeEnabled, isFalse);

        await tester.tap(find.text('Accessibility Mode'));
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.accessibilityModeEnabled, isTrue);

        await tester.tap(find.text('High Contrast mode'));
        await tester.pumpAndSettle();
        expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
      },
    );

    testWidgets(
      'high contrast mode switch updates shared settings when accessibility mode is enabled',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        await tester.tap(find.text('Accessibility Mode'));
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.highContrastModeEnabled, isFalse);

        await tester.ensureVisible(find.text('High Contrast mode'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('High Contrast mode'));
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
      },
    );

    testWidgets(
      'large text switch updates shared settings when accessibility mode is enabled',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        await tester.tap(find.text('Accessibility Mode'));
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.largeTextModeEnabled, isFalse);

        await tester.ensureVisible(find.text('Large Text'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Large Text'));
        await tester.pumpAndSettle();

        expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
      },
    );

    testWidgets('calendar access switch updates shared settings state', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);

      await tester.tap(find.text('Calendar Access'));
      await tester.pumpAndSettle();

      expect(AppSettingsController.state.calendarAccessEnabled, isFalse);
    });

    testWidgets(
      'high contrast active settings screen uses dark page background',
      (tester) async {
        AppSettingsController.setAccessibilityMode(true);
        AppSettingsController.setHighContrastMode(true);

        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, Colors.black);
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets('listens to shared settings updates after initial build', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);

      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);
      await tester.pumpAndSettle();

      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('default campus segmented control allows switching to Loyola', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      await tester.tap(find.text('Loyola'));
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>),
      );

      expect(segmentedButton.selected, {'Loyola'});
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusLoyola,
      );
    });

    testWidgets(
      'default campus segmented control reflects shared default campus on load',
      (tester) async {
        AppSettingsController.notifier.value = const AppSettingsState(
          defaultCampus: AppSettingsState.defaultCampusLoyola,
        );

        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );

        expect(segmentedButton.selected, {'Loyola'});
      },
    );

    testWidgets(
      'accessibility section is dimmed and non-interactive when mode is off',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
        final ignorePointerWidgets = tester.widgetList<IgnorePointer>(
          find.byType(IgnorePointer),
        );

        expect(opacityWidgets.any((widget) => widget.opacity == 0.5), isTrue);
        expect(ignorePointerWidgets.any((widget) => widget.ignoring), isTrue);
      },
    );

    testWidgets(
      'enabling accessibility mode activates accessibility controls',
      (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
        );

        await tester.tap(find.text('Accessibility Mode'));
        await tester.pumpAndSettle();

        final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
        final ignorePointerWidgets = tester.widgetList<IgnorePointer>(
          find.byType(IgnorePointer),
        );

        expect(opacityWidgets.any((widget) => widget.opacity == 1.0), isTrue);
        expect(ignorePointerWidgets.any((widget) => !widget.ignoring), isTrue);
      },
    );

    testWidgets('wheelchair routing switch updates shared settings state', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      await tester.tap(find.text('Accessibility Mode'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Wheelchair routing as default'));
      final wheelchairSwitch = find.descendant(
        of: find.widgetWithText(
          SwitchListTile,
          'Wheelchair routing as default',
        ),
        matching: find.byType(Switch),
      );
      await tester.tap(wheelchairSwitch, warnIfMissed: false);
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Wheelchair routing as default'),
      );
      expect(switchTile.value, isTrue);
      expect(
        AppSettingsController.state.wheelchairRoutingDefaultEnabled,
        isTrue,
      );
    });

    testWidgets('sign in button routes to SignInPage when logged out', (
      tester,
    ) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: false)),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('sign out failure shows an error snackbar', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const SettingsScreen(isLoggedIn: true)),
      );

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error logging out:'), findsOneWidget);
    });
  });
}
