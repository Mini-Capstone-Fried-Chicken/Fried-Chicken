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
            coordinates: [
              _squareRing(),
            ],
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
          _feature(type: "Point", coordinates: [-73.0, 45.0], props: {"ref": "X"}),
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

    test('sets fillColor pink for highway=steps', () {
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
      expect(poly.fillColor.value, Colors.pink.withOpacity(1.0).value);
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
      expect(poly.fillColor.value, const Color(0xFF800020).withOpacity(1.0).value);
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
}