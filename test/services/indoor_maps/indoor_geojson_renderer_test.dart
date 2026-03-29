import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:campus_app/services/indoor_maps/indoor_geojson_renderer.dart';

void main() {
  group('IndoorGeoJsonRenderer.geoJsonToPolygons', () {
    Map<String, dynamic> _feature({
      required String type,
      required dynamic coordinates,
      Map<String, dynamic>? props,
    }) {
      return {
        "type": "Feature",
        "properties": props ?? {},
        "geometry": {"type": type, "coordinates": coordinates},
      };
    }

    // A simple square polygon ring (GeoJSON uses [lng, lat])
    List<dynamic> _squareRing({
      double lng = -73.0,
      double lat = 45.0,
      double d = 0.0001,
    }) {
      return [
        [lng, lat],
        [lng + d, lat],
        [lng + d, lat + d],
        [lng, lat + d],
        [lng, lat], // closed ring
      ];
    }

    test('creates one Polygon for a valid Polygon feature', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "H1"},
          ),
        ],
      };

      final polys = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson);

      expect(polys, hasLength(1));
      final poly = polys.first;

      expect(poly.polygonId.value, 'indoor-H1');
      expect(poly.points.length, greaterThanOrEqualTo(3));

      // sanity: first point converted to LatLng(lat, lng)
      expect(poly.points.first.latitude, closeTo(45.0, 1e-9));
      expect(poly.points.first.longitude, closeTo(-73.0, 1e-9));
    });

    test('skips non-Polygon geometry types', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Point",
            coordinates: [-73.0, 45.0],
            props: {"ref": "X"},
          ),
        ],
      };

      final polys = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson);
      expect(polys, isEmpty);
    });

    test('skips polygons with less than 3 points', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [
              [
                [-73.0, 45.0],
                [-73.0, 45.0],
              ],
            ],
            props: {"ref": "tiny"},
          ),
        ],
      };

      final polys = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson);
      expect(polys, isEmpty);
    });

    test('sets fillColor green for escalators=yes', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "E1", "escalators": "yes"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(poly.fillColor.value, Colors.green.withOpacity(1.0).value);
    });

    test('sets fillColor orange for highway=elevator', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "L1", "highway": "elevator"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(poly.fillColor.value, Colors.orange.withOpacity(1.0).value);
    });

    test('sets fillColor purple for highway=steps', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "S1", "highway": "steps"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(poly.fillColor.value, Colors.purple.withOpacity(1.0).value);
    });

    test('sets fillColor blue for amenity=toilets', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "T1", "amenity": "toilets"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(poly.fillColor.value, Colors.blue.withOpacity(1.0).value);
    });

    test('sets corridor fill color when indoor=corridor', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "C1", "indoor": "corridor"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(
        poly.fillColor.value,
        const Color.fromARGB(255, 232, 122, 149).withOpacity(1.0).value,
      );
    });

    test('uses default burgundy for other features', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"ref": "D1"},
          ),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      expect(
        poly.fillColor.value,
        const Color(0xFF800020).withOpacity(1.0).value,
      );
    });

    test('uses fallback id when ref is missing', () {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(type: "Polygon", coordinates: [_squareRing()], props: {}),
        ],
      };

      final poly = IndoorGeoJsonRenderer.geoJsonToPolygons(geojson).first;
      // fallback uses polygons.length at the time -> starts at 0
      expect(poly.polygonId.value, 'indoor-0');
    });
  });

  group('IndoorGeoJsonRenderer.createAmenityIcons', () {
    Map<String, dynamic> _feature({
      required String type,
      required dynamic coordinates,
      Map<String, dynamic>? props,
    }) {
      return {
        "type": "Feature",
        "properties": props ?? {},
        "geometry": {"type": type, "coordinates": coordinates},
      };
    }

    List<dynamic> _squareRing({
      double lng = -73.0,
      double lat = 45.0,
      double d = 0.0001,
    }) {
      return [
        [lng, lat],
        [lng + d, lat],
        [lng + d, lat + d],
        [lng, lat + d],
        [lng, lat],
      ];
    }

    test('returns empty when features is missing or not a List', () async {
      final markers = await IndoorGeoJsonRenderer.createAmenityIcons({
        "type": "FeatureCollection",
        "features": "not-a-list",
      });

      expect(markers, isEmpty);
    });

    test('skips invalid features and non-amenities', () async {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          "bad-feature",
          {
            "type": "Feature",
            "properties": {"amenity": "toilets"},
            "geometry": "bad-geometry",
          },
          {
            "type": "Feature",
            "properties": {"amenity": "toilets"},
            "geometry": {
              "type": "Point",
              "coordinates": [-73.0, 45.0],
            },
          },
          {
            "type": "Feature",
            "properties": {"indoor": "room"},
            "geometry": {
              "type": "Polygon",
              "coordinates": [_squareRing()],
            },
          },
          {
            "type": "Feature",
            "properties": {"amenity": "toilets"},
            "geometry": {"type": "Polygon", "coordinates": []},
          },
          {
            "type": "Feature",
            "properties": {"amenity": "toilets"},
            "geometry": {
              "type": "Polygon",
              "coordinates": ["bad-outer"],
            },
          },
          {
            "type": "Feature",
            "properties": {"amenity": "toilets"},
            "geometry": {
              "type": "Polygon",
              "coordinates": [
                [
                  "bad-point",
                  [1],
                  [-73.0, 45.0],
                ],
              ],
            },
          },
        ],
      };

      final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geojson);
      expect(markers, isEmpty);
    });

    test('creates amenity markers for all label branches', () async {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing(lat: 45.0000)],
            props: {"amenity": "toilets"},
          ),
          _feature(
            type: "Polygon",
            coordinates: [_squareRing(lat: 45.0010)],
            props: {"highway": "elevator"},
          ),
          _feature(
            type: "Polygon",
            coordinates: [_squareRing(lat: 45.0020)],
            props: {"highway": "steps"},
          ),
          _feature(
            type: "Polygon",
            coordinates: [_squareRing(lat: 45.0030)],
            props: {"escalators": "yes"},
          ),
          _feature(
            type: "Polygon",
            coordinates: [_squareRing(lat: 45.0040)],
            props: {"amenity": "cafe"},
          ),
        ],
      };

      final markers = await IndoorGeoJsonRenderer.createAmenityIcons(geojson);

      expect(markers, hasLength(5));

      final titles = markers.map((m) => m.infoWindow.title).toSet();
      expect(
        titles,
        containsAll(<String?>[
          'toilets',
          'elevator',
          'steps',
          'escalator',
          'cafe',
        ]),
      );

      for (final marker in markers) {
        expect(marker.markerId.value, startsWith('amenity-'));
        expect(marker.zIndexInt, 25);
        expect(marker.anchor, const Offset(0.5, 0.5));
        expect(marker.flat, isTrue);
      }
    });

    test('reuses cached icon on subsequent calls', () async {
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          _feature(
            type: "Polygon",
            coordinates: [_squareRing()],
            props: {"amenity": "toilets"},
          ),
        ],
      };

      final first = await IndoorGeoJsonRenderer.createAmenityIcons(geojson);
      final second = await IndoorGeoJsonRenderer.createAmenityIcons(geojson);

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(first.first.icon, same(second.first.icon));
    });
  });
}
