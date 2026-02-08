class ValidationUtils {
  /// Validates email format
  static String? validateEmail(String email) {
    final trimmed = email.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return 'Please enter a valid email address.';
    }

    if (!trimmed.contains('@')) {
      return 'Please enter a valid email address.';
    }

    return null; // No error
  }

  /// Validates password length
  static String? validatePassword(String password) {
    if (password.length < 3) {
      return 'Password must be at least 3 characters.';
    }

    return null; // No error
  }

  /// Validates name is not empty
  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Please enter your name.';
    }

    return null; // No error
  }

  /// Validates passwords match
  static String? validatePasswordsMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }

    return null; // No error
  }
}
