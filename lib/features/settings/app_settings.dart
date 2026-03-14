import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class AppSettingsState {
  final bool accessibilityModeEnabled;
  final bool highContrastModeEnabled;

  const AppSettingsState({
    this.accessibilityModeEnabled = false,
    this.highContrastModeEnabled = false,
  });

  AppSettingsState copyWith({
    bool? accessibilityModeEnabled,
    bool? highContrastModeEnabled,
  }) {
    return AppSettingsState(
      accessibilityModeEnabled:
          accessibilityModeEnabled ?? this.accessibilityModeEnabled,
      highContrastModeEnabled:
          highContrastModeEnabled ?? this.highContrastModeEnabled,
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
    );
  }

  static void setHighContrastMode(bool enabled) {
    if (!state.accessibilityModeEnabled && enabled) {
      return;
    }
    notifier.value = state.copyWith(highContrastModeEnabled: enabled);
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
