import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/indoor/data/indoor_id_parser.dart';

void main() {
  group('parseIndoorId', () {
    test('returns UNKNOWN for empty string', () {
      final result = parseIndoorId('');
      expect(result.buildingCode, 'UNKNOWN');
      expect(result.floor, isNull);
    });

    test('parses special shorthand "h8" (case-insensitive)', () {
      final result1 = parseIndoorId('h8');
      final result2 = parseIndoorId('H8');
      expect(result1.buildingCode, 'HALL');
      expect(result1.floor, '8');
      expect(result2.buildingCode, 'HALL');
      expect(result2.floor, '8');
    });

    test('parses hyphenated input', () {
      final result = parseIndoorId('A-1');
      expect(result.buildingCode, 'A');
      expect(result.floor, '1');
    });

    test('parses hyphenated input with multiple parts', () {
      final result = parseIndoorId('B-2-3');
      expect(result.buildingCode, 'B');
      expect(result.floor, '2-3');
    });

    test('parses compact input', () {
      final result = parseIndoorId('C4');
      expect(result.buildingCode, 'C');
      expect(result.floor, '4');
    });

    test('parses compact input with lowercase', () {
      final result = parseIndoorId('d12');
      expect(result.buildingCode, 'D');
      expect(result.floor, '12');
    });

    test('fallback for unknown format', () {
      final result = parseIndoorId('random');
      expect(result.buildingCode, 'RANDOM');
      expect(result.floor, isNull);
    });

    test('trims whitespace', () {
      final result = parseIndoorId('  E5  ');
      expect(result.buildingCode, 'E');
      expect(result.floor, '5');
    });

    test('hyphenated input with extra hyphens', () {
      final result = parseIndoorId('--F--6--');
      expect(result.buildingCode, 'F');
      expect(result.floor, '6');
    });

    test('hyphenated input with only building', () {
      final result = parseIndoorId('G-');
      expect(result.buildingCode, 'G');
      expect(result.floor, isNull);
    });
  });
}