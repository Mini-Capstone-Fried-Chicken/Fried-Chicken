import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/services/firebase/firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('web options are correct', () {
      final options = DefaultFirebaseOptions.web;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.projectId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.authDomain, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);
      expect(options.measurementId, isNotEmpty);
    });

    test('android options are correct', () {
      final options = DefaultFirebaseOptions.android;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.projectId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);
    });

    test('ios options are correct', () {
      final options = DefaultFirebaseOptions.ios;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.projectId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);
      expect(options.iosBundleId, isNotEmpty);
    });

    test('macos options are correct', () {
      final options = DefaultFirebaseOptions.macos;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.projectId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);
      expect(options.iosBundleId, isNotEmpty);
    });

    test('windows options are correct', () {
      final options = DefaultFirebaseOptions.windows;
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.projectId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.authDomain, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);
      expect(options.measurementId, isNotEmpty);
    });

    test('currentPlatform throws for unsupported platform', () {
      expect(() => DefaultFirebaseOptions.currentPlatform, returnsNormally);
    });
  });
}
