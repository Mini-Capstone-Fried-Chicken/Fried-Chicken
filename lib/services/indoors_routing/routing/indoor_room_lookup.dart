import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/indoor_routing_models.dart';

class IndoorRoomLookup {
  const IndoorRoomLookup();

  String normalizeRoomCode(String roomCode) {
    return roomCode.trim().toUpperCase();
  }

  Map<String, IndoorRoutingNode> indexByRoomCode(
    List<IndoorRoutingNode> nodes,
  ) {
    final byRoomCode = <String, IndoorRoutingNode>{};

    for (final node in nodes) {
      if (node.nodeType != IndoorRoutingNodeType.room) continue;
      final code = node.roomCode;
      if (code == null || code.isEmpty) continue;
      byRoomCode[code] = node;
    }

    return byRoomCode;
  }

  IndoorRoutingNode? findRoomNode(
    Map<String, IndoorRoutingNode> byRoomCode,
    String roomCode,
  ) {
    final normalized = normalizeRoomCode(roomCode);
    if (normalized.isEmpty) return null;
    return byRoomCode[normalized];
  }

  LatLng? findRoomCenter(
    Map<String, IndoorRoutingNode> byRoomCode,
    String roomCode,
  ) {
    return findRoomNode(byRoomCode, roomCode)?.center;
  }
}
