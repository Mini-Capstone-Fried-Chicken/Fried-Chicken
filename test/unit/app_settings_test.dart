import 'package:campus_app/features/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(
        AppSettingsController.state.wheelchairRoutingDefaultEnabled,
        isFalse,
      );
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
      expect(AppSettingsController.state.calendarAccessEnabled, isTrue);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusSgw,
      );
    });

    test('AppSettingsState.copyWith updates selected fields only', () {
      const base = AppSettingsState(
        accessibilityModeEnabled: true,
        wheelchairRoutingDefaultEnabled: false,
        highContrastModeEnabled: true,
        largeTextModeEnabled: false,
        calendarAccessEnabled: true,
        defaultCampus: AppSettingsState.defaultCampusSgw,
      );

      final updated = base.copyWith(
        largeTextModeEnabled: true,
        defaultCampus: AppSettingsState.defaultCampusLoyola,
      );

      expect(updated.accessibilityModeEnabled, isTrue);
      expect(updated.wheelchairRoutingDefaultEnabled, isFalse);
      expect(updated.highContrastModeEnabled, isTrue);
      expect(updated.largeTextModeEnabled, isTrue);
      expect(updated.calendarAccessEnabled, isTrue);
      expect(updated.defaultCampus, AppSettingsState.defaultCampusLoyola);
    });

    test('setAccessibilityMode(false) clears high contrast and large text', () {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);
      AppSettingsController.setLargeTextMode(true);

      AppSettingsController.setAccessibilityMode(false);

      expect(AppSettingsController.state.accessibilityModeEnabled, isFalse);
      expect(
        AppSettingsController.state.wheelchairRoutingDefaultEnabled,
        isFalse,
      );
      expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
      expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
    });

    test(
      'setWheelchairRoutingDefault updates state even when accessibility mode is disabled',
      () {
        AppSettingsController.setWheelchairRoutingDefault(true);
        expect(
          AppSettingsController.state.wheelchairRoutingDefaultEnabled,
          isTrue,
        );
      },
    );

    test(
      'setWheelchairRoutingDefault updates when accessibility mode is enabled',
      () {
        AppSettingsController.setAccessibilityMode(true);
        AppSettingsController.setWheelchairRoutingDefault(true);

        expect(
          AppSettingsController.state.wheelchairRoutingDefaultEnabled,
          isTrue,
        );
      },
    );

    test(
      'setHighContrastMode updates state even when accessibility mode is disabled',
      () {
        AppSettingsController.setHighContrastMode(true);
        expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
      },
    );

    test('setHighContrastMode updates when accessibility mode is enabled', () {
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setHighContrastMode(true);

      expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
    });

    test('setLargeTextMode updates state even when accessibility mode is disabled', () {
      AppSettingsController.setLargeTextMode(true);
      expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
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
      AppSettingsController.setDefaultCampus(
        AppSettingsState.defaultCampusLoyola,
      );
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

    test(
      'restore loads persisted default campus from shared preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'settings_default_campus__anonymous':
              AppSettingsState.defaultCampusLoyola,
        });

        await AppSettingsController.restore();

        expect(
          AppSettingsController.state.defaultCampus,
          AppSettingsState.defaultCampusLoyola,
        );
      },
    );

    test(
      'restore reads legacy unscoped keys when scoped key is absent',
      () async {
        SharedPreferences.setMockInitialValues({
          'settings_accessibility_mode_enabled': true,
          'settings_wheelchair_routing_default_enabled': true,
          'settings_high_contrast_mode_enabled': true,
          'settings_large_text_mode_enabled': true,
          'settings_calendar_access_enabled': false,
          'settings_default_campus': AppSettingsState.defaultCampusLoyola,
        });

        await AppSettingsController.restore(force: true);

        expect(AppSettingsController.state.accessibilityModeEnabled, isTrue);
        expect(
          AppSettingsController.state.wheelchairRoutingDefaultEnabled,
          isTrue,
        );
        expect(AppSettingsController.state.highContrastModeEnabled, isTrue);
        expect(AppSettingsController.state.largeTextModeEnabled, isTrue);
        expect(AppSettingsController.state.calendarAccessEnabled, isFalse);
        expect(
          AppSettingsController.state.defaultCampus,
          AppSettingsState.defaultCampusLoyola,
        );
      },
    );

    test(
      'restore skips work when already initialized for same scope',
      () async {
        SharedPreferences.setMockInitialValues({
          'settings_default_campus__anonymous':
              AppSettingsState.defaultCampusLoyola,
        });
        await AppSettingsController.restore(force: true);
        expect(
          AppSettingsController.state.defaultCampus,
          AppSettingsState.defaultCampusLoyola,
        );

        SharedPreferences.setMockInitialValues({
          'settings_default_campus__anonymous':
              AppSettingsState.defaultCampusSgw,
        });
        await AppSettingsController.restore();

        expect(
          AppSettingsController.state.defaultCampus,
          AppSettingsState.defaultCampusLoyola,
        );
      },
    );

    test(
      'restore with default resolver does not crash in test environment',
      () async {
        SharedPreferences.setMockInitialValues({});
        AppSettingsController.debugResetUserIdResolver();

        await AppSettingsController.restore(force: true);

        expect(AppSettingsController.state, isA<AppSettingsState>());
      },
    );

    test('setDefaultCampus persists to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});

      AppSettingsController.setDefaultCampus(
        AppSettingsState.defaultCampusLoyola,
      );
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('settings_default_campus__anonymous'),
        AppSettingsState.defaultCampusLoyola,
      );
    });

    test(
      'setWheelchairRoutingDefault persists to shared preferences',
      () async {
        SharedPreferences.setMockInitialValues({});

        AppSettingsController.setAccessibilityMode(true);
        AppSettingsController.setWheelchairRoutingDefault(true);
        await Future<void>.delayed(Duration.zero);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(
            'settings_wheelchair_routing_default_enabled__anonymous',
          ),
          isTrue,
        );
      },
    );

    test('settings are isolated between accounts', () async {
      SharedPreferences.setMockInitialValues({});

      AppSettingsController.debugSetUserIdResolver(() => 'user-a');
      await AppSettingsController.restore(force: true);
      AppSettingsController.setDefaultCampus(
        AppSettingsState.defaultCampusLoyola,
      );
      AppSettingsController.setAccessibilityMode(true);
      AppSettingsController.setWheelchairRoutingDefault(true);
      await Future<void>.delayed(Duration.zero);

      AppSettingsController.debugSetUserIdResolver(() => 'user-b');
      await AppSettingsController.restore(force: true);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusSgw,
      );
      expect(
        AppSettingsController.state.wheelchairRoutingDefaultEnabled,
        isFalse,
      );

      AppSettingsController.debugSetUserIdResolver(() => 'user-a');
      await AppSettingsController.restore(force: true);
      expect(
        AppSettingsController.state.defaultCampus,
        AppSettingsState.defaultCampusLoyola,
      );
      expect(
        AppSettingsController.state.wheelchairRoutingDefaultEnabled,
        isTrue,
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

    test(
      'primary returns high contrast primary when high contrast is enabled',
      () {
        expect(
          AppUiColors.primary(highContrastEnabled: true),
          AppUiColors.highContrastPrimary,
        );
      },
    );
  });
}
