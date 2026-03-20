import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppSettingsState {
  final bool accessibilityModeEnabled;
  final bool highContrastModeEnabled;
  final bool largeTextModeEnabled;
  final bool calendarAccessEnabled;

  const AppSettingsState({
    this.accessibilityModeEnabled = false,
    this.highContrastModeEnabled = false,
    this.largeTextModeEnabled = false,
    this.calendarAccessEnabled = true,
  });

  AppSettingsState copyWith({
    bool? accessibilityModeEnabled,
    bool? highContrastModeEnabled,
    bool? largeTextModeEnabled,
    bool? calendarAccessEnabled,
  }) {
    return AppSettingsState(
      accessibilityModeEnabled:
          accessibilityModeEnabled ?? this.accessibilityModeEnabled,
      highContrastModeEnabled:
          highContrastModeEnabled ?? this.highContrastModeEnabled,
      largeTextModeEnabled: largeTextModeEnabled ?? this.largeTextModeEnabled,
      calendarAccessEnabled:
          calendarAccessEnabled ?? this.calendarAccessEnabled,
    );
  }
}

class AppSettingsController {
  static const String _accessibilityModeEnabledKey =
      'settings_accessibility_mode_enabled';
  static const String _highContrastModeEnabledKey =
      'settings_high_contrast_mode_enabled';
  static const String _largeTextModeEnabledKey =
      'settings_large_text_mode_enabled';
  static const String _calendarAccessEnabledKey =
      'settings_calendar_access_enabled';

  static final ValueNotifier<AppSettingsState> notifier =
      ValueNotifier(const AppSettingsState());

  static AppSettingsState get state => notifier.value;

  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      notifier.value = AppSettingsState(
        accessibilityModeEnabled:
            prefs.getBool(_accessibilityModeEnabledKey) ?? false,
        highContrastModeEnabled:
            prefs.getBool(_highContrastModeEnabledKey) ?? false,
        largeTextModeEnabled: prefs.getBool(_largeTextModeEnabledKey) ?? false,
        calendarAccessEnabled: prefs.getBool(_calendarAccessEnabledKey) ?? true,
      );
    } catch (_) {
      // Keep defaults when persistence isn't available.
      notifier.value = const AppSettingsState();
    }
  }

  static void _updateState(AppSettingsState newState) {
    notifier.value = newState;
    unawaited(_persist(newState));
  }

  static Future<void> _persist(AppSettingsState newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        _accessibilityModeEnabledKey,
        newState.accessibilityModeEnabled,
      );
      await prefs.setBool(
        _highContrastModeEnabledKey,
        newState.highContrastModeEnabled,
      );
      await prefs.setBool(_largeTextModeEnabledKey, newState.largeTextModeEnabled);
      await prefs.setBool(
        _calendarAccessEnabledKey,
        newState.calendarAccessEnabled,
      );
    } catch (_) {
      // Ignore persistence failures and keep in-memory state.
    }
  }

  static void setAccessibilityMode(bool enabled) {
    _updateState(state.copyWith(
      accessibilityModeEnabled: enabled,
      highContrastModeEnabled: enabled ? state.highContrastModeEnabled : false,
      largeTextModeEnabled: enabled ? state.largeTextModeEnabled : false,
    ));
  }

  static void setHighContrastMode(bool enabled) {
    if (!state.accessibilityModeEnabled && enabled) {
      return;
    }
    _updateState(state.copyWith(highContrastModeEnabled: enabled));
  }

  static void setLargeTextMode(bool enabled) {
    if (!state.accessibilityModeEnabled && enabled) {
      return;
    }
    _updateState(state.copyWith(largeTextModeEnabled: enabled));
  }

  static void setCalendarAccess(bool enabled) {
    _updateState(state.copyWith(calendarAccessEnabled: enabled));
  }
}

class AppUiColors {
  static const Color defaultPrimary = Color(0xFF76263D);
  static const Color highContrastPrimary = Color(0xFF89D9C2);
  static const Color highContrastRoutePreview = Color(0xFFA6FF05);
  static const Color highContrastBuildingHighlight = Color(0xFF999665);

  static Color primary({required bool highContrastEnabled}) {
    return highContrastEnabled ? highContrastPrimary : defaultPrimary;
  }
}
