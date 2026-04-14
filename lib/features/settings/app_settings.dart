import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AppSettingsState {
  static const String defaultCampusSgw = 'SGW';
  static const String defaultCampusLoyola = 'Loyola';

  final bool accessibilityModeEnabled;
  final bool wheelchairRoutingDefaultEnabled;
  final bool highContrastModeEnabled;
  final bool largeTextModeEnabled;
  final bool calendarAccessEnabled;
  final String defaultCampus;

  const AppSettingsState({
    this.accessibilityModeEnabled = false,
    this.wheelchairRoutingDefaultEnabled = false,
    this.highContrastModeEnabled = false,
    this.largeTextModeEnabled = false,
    this.calendarAccessEnabled = true,
    this.defaultCampus = defaultCampusSgw,
  });

  AppSettingsState copyWith({
    bool? accessibilityModeEnabled,
    bool? wheelchairRoutingDefaultEnabled,
    bool? highContrastModeEnabled,
    bool? largeTextModeEnabled,
    bool? calendarAccessEnabled,
    String? defaultCampus,
  }) {
    return AppSettingsState(
      accessibilityModeEnabled:
          accessibilityModeEnabled ?? this.accessibilityModeEnabled,
      wheelchairRoutingDefaultEnabled:
          wheelchairRoutingDefaultEnabled ??
          this.wheelchairRoutingDefaultEnabled,
      highContrastModeEnabled:
          highContrastModeEnabled ?? this.highContrastModeEnabled,
      largeTextModeEnabled: largeTextModeEnabled ?? this.largeTextModeEnabled,
      calendarAccessEnabled:
          calendarAccessEnabled ?? this.calendarAccessEnabled,
      defaultCampus: defaultCampus ?? this.defaultCampus,
    );
  }
}

class AppSettingsController {
  static const String _anonymousScope = 'anonymous';
  static const String _accessibilityModeEnabledKey =
      'settings_accessibility_mode_enabled';
  static const String _wheelchairRoutingDefaultEnabledKey =
      'settings_wheelchair_routing_default_enabled';
  static const String _highContrastModeEnabledKey =
      'settings_high_contrast_mode_enabled';
  static const String _largeTextModeEnabledKey =
      'settings_large_text_mode_enabled';
  static const String _calendarAccessEnabledKey =
      'settings_calendar_access_enabled';
  static const String _defaultCampusKey = 'settings_default_campus';

  static final ValueNotifier<AppSettingsState> notifier = ValueNotifier(
    const AppSettingsState(),
  );

  static bool _initialized = false;
  static int _persistGeneration = 0;
  static String _activeScope = _anonymousScope;
  static String? Function() _userIdResolver = _defaultUserIdResolver;

  static AppSettingsState get state => notifier.value;

  static String? _defaultUserIdResolver() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String _scope() {
    final userId = _userIdResolver();
    if (userId == null || userId.isEmpty) {
      return _anonymousScope;
    }
    return userId;
  }

  static String _scopedKey(String baseKey, {String? scope}) {
    return '${baseKey}__${scope ?? _scope()}';
  }

