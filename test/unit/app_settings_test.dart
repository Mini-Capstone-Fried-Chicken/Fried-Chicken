import 'package:campus_app/features/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettingsController', () {
    setUp(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    test('default state values are correct', () {
      expect(AppSettingsController.state.accessibilityModeEnabled, isFalse);
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);
    });

    test('setAccessibilityMode(false) clears high contrast and large text', () {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);
      AppSettingsController.setLargeTextMode(true);

      AppSettingsController.setAccessibilityMode(false);

      expect(AppSettingsController.state.accessibilityModeEnabled, isFalse);
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
    });

    test('setHighContrastMode is ignored when accessibility mode is disabled', () {
      AppSettingsController.setHighContrastMode(true);
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
    });

    test('setHighContrastMode updates when accessibility mode is enabled', () {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);

      expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
    });

    test('setLargeTextMode is ignored when accessibility mode is disabled', () {
      AppSettingsController.setLargeTextMode(true);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
    });

    test('setLargeTextMode updates when accessibility mode is enabled', () {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setLargeTextMode(true);

      expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
    });

    test('setCalendarAccess updates state', () {
      AppSettingsController.setCalendarAccess(false);
      expect(AppSettingsController.state.calendarAccessEnabled, isFalse);

      AppSettingsController.setCalendarAccess(true);
      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);
    });
  });

  group('AppUiColors', () {
    test('primary returns default primary when high contrast is disabled', () {
      expect(
        AppUiColors.primary(highContrastEnabled: false),
        AppUiColors.defaultPrimary,
      );
    });

    test('primary returns high contrast primary when high contrast is enabled', () {
      expect(
        AppUiColors.primary(highContrastEnabled: true),
        AppUiColors.highContrastPrimary,
      );
    });
  });
}
