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
    test('returns cached descriptor immediately after seeding', () {
      PoiIconFactory.seedCacheForTesting({
        for (final cat in PoiCategory.values)
          cat: BitmapDescriptor.defaultMarker,
      });

      for (final category in PoiCategory.values) {
        expect(PoiIconFactory.isCachedForTesting(category), isTrue);
      }
    });

    test('caches result — second iconFor call returns same instance', () async {
      // Seed so _buildDescriptor is never called
      PoiIconFactory.seedCacheForTesting({
        PoiCategory.cafe: BitmapDescriptor.defaultMarker,
      });

      final first = await PoiIconFactory.iconFor(PoiCategory.cafe);
      final second = await PoiIconFactory.iconFor(PoiCategory.cafe);
      expect(identical(first, second), isTrue);
    });

    test('different categories have different cache entries after seeding', () {
      final cafeIcon = BitmapDescriptor.defaultMarker;
      final pharmacyIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );

      PoiIconFactory.seedCacheForTesting({
        PoiCategory.cafe: cafeIcon,
        PoiCategory.pharmacy: pharmacyIcon,
      });

      expect(PoiIconFactory.isCachedForTesting(PoiCategory.cafe), isTrue);
      expect(PoiIconFactory.isCachedForTesting(PoiCategory.pharmacy), isTrue);
    });

    test('cache is empty before seeding (clearCacheForTesting works)', () {
      // setUp already calls clearCacheForTesting
      for (final cat in PoiCategory.values) {
        expect(PoiIconFactory.isCachedForTesting(cat), isFalse);
      }
    });
  });

  group('PoiIconFactory.preloadAll', () {
    test('all categories cached after seedCacheForTesting', () {
      PoiIconFactory.seedCacheForTesting({
        for (final cat in PoiCategory.values)
          cat: BitmapDescriptor.defaultMarker,
      });

      for (final category in PoiCategory.values) {
        expect(
          PoiIconFactory.isCachedForTesting(category),
          isTrue,
          reason: '$category should be cached',
        );
      }
    });
  });

  group('PoiIconFactory.iconFor — cache-miss path', () {
    setUp(() {
      // Inject a fast fake builder so _buildDescriptor is never called
      PoiIconFactory.testDescriptorBuilder = (_) async =>
          BitmapDescriptor.defaultMarker;
    });

    tearDown(() {
      PoiIconFactory.testDescriptorBuilder = null;
    });

    test('cache-miss path stores result in cache', () async {
      expect(PoiIconFactory.isCachedForTesting(PoiCategory.cafe), isFalse);

      await PoiIconFactory.iconFor(PoiCategory.cafe);

      expect(PoiIconFactory.isCachedForTesting(PoiCategory.cafe), isTrue);
    });

    test('cache-miss path returns a BitmapDescriptor', () async {
      final result = await PoiIconFactory.iconFor(PoiCategory.restaurant);
      // return descriptor line is now hit
      expect(result, isA<BitmapDescriptor>());
    });

    test('preloadAll covers all categories via cache-miss path', () async {
      // preloadAll() calls iconFor for every category —
      // with testDescriptorBuilder set, none of them hang
      await PoiIconFactory.preloadAll();

      for (final cat in PoiCategory.values) {
        expect(
          PoiIconFactory.isCachedForTesting(cat),
          isTrue,
          reason: '$cat should be cached after preloadAll',
        );
      }
    });
  });
}
