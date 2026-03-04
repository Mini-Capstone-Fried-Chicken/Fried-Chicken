import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/utils/login_helper.dart';

void main() {
  group('ValidationUtils.validateEmail', () {
    test('returns error for empty email', () {
      expect(
        ValidationUtils.validateEmail(''),
        equals('Please enter a valid email address.'),
      );
    });

    test('returns error for email without @', () {
      expect(
        ValidationUtils.validateEmail('invalidemail'),
        equals('Please enter a valid email address.'),
      );
    });

    test('returns null for valid email', () {
      expect(
        ValidationUtils.validateEmail('user@example.com'),
        isNull,
      );
    });

    test('trims whitespace and converts to lowercase', () {
      expect(
        ValidationUtils.validateEmail('  USER@EXAMPLE.COM  '),
        isNull,
      );
    });
  });

  group('ValidationUtils.validatePassword', () {
    test('returns error for password less than 6 characters', () {
      expect(
        ValidationUtils.validatePassword('12'),
        equals('Password must be at least 6 characters.'),
      );
    });

    test('returns null for password with 6+ characters', () {
      expect(
        ValidationUtils.validatePassword('123456'),
        isNull,
      );
    });

    test('returns null for long password', () {
      expect(
        ValidationUtils.validatePassword('securepassword123'),
        isNull,
      );
    });
  });

  group('ValidationUtils.validateName', () {
    test('returns error for empty name', () {
      expect(
        ValidationUtils.validateName(''),
        equals('Please enter your name.'),
      );
    });

    test('returns error for whitespace-only name', () {
      expect(
        ValidationUtils.validateName('   '),
        equals('Please enter your name.'),
      );
    });

    test('returns null for valid name', () {
      expect(
        ValidationUtils.validateName('John Doe'),
        isNull,
      );
    });
  });

  group('ValidationUtils.validatePasswordsMatch', () {
    test('returns error when passwords do not match', () {
      expect(
        ValidationUtils.validatePasswordsMatch('password123', 'password456'),
        equals('Passwords do not match.'),
      );
    });

    test('returns null when passwords match', () {
      expect(
        ValidationUtils.validatePasswordsMatch('password123', 'password123'),
        isNull,
      );
    });
  });
}
