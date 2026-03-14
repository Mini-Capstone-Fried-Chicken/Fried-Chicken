import 'package:flutter/material.dart';

@immutable
class AppSettingsState {
  final bool accessibilityModeEnabled;
  final bool highContrastModeEnabled;
  final bool largeTextModeEnabled;

  const AppSettingsState({
    this.accessibilityModeEnabled = false,
    this.highContrastModeEnabled = false,
    this.largeTextModeEnabled = false,
  });

  AppSettingsState copyWith({
    bool? accessibilityModeEnabled,
    bool? highContrastModeEnabled,
    bool? largeTextModeEnabled,
  }) {
    return AppSettingsState(
      accessibilityModeEnabled:
          accessibilityModeEnabled ?? this.accessibilityModeEnabled,
      highContrastModeEnabled:
          highContrastModeEnabled ?? this.highContrastModeEnabled,
      largeTextModeEnabled: largeTextModeEnabled ?? this.largeTextModeEnabled,
    );
  }
}

class AppSettingsController {
  static final ValueNotifier<AppSettingsState> notifier =
      ValueNotifier(const AppSettingsState());

  static AppSettingsState get state => notifier.value;

  static void setAccessibilityMode(bool enabled) {
    notifier.value = state.copyWith(
      accessibilityModeEnabled: enabled,
      highContrastModeEnabled: enabled ? state.highContrastModeEnabled : false,
      largeTextModeEnabled: enabled ? state.largeTextModeEnabled : false,
    );
  }

  static void setHighContrastMode(bool enabled) {
    if (!state.accessibilityModeEnabled && enabled) {
      return;
    }
    notifier.value = state.copyWith(highContrastModeEnabled: enabled);
  }

  static void setLargeTextMode(bool enabled) {
    if (!state.accessibilityModeEnabled && enabled) {
      return;
    }
    notifier.value = state.copyWith(largeTextModeEnabled: enabled);
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
