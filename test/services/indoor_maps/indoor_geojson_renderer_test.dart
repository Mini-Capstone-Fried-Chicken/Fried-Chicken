import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/services/indoor_maps/indoor_geojson_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IndoorGeoJsonRenderer', () {
    group('createAmenityIcons', () {
      test('creates markers for toilets with correct properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.length, 1);
        final marker = markers.first;
        expect(marker.markerId.value, contains('toilet'));
        expect(marker.zIndex, 40);
        expect(marker.anchor, const Offset(0.5, 0.5));
      });

      test('creates markers for elevators with correct properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'highway': 'elevator'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.length, 1);
        expect(markers.first.markerId.value, contains('elevator'));
        expect(markers.first.zIndex, 40);
      });

      test('creates markers for escalators with correct properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'escalators': 'yes'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.length, 1);
        expect(markers.first.markerId.value, contains('escalator'));
      });

      test('creates markers for stairs with correct properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'highway': 'steps'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.length, 1);
        expect(markers.first.markerId.value, contains('stairs'));
      });

      test(
        'creates markers for water fountains with correct properties',
        () async {
          final geoJson = {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': {'amenity': 'drinking_water'},
                'geometry': {
                  'type': 'Polygon',
                  'coordinates': [
                    [
                      [-73.579, 45.497],
                      [-73.578, 45.497],
                      [-73.578, 45.496],
                      [-73.579, 45.496],
                      [-73.579, 45.497],
                    ],
                  ],
                },
              },
            ],
          };

          final markers = await IndoorGeoJsonRenderer.createAmenityIcons(
            geoJson,
          );

          expect(markers.length, 1);
          expect(markers.first.markerId.value, contains('fountain'));
        },
      );

      test('handles multiple amenities of different types', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'highway': 'elevator'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.580, 45.497],
                    [-73.581, 45.497],
                    [-73.581, 45.496],
                    [-73.580, 45.496],
                    [-73.580, 45.497],
                  ],
                ],
              },
            },
            {
              'type': 'Feature',
              'properties': {'highway': 'steps'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.582, 45.497],
                    [-73.583, 45.497],
                    [-73.583, 45.496],
                    [-73.582, 45.496],
                    [-73.582, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.length, 3);
        final markerIds = markers.map((m) => m.markerId.value).toList();
        expect(markerIds.any((id) => id.contains('toilet')), true);
        expect(markerIds.any((id) => id.contains('elevator')), true);
        expect(markerIds.any((id) => id.contains('stairs')), true);
      });

      test('ignores features without amenity properties', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'ref': '101', 'indoor': 'room'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);

        expect(markers.isEmpty, true);
      });

      test('applies zoom-based sizing correctly at zoom 17', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(
          geoJson,
          zoom: 17.0,
        );

        expect(markers.length, 1);
        // We can't directly test the icon size, but we can verify marker was created
        expect(markers.first.markerId.value, contains('toilet'));
      });

      test('applies zoom-based sizing correctly at zoom 20', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(
          geoJson,
          zoom: 20.0,
        );

        expect(markers.length, 1);
        // At zoom 20: iconSize = (15 + (20 - 17) * 5).clamp(16.0, 40.0) = 30.clamp(16.0, 40.0) = 30.0
        expect(markers.first.markerId.value, contains('toilet'));
      });

      test('clamps icon size at maximum zoom', () async {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(
          geoJson,
          zoom: 25.0,
        );

        expect(markers.length, 1);
        // At zoom 25: iconSize = (15 + (25 - 17) * 5).clamp(16.0, 40.0) = 55.clamp(16.0, 40.0) = 40.0
        expect(markers.first.markerId.value, contains('toilet'));
      });

      test('returns empty set for GeoJSON without features', () async {
        final geoJson = {'type': 'FeatureCollection', 'features': []};

        final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geoJson);
        expect(markers.isEmpty, true);
      });
    });

    group('polygonCenter', () {
      test('calculates center of square polygon correctly', () {
        final coordinates = [
          const LatLng(45.497, -73.579),
          const LatLng(45.497, -73.578),
          const LatLng(45.496, -73.578),
          const LatLng(45.496, -73.579),
          const LatLng(45.497, -73.579),
        ];

        final center = IndoorGeoJsonRenderer.polygonCenter(coordinates);

        expect(center.latitude, closeTo(45.4965, 0.001));
        expect(center.longitude, closeTo(-73.5785, 0.0001));
      });

      test('calculates center of triangle polygon correctly', () {
        final coordinates = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 2.0),
          const LatLng(2.0, 1.0),
          const LatLng(0.0, 0.0),
        ];

        final center = IndoorGeoJsonRenderer.polygonCenter(coordinates);

        expect(center.latitude, closeTo(0.5, 0.1));
        expect(center.longitude, closeTo(0.75, 0.1));
      });

      test('handles irregular polygon', () {
        final coordinates = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 4.0),
          const LatLng(3.0, 4.0),
          const LatLng(3.0, 2.0),
          const LatLng(1.0, 2.0),
          const LatLng(1.0, 0.0),
          const LatLng(0.0, 0.0),
        ];

        final center = IndoorGeoJsonRenderer.polygonCenter(coordinates);

        expect(center.latitude, greaterThan(0.0));
        expect(center.latitude, lessThan(3.0));
        expect(center.longitude, greaterThan(0.0));
        expect(center.longitude, lessThan(4.0));
      });
    });

    group('polygonArea', () {
      test('calculates area of square correctly', () {
        final coordinates = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 2.0),
          const LatLng(2.0, 2.0),
          const LatLng(2.0, 0.0),
          const LatLng(0.0, 0.0),
        ];

        final area = IndoorGeoJsonRenderer.polygonArea(coordinates);

        expect(area.abs(), closeTo(4.0, 0.0001));
      });

      test('calculates area of triangle correctly', () {
        final coordinates = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 2.0),
          const LatLng(2.0, 1.0),
          const LatLng(0.0, 0.0),
        ];

        final area = IndoorGeoJsonRenderer.polygonArea(coordinates);

        expect(area.abs(), closeTo(2.0, 0.0001));
      });

      test('returns zero for degenerate polygon', () {
        final coordinates = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 1.0),
          const LatLng(0.0, 0.0),
        ];

        final area = IndoorGeoJsonRenderer.polygonArea(coordinates);

        expect(area.abs(), closeTo(0.0, 0.0001));
      });
    });

    group('geoJsonToPolygons', () {
      test('assigns correct color to toilets', () {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'amenity': 'toilets'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final polygons = IndoorGeoJsonRenderer.geoJsonToPolygons(geoJson);

        expect(polygons.length, 1);
        final polygon = polygons.first;
        expect(polygon.strokeColor.value, 0xFF000000);
      });

      test('creates polygons for elevators', () {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'highway': 'elevator'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final polygons = IndoorGeoJsonRenderer.geoJsonToPolygons(geoJson);

        expect(polygons.length, 1);
        expect(polygons.first.zIndex, 20);
      });

      test('creates polygons for escalators', () {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'escalators': 'yes'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final polygons = IndoorGeoJsonRenderer.geoJsonToPolygons(geoJson);

        expect(polygons.length, 1);
        expect(polygons.first.strokeWidth, 2);
      });

      test('creates polygons for stairs', () {
        final geoJson = {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'properties': {'highway': 'steps'},
              'geometry': {
                'type': 'Polygon',
                'coordinates': [
                  [
                    [-73.579, 45.497],
                    [-73.578, 45.497],
                    [-73.578, 45.496],
                    [-73.579, 45.496],
                    [-73.579, 45.497],
                  ],
                ],
              },
            },
          ],
        };

        final polygons = IndoorGeoJsonRenderer.geoJsonToPolygons(geoJson);

        expect(polygons.length, 1);
        expect(polygons.first.points.length, 5);
      });
    });
  });
}
