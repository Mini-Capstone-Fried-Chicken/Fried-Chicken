import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/nearby_poi_service.dart';
import 'package:campus_app/services/poi_icon_factory.dart';

// ---------------------------------------------------------------------------
// Minimal 1×1 transparent PNG bytes (valid PNG, usable as a fake asset)
// ---------------------------------------------------------------------------
final Uint8List _minimalPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk length + type
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // bit depth, color type, ...
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, // IEND
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

/// Registers a fake asset for [path] backed by [_minimalPng].
void _registerFakeAsset(String path) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        return _minimalPng.buffer.asByteData();
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register fake assets for all four categories before any test runs
  setUpAll(() {
    for (final path in [
      'assets/images/cafe.png',
      'assets/images/restaurant.png',
      'assets/images/pharmacy.png',
      'assets/images/depanneur.png',
    ]) {
      _registerFakeAsset(path);
    }
  });

  // Clear the internal cache before each test so tests are independent
  setUp(() {
    PoiIconFactory.clearCacheForTesting();
  });

  group('PoiIconFactory._assetPaths', () {
    test('has an entry for every PoiCategory', () {
      for (final category in PoiCategory.values) {
        expect(
          PoiIconFactory.assetPathForTesting(category),
          isNotNull,
          reason: 'Missing asset path for $category',
        );
      }
    });

    test('all asset paths end with .png', () {
      for (final category in PoiCategory.values) {
        expect(PoiIconFactory.assetPathForTesting(category), endsWith('.png'));
      }
    });

    test('cafe uses cafe.png', () {
      expect(
        PoiIconFactory.assetPathForTesting(PoiCategory.cafe),
        contains('cafe'),
      );
    });

    test('restaurant uses restaurant.png', () {
      expect(
        PoiIconFactory.assetPathForTesting(PoiCategory.restaurant),
        contains('restaurant'),
      );
    });

    test('pharmacy uses pharmacy.png', () {
      expect(
        PoiIconFactory.assetPathForTesting(PoiCategory.pharmacy),
        contains('pharmacy'),
      );
    });

    test('depanneur uses depanneur.png', () {
      expect(
        PoiIconFactory.assetPathForTesting(PoiCategory.depanneur),
        contains('depanneur'),
      );
    });
  });

  group('PoiIconFactory._bgColor', () {
    test('background colour is burgundy', () {
      expect(
        PoiIconFactory.bgColorForTesting.value,
        equals(const Color(0xFF76263D).value),
      );
    });
  });

  group('PoiIconFactory.iconFor', () {
    testWidgets('returns a BitmapDescriptor for each category', (tester) async {
      for (final category in PoiCategory.values) {
        final descriptor = await PoiIconFactory.iconFor(category);
        expect(descriptor, isA<BitmapDescriptor>());
      }
    });

    testWidgets('caches result — second call returns same instance', (
      tester,
    ) async {
      final first = await PoiIconFactory.iconFor(PoiCategory.cafe);
      final second = await PoiIconFactory.iconFor(PoiCategory.cafe);
      expect(identical(first, second), isTrue);
    });

    testWidgets('different categories return different descriptors', (
      tester,
    ) async {
      final cafe = await PoiIconFactory.iconFor(PoiCategory.cafe);
      final pharmacy = await PoiIconFactory.iconFor(PoiCategory.pharmacy);
      // They won't be identical objects
      expect(identical(cafe, pharmacy), isFalse);
    });
  });

  group('PoiIconFactory.preloadAll', () {
    testWidgets('populates cache for all categories', (tester) async {
      await PoiIconFactory.preloadAll();

      for (final category in PoiCategory.values) {
        expect(
          PoiIconFactory.isCachedForTesting(category),
          isTrue,
          reason: '$category should be cached after preloadAll',
        );
      }
    });
  });
}
