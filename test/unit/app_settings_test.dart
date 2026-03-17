import 'package:campus_app/features/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettingsController', () {
    setUp(() {
      AppSettingsController.debugSetUserIdResolver(() => null);
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    tearDown(() {
      AppSettingsController.debugResetUserIdResolver();
      AppSettingsController.notifier.value = const AppSettingsState();
    });

    test('default state values are correct', () {
      expect(AppSettingsController.state.accessibilityModeEnabled, isFalse);
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusSgw,
      );
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

    test('setDefaultCampus updates state and normalizes invalid values', () {
      AppSettingsController.setDefaultCampus(AppSettingsState.defaultCampusLoyola);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusLoyola,
      );

      AppSettingsController.setDefaultCampus('invalid-campus');
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusSgw,
      );
    });

    test('restore loads persisted default campus from shared preferences', () async {
      SharedPreferences.setMockInitialValues({
        'settings_default_campus__anonymous':
            AppSettingsState.defaultCampusLoyola,
      });

      await AppSettingsController.restore();

      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusLoyola,
      );
    });

    test('setDefaultCampus persists to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});

      AppSettingsController.setDefaultCampus(AppSettingsState.defaultCampusLoyola);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('settings_default_campus__anonymous'),
        AppSettingsState.defaultCampusLoyola,
      );
    });

    test('settings are isolated between accounts', () async {
      SharedPreferences.setMockInitialValues({});

      AppSettingsController.debugSetUserIdResolver(() => 'user-a');
      await AppSettingsController.restore(force: true);
      AppSettingsController.setDefaultCampus(AppSettingsState.defaultCampusLoyola);
      await Future<void>.delayed(Duration.zero);

      AppSettingsController.debugSetUserIdResolver(() => 'user-b');
      await AppSettingsController.restore(force: true);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusSgw,
      );

      AppSettingsController.debugSetUserIdResolver(() => 'user-a');
      await AppSettingsController.restore(force: true);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusLoyola,
      );
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
