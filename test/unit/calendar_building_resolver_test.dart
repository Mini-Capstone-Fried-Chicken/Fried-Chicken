import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/calendar/services/calendar_building_resolver.dart';

void main() {
  group('resolveBuildingCode', () {
    test('returns empty string for null input', () {
      expect(resolveBuildingCode(null), '');
    });

    test('returns empty string for empty input', () {
      expect(resolveBuildingCode(''), '');
      expect(resolveBuildingCode('   '), '');
    });

    test('resolves special H code from dash room format', () {
      expect(resolveBuildingCode('H-937'), 'HALL');
    });

    test('resolves special H code from spaced room format', () {
      expect(resolveBuildingCode('H 937'), 'HALL');
    });

    test('resolves MB from spaced room format', () {
      expect(resolveBuildingCode('MB 2.130'), 'MB');
    });

    test('resolves EV from dash room format', () {
      expect(resolveBuildingCode('EV-1.162'), 'EV');
    });

    test('resolves by full building name', () {
      expect(resolveBuildingCode('Hall Building'), 'HALL');
    });

    test('resolves by exact building code', () {
      expect(resolveBuildingCode('MB'), 'MB');
    });

    test('resolves by lowercase building name', () {
      expect(resolveBuildingCode('hall building'), 'HALL');
    });

    test('returns empty string for unknown building', () {
      expect(resolveBuildingCode('Some Random Place'), '');
    });
  });

  group('extractBuildingQuery', () {
    test('extracts building token from dash format', () {
      expect(extractBuildingQuery('H-937'), 'HALL');
      expect(extractBuildingQuery('MB-2.130'), 'MB');
    });

    test('extracts building token from spaced format', () {
      expect(extractBuildingQuery('H 937'), 'HALL');
      expect(extractBuildingQuery('EV 1.162'), 'EV');
    });

    test('returns normalized full value when no room pattern exists', () {
      expect(extractBuildingQuery('Hall Building'), 'HALL BUILDING');
      expect(extractBuildingQuery('MB'), 'MB');
    });
  });

  group('normalizeSpecialBuildingCode', () {
    test('maps H to HALL', () {
      expect(normalizeSpecialBuildingCode('H'), 'HALL');
      expect(normalizeSpecialBuildingCode(' h '), 'HALL');
    });

    test('keeps other building codes uppercase', () {
      expect(normalizeSpecialBuildingCode('mb'), 'MB');
      expect(normalizeSpecialBuildingCode(' ev '), 'EV');
    });
  });

  group('normalizeBuildingValue', () {
    test('removes spaces, punctuation, and lowercases text', () {
      expect(normalizeBuildingValue('Hall Building'), 'hallbuilding');
      expect(normalizeBuildingValue('MB-2.130'), 'mb2130');
      expect(normalizeBuildingValue(' EV 1.162 '), 'ev1162');
    });
  });
}
