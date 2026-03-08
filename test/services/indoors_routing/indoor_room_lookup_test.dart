import 'package:campus_app/services/indoors_routing/core/indoor_routing_models.dart';
import 'package:campus_app/services/indoors_routing/routing/indoor_room_lookup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('IndoorRoomLookup', () {
    final lookup = IndoorRoomLookup();
    final polygon = <LatLng>[
      const LatLng(45, -73),
      const LatLng(45, -72.9999),
      const LatLng(45.0001, -72.9999),
      const LatLng(45.0001, -73),
      const LatLng(45, -73),
    ];

    test('indexes room nodes and normalizes lookups', () {
      final nodes = <IndoorRoutingNode>[
        IndoorRoutingNode(
          id: 1,
          nodeType: IndoorRoutingNodeType.room,
          roomCode: 'H-920',
          transitionType: null,
          level: '9',
          center: const LatLng(45.0, -73.0),
          polygonPoints: polygon,
        ),
        IndoorRoutingNode(
          id: 2,
          nodeType: IndoorRoutingNodeType.corridor,
          roomCode: null,
          transitionType: null,
          level: '9',
          center: const LatLng(45.0, -72.9999),
          polygonPoints: polygon,
        ),
      ];

      final index = lookup.indexByRoomCode(nodes);

      expect(lookup.findRoomNode(index, ' h-920 ')?.id, 1);
      expect(lookup.findRoomCenter(index, 'H-920'), const LatLng(45.0, -73.0));
      expect(lookup.findRoomNode(index, ''), isNull);
      expect(lookup.findRoomNode(index, 'UNKNOWN'), isNull);
    });
  });
}