  static Future<void> restore({bool force = false}) async {
    final scope = _scope();
    if (!force && _initialized && _activeScope == scope) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      notifier.value = AppSettingsState(
        accessibilityModeEnabled: _getScopedBool(
          prefs,
          _accessibilityModeEnabledKey,
          scope,
          fallback: false,
        ),
        wheelchairRoutingDefaultEnabled: _getScopedBool(
          prefs,
          _wheelchairRoutingDefaultEnabledKey,
          scope,
          fallback: false,
        ),
        highContrastModeEnabled: _getScopedBool(
          prefs,
          _highContrastModeEnabledKey,
          scope,
          fallback: false,
        ),
        largeTextModeEnabled: _getScopedBool(
          prefs,
          _largeTextModeEnabledKey,
          scope,
          fallback: false,
        ),
        calendarAccessEnabled: _getScopedBool(
          prefs,
          _calendarAccessEnabledKey,
          scope,
          fallback: true,
        ),
        defaultCampus: _normalizeDefaultCampus(
          _getScopedString(prefs, _defaultCampusKey, scope),
        ),
      );
      _initialized = true;
      _activeScope = scope;
    } catch (_) {
      // Keep defaults when persistence isn't available.
      notifier.value = const AppSettingsState();
      _initialized = true;
      _activeScope = scope;
    }
  }

  static void _updateState(AppSettingsState newState) {
    notifier.value = newState;
    final generation = ++_persistGeneration;
    unawaited(_persist(newState, generation));
  }

  static Future<void> _persist(
    AppSettingsState newState,
    int generation,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (generation != _persistGeneration) {
        return;
      }
      final scope = _scope();

      await prefs.setBool(
        _scopedKey(_accessibilityModeEnabledKey, scope: scope),
        newState.accessibilityModeEnabled,
      );
      await prefs.setBool(
        _scopedKey(_wheelchairRoutingDefaultEnabledKey, scope: scope),
        newState.wheelchairRoutingDefaultEnabled,
      );
      await prefs.setBool(
        _scopedKey(_highContrastModeEnabledKey, scope: scope),
        newState.highContrastModeEnabled,
      );
      await prefs.setBool(
        _scopedKey(_largeTextModeEnabledKey, scope: scope),
        newState.largeTextModeEnabled,
      );
      await prefs.setBool(
        _scopedKey(_calendarAccessEnabledKey, scope: scope),
        newState.calendarAccessEnabled,
      );
      await prefs.setString(
        _scopedKey(_defaultCampusKey, scope: scope),
        _normalizeDefaultCampus(newState.defaultCampus),
      );
    } catch (_) {
      // Ignore persistence failures and keep in-memory state.
    }
  }

  static String _normalizeDefaultCampus(String? value) {
    if (value == AppSettingsState.defaultCampusLoyola) {
      return AppSettingsState.defaultCampusLoyola;
    }
    return AppSettingsState.defaultCampusSgw;
  }

  static bool _getScopedBool(
    SharedPreferences prefs,
    String baseKey,
    String scope, {
    required bool fallback,
  }) {
    final scoped = _scopedKey(baseKey, scope: scope);
    if (prefs.containsKey(scoped)) {
      return prefs.getBool(scoped) ?? fallback;
    }
    if (prefs.containsKey(baseKey)) {
      return prefs.getBool(baseKey) ?? fallback;
    }
    return fallback;
  }

  static String? _getScopedString(
    SharedPreferences prefs,
    String baseKey,
    String scope,
  ) {
    final scoped = _scopedKey(baseKey, scope: scope);
    if (prefs.containsKey(scoped)) {
      return prefs.getString(scoped);
    }
    if (prefs.containsKey(baseKey)) {
      return prefs.getString(baseKey);
    }
    return null;
  }

  @visibleForTesting
  static void debugSetUserIdResolver(String? Function() resolver) {
    _userIdResolver = resolver;
    _initialized = false;
  }

  @visibleForTesting
  static void debugResetUserIdResolver() {
    _userIdResolver = _defaultUserIdResolver;
    _initialized = false;
  }

  static void setAccessibilityMode(bool enabled) {
    _updateState(
      state.copyWith(
        accessibilityModeEnabled: enabled,
        wheelchairRoutingDefaultEnabled: enabled
            ? state.wheelchairRoutingDefaultEnabled
            : false,
        highContrastModeEnabled: enabled
            ? state.highContrastModeEnabled
            : false,
        largeTextModeEnabled: enabled ? state.largeTextModeEnabled : false,
      ),
    );
  }

  static void setWheelchairRoutingDefault(bool enabled) {
    _updateState(state.copyWith(wheelchairRoutingDefaultEnabled: enabled));
  }

  static void setHighContrastMode(bool enabled) {
    _updateState(state.copyWith(highContrastModeEnabled: enabled));
  }

  static void setLargeTextMode(bool enabled) {
    _updateState(state.copyWith(largeTextModeEnabled: enabled));
  }

  static void setCalendarAccess(bool enabled) {
    _updateState(state.copyWith(calendarAccessEnabled: enabled));
  }

  static void setDefaultCampus(String campus) {
    _updateState(
      state.copyWith(defaultCampus: _normalizeDefaultCampus(campus)),
    );
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
