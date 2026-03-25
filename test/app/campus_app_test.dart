import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/app/campus_app.dart';
import 'package:campus_app/app/app_shell.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class _MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppSettingsController.notifier.value = const AppSettingsState(
      largeTextModeEnabled: false,
      highContrastModeEnabled: false,
    );
    CampusAppState.debugAuthStateChangesProvider = null;
    CampusAppState.debugRestoreSettings = null;
    CampusAppState.debugReloadSavedPlaces = null;
  });

  tearDown(() {
    CampusAppState.debugAuthStateChangesProvider = null;
    CampusAppState.debugRestoreSettings = null;
    CampusAppState.debugReloadSavedPlaces = null;
  });

  // =========================================================================
  // Widget basics
  // =========================================================================
  group('CampusApp — widget basics', () {
    test('is a StatefulWidget', () {
      expect(const CampusApp(), isA<StatefulWidget>());
    });

    test('createState returns CampusAppState', () {
      expect(const CampusApp().createState(), isA<CampusAppState>());
    });

    test('createState returns a new instance on every call', () {
      final app = const CampusApp();
      final s1 = app.createState();
      final s2 = app.createState();
      expect(s1, isNot(same(s2)));
    });

    test('two separate CampusApp instances produce independent states', () {
      final s1 = const CampusApp().createState();
      final s2 = const CampusApp().createState();
      expect(s1, isNot(same(s2)));
    });

    // Crucially different from the old tests: the current code has NO
    // initState override, so createState must never throw.
    test('createState does not throw (no Firebase call at init)', () {
      expect(() => const CampusApp().createState(), returnsNormally);
    });
  });

  // =========================================================================
  // findAssetPath — exact-match (SVGs)
  // =========================================================================
  group('findAssetPath — exact match SVGs', () {
    late CampusAppState state;
    setUp(() => state = const CampusApp().createState() as CampusAppState);

    test('MB-1', () =>
        expect(state.findAssetPath('MB-1'), 'assets/indoor_svg/MB-1.svg'));
    test('MB-S2', () =>
        expect(state.findAssetPath('MB-S2'), 'assets/indoor_svg/MB-S2.svg'));
    test('Hall-8', () =>
        expect(state.findAssetPath('Hall-8'), 'assets/indoor_svg/Hall-8.svg'));
    test('Hall-9', () =>
        expect(state.findAssetPath('Hall-9'), 'assets/indoor_svg/Hall-9.svg'));
    test('VE-1', () =>
        expect(state.findAssetPath('VE-1'), 'assets/indoor_svg/VE-1.svg'));
    test('VE-2', () =>
        expect(state.findAssetPath('VE-2'), 'assets/indoor_svg/VE-2.svg'));
    test('VL-1', () =>
        expect(state.findAssetPath('VL-1'), 'assets/indoor_svg/VL-1.svg'));
    test('VL-2', () =>
        expect(state.findAssetPath('VL-2'), 'assets/indoor_svg/VL-2.svg'));
    test('h8 (lowercase key)', () =>
        expect(state.findAssetPath('h8'), 'assets/indoor_svg/h8.svg'));
  });

  // =========================================================================
  // findAssetPath — exact-match (PNGs)
  // =========================================================================
  group('findAssetPath — exact match PNGs', () {
    late CampusAppState state;
    setUp(() => state = const CampusApp().createState() as CampusAppState);

    test('CC1', () =>
        expect(state.findAssetPath('CC1'), 'assets/indoor_svg/CC1.png'));
    test('Hall-1', () =>
        expect(state.findAssetPath('Hall-1'), 'assets/indoor_svg/Hall-1.png'));
    test('Hall-2', () =>
        expect(state.findAssetPath('Hall-2'), 'assets/indoor_svg/Hall-2.png'));
    test('LB-2', () =>
        expect(state.findAssetPath('LB-2'), 'assets/indoor_svg/LB-2.png'));
    test('LB-3', () =>
        expect(state.findAssetPath('LB-3'), 'assets/indoor_svg/LB-3.png'));
    test('LB-4', () =>
        expect(state.findAssetPath('LB-4'), 'assets/indoor_svg/LB-4.png'));
    test('LB-5', () =>
        expect(state.findAssetPath('LB-5'), 'assets/indoor_svg/LB-5.png'));
  });

  // =========================================================================
  // findAssetPath — case-insensitive fallback (the `for` loop branch)
  // =========================================================================
  group('findAssetPath — case-insensitive fallback', () {
    late CampusAppState state;
    setUp(() => state = const CampusApp().createState() as CampusAppState);

    test('mb-1 → MB-1.svg', () =>
        expect(state.findAssetPath('mb-1'), 'assets/indoor_svg/MB-1.svg'));
    test('MB-S2 (exact) still resolves', () =>
        expect(state.findAssetPath('MB-S2'), 'assets/indoor_svg/MB-S2.svg'));
    test('mb-s2 → MB-S2.svg', () =>
        expect(state.findAssetPath('mb-s2'), 'assets/indoor_svg/MB-S2.svg'));
    test('HALL-8 → Hall-8.svg', () =>
        expect(state.findAssetPath('HALL-8'), 'assets/indoor_svg/Hall-8.svg'));
    test('hall-9 → Hall-9.svg', () =>
        expect(state.findAssetPath('hall-9'), 'assets/indoor_svg/Hall-9.svg'));
    test('ve-1 → VE-1.svg', () =>
        expect(state.findAssetPath('ve-1'), 'assets/indoor_svg/VE-1.svg'));
    test('ve-2 → VE-2.svg', () =>
        expect(state.findAssetPath('ve-2'), 'assets/indoor_svg/VE-2.svg'));
    test('vl-1 → VL-1.svg', () =>
        expect(state.findAssetPath('vl-1'), 'assets/indoor_svg/VL-1.svg'));
    test('vl-2 → VL-2.svg', () =>
        expect(state.findAssetPath('vl-2'), 'assets/indoor_svg/VL-2.svg'));
    // h8 is stored with lowercase key; 'H8' must use the fallback loop
    test('H8 → h8.svg (fallback loop)', () =>
        expect(state.findAssetPath('H8'), 'assets/indoor_svg/h8.svg'));
    test('cc1 → CC1.png', () =>
        expect(state.findAssetPath('cc1'), 'assets/indoor_svg/CC1.png'));
    test('hall-1 → Hall-1.png', () =>
        expect(state.findAssetPath('hall-1'), 'assets/indoor_svg/Hall-1.png'));
    test('hall-2 → Hall-2.png', () =>
        expect(state.findAssetPath('hall-2'), 'assets/indoor_svg/Hall-2.png'));
    test('lb-2 → LB-2.png', () =>
        expect(state.findAssetPath('lb-2'), 'assets/indoor_svg/LB-2.png'));
    test('lb-3 → LB-3.png', () =>
        expect(state.findAssetPath('lb-3'), 'assets/indoor_svg/LB-3.png'));
    test('lb-4 → LB-4.png', () =>
        expect(state.findAssetPath('lb-4'), 'assets/indoor_svg/LB-4.png'));
    test('lb-5 → LB-5.png', () =>
        expect(state.findAssetPath('lb-5'), 'assets/indoor_svg/LB-5.png'));
  });
 
  // =========================================================================
  // findAssetPath — null returns  (exercises the final `return null` line)
  // =========================================================================
  group('findAssetPath — returns null for unknown ids', () {
    late CampusAppState state;
    setUp(() => state = const CampusApp().createState() as CampusAppState);
 
    test('empty string', () => expect(state.findAssetPath(''), isNull));
    test('whitespace only', () => expect(state.findAssetPath('   '), isNull));
    test('completely unknown', () => expect(state.findAssetPath('UNKNOWN'), isNull));
    test('partial prefix "MB"', () => expect(state.findAssetPath('MB'), isNull));
    test('partial prefix "Hall"', () => expect(state.findAssetPath('Hall'), isNull));
    test('Hall-3 (not in map)', () => expect(state.findAssetPath('Hall-3'), isNull));
    test('LB-1 (not in map)', () => expect(state.findAssetPath('LB-1'), isNull));
    test('LB-6 (not in map)', () => expect(state.findAssetPath('LB-6'), isNull));
    test('MB-3 (not in map)', () => expect(state.findAssetPath('MB-3'), isNull));
    test('VE-3 (not in map)', () => expect(state.findAssetPath('VE-3'), isNull));
    test('numeric only "123"', () => expect(state.findAssetPath('123'), isNull));
    // Triggers the fallback loop and still returns null
    test('HALL-99 (fallback loop, still null)', () =>
        expect(state.findAssetPath('HALL-99'), isNull));
  });
 
  // =========================================================================
  // indoorAssetsById map integrity
  // =========================================================================
  group('indoorAssetsById map integrity', () {
    test('has exactly 16 entries (9 SVG + 7 PNG)', () =>
        expect(CampusAppState.indoorAssetsById.length, 16));
 
    test('every value ends with .svg or .png', () {
      for (final v in CampusAppState.indoorAssetsById.values) {
        expect(v.endsWith('.svg') || v.endsWith('.png'), isTrue,
            reason: '$v has unexpected extension');
      }
    });
 
    test('every value starts with assets/indoor_svg/', () {
      for (final v in CampusAppState.indoorAssetsById.values) {
        expect(v.startsWith('assets/indoor_svg/'), isTrue,
            reason: '$v has wrong prefix');
      }
    });
 
    test('all keys are non-empty strings', () {
      for (final k in CampusAppState.indoorAssetsById.keys) {
        expect(k.trim(), isNotEmpty);
      }
    });
 
    test('no duplicate keys', () {
      final keys = CampusAppState.indoorAssetsById.keys.toList();
      expect(keys.toSet().length, keys.length);
    });
 
    test('no duplicate values', () {
      final vals = CampusAppState.indoorAssetsById.values.toList();
      expect(vals.toSet().length, vals.length);
    });
 
    test('exactly 9 SVG entries', () {
      final count = CampusAppState.indoorAssetsById.values
          .where((v) => v.endsWith('.svg'))
          .length;
      expect(count, 9);
    });
 
    test('exactly 7 PNG entries', () {
      final count = CampusAppState.indoorAssetsById.values
          .where((v) => v.endsWith('.png'))
          .length;
      expect(count, 7);
    });
 
    test('contains all expected SVG keys', () {
      expect(
        CampusAppState.indoorAssetsById.keys,
        containsAll(['MB-1', 'MB-S2', 'Hall-8', 'Hall-9',
                      'VE-1', 'VE-2', 'VL-1', 'VL-2', 'h8']),
      );
    });
 
    test('contains all expected PNG keys', () {
      expect(
        CampusAppState.indoorAssetsById.keys,
        containsAll(['CC1', 'Hall-1', 'Hall-2', 'LB-2', 'LB-3', 'LB-4', 'LB-5']),
      );
    });
  });
 
  test('AppSettingsController reset in setUp uses immutable state updates', () {
    expect(AppSettingsController.state.largeTextModeEnabled, isFalse);
    expect(AppSettingsController.state.highContrastModeEnabled, isFalse);
  });

  group('CampusApp - auth and builder behavior', () {
    testWidgets('shows loading indicator while auth stream is waiting', (tester) async {
      final authStream = StreamController<User?>.broadcast();
      CampusAppState.debugAuthStateChangesProvider = () => authStream.stream;

      await tester.pumpWidget(const CampusApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await authStream.close();
    });

    testWidgets('shows SignInPage when auth stream emits null user', (tester) async {
      CampusAppState.debugAuthStateChangesProvider = () => Stream<User?>.value(null);

      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('shows AppShell when auth stream emits logged-in user', (tester) async {
      final user = _MockUser();
      CampusAppState.debugAuthStateChangesProvider = () => Stream<User?>.value(user);

      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(SignInPage), findsNothing);
      final shell = tester.widget<AppShell>(find.byType(AppShell));
      expect(shell.isLoggedIn, isTrue);
    });

    testWidgets('builder applies large text multiplier from settings notifier', (tester) async {
      CampusAppState.debugAuthStateChangesProvider = () => Stream<User?>.value(null);

      AppSettingsController.notifier.value = const AppSettingsState(
        largeTextModeEnabled: false,
        highContrastModeEnabled: false,
      );
      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      double maxScaleFromMediaQueries() {
        final scales = tester
            .widgetList<MediaQuery>(find.byType(MediaQuery))
            .map((mq) => mq.data.textScaler.scale(1.0))
            .toList();
        scales.sort();
        return scales.last;
      }

      final normalScale = maxScaleFromMediaQueries();

      AppSettingsController.notifier.value = const AppSettingsState(
        largeTextModeEnabled: true,
        highContrastModeEnabled: false,
      );
      await tester.pump();

      final largeScale = maxScaleFromMediaQueries();
      expect(largeScale, greaterThan(normalScale));
      expect(largeScale / normalScale, closeTo(1.4, 0.01));
    });

    testWidgets('auth listener triggers side effects and is cancelled on dispose', (tester) async {
      final authStream = StreamController<User?>.broadcast();
      var restoreCalls = 0;
      var reloadCalls = 0;

      CampusAppState.debugAuthStateChangesProvider = () => authStream.stream;
      CampusAppState.debugRestoreSettings = ({bool force = false}) async {
        expect(force, isTrue);
        restoreCalls += 1;
      };
      CampusAppState.debugReloadSavedPlaces = () async {
        reloadCalls += 1;
      };

      await tester.pumpWidget(const CampusApp());

      authStream.add(null);
      await tester.pump();
      expect(restoreCalls, 1);
      expect(reloadCalls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      authStream.add(null);
      await tester.pump();
      expect(restoreCalls, 1);
      expect(reloadCalls, 1);

      await authStream.close();
    });
  });
}
