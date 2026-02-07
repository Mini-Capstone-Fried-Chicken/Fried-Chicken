import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter_svg/flutter_svg.dart";

import "../../data/building_info.dart";

class IndoorPage extends StatelessWidget {
  final String id;        // e.g. "MB-1"
  final String assetPath; // exact path from map: svg or png

  const IndoorPage({
    super.key,
    required this.id,
    required this.assetPath,
  });

  bool get _isSvg => assetPath.toLowerCase().endsWith(".svg");

  // JSON naming rule: MB-1 -> mb1.json, LB-2 -> lb2.json, Hall-8 -> hall8.json
  String get _jsonPath {
    final normalized = id.trim().toLowerCase().replaceAll("-", "");
    return "assets/json/$normalized.json";
  }

  String get _buildingCode {
    final clean = id.trim();
    if (clean.contains("-")) return clean.split("-").first.toUpperCase();
    final m = RegExp(r"^([A-Za-z]+)").firstMatch(clean);
    return (m?.group(1) ?? clean).toUpperCase();
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<_FloorData?> _tryLoadFloorDataIfJsonExists() async {
    final exists = await _assetExists(_jsonPath);
    if (!exists) return null;

    final raw = await rootBundle.loadString(_jsonPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;

    double readNum(dynamic v, {double fallback = 0}) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final building = map["building"]?.toString() ?? _buildingCode;

    final refW = readNum(map["refWidth"], fallback: 1024);
    final refH = readNum(map["refHeight"], fallback: 1024);
    final svgW = readNum(map["svgWidth"], fallback: 1024);
    final svgH = readNum(map["svgHeight"], fallback: 1024);

    final flipHorizontally = (map["flipHorizontally"] == true);

    List<_PointItem> parsePoints(List<dynamic>? list, _PointType type) {
      final rawList = list ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) {
        final name = e["name"]?.toString() ?? "Unknown";
        final x = readNum(e["x"]);
        final y = readNum(e["y"]);

        // Convert ref coords -> svg coords
        final sx = (refW == 0) ? 1.0 : (svgW / refW);
        final sy = (refH == 0) ? 1.0 : (svgH / refH);

        return _PointItem(
          name: name,
          x: x * sx,
          y: y * sy,
          type: type,
        );
      }).toList();
    }

    final classrooms =
        parsePoints(map["classrooms"] as List<dynamic>?, _PointType.classroom);
    final poi = parsePoints(map["poi"] as List<dynamic>?, _PointType.poi);

    return _FloorData(
      building: building,
      svgW: svgW,
      svgH: svgH,
      flipHorizontally: flipHorizontally,
      items: [...classrooms, ...poi],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prettyTitle = "Indoor Map - ${id.trim()}";

    return Scaffold(
      appBar: AppBar(title: Text(prettyTitle)),
      body: FutureBuilder<_FloorData?>(
        future: _tryLoadFloorDataIfJsonExists(),
        builder: (context, snapshot) {
          final data = snapshot.data; // null => view-only mode

          // choose coordinate box size:
          final refW = data?.svgW ?? 1024.0;
          final refH = data?.svgH ?? 1024.0;

          final mapWidget = _isSvg
              ? SvgPicture.asset(assetPath, fit: BoxFit.fill)
              : Image.asset(assetPath, fit: BoxFit.fill);

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxW = constraints.maxWidth;
                final boxH = constraints.maxHeight;

                final scale = _containScale(
                  boxW: boxW,
                  boxH: boxH,
                  refW: refW,
                  refH: refH,
                );

                final drawW = refW * scale;
                final drawH = refH * scale;

                final offsetX = (boxW - drawW) / 2;
                final offsetY = (boxH - drawH) / 2;

                Widget stack = Stack(
                  children: [
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: drawW,
                      height: drawH,
                      child: Stack(
                        children: [
                          mapWidget,
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showBuildingInfo(
                                  context,
                                  data?.building ?? _buildingCode,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // markers if JSON exists
                    if (data != null)
                      for (final item in data.items)
                        Positioned(
                          left: offsetX + (item.x * scale) - 18,
                          top: offsetY + (item.y * scale) - 18,
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showInfo(context, item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: item.type == _PointType.classroom
                                    ? Colors.red.withOpacity(0.25)
                                    : Colors.blue.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: item.type == _PointType.classroom
                                      ? Colors.red.withOpacity(0.7)
                                      : Colors.blue.withOpacity(0.7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                );

                if (data?.flipHorizontally == true) {
                  stack = Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                    child: stack,
                  );
                }

                return SizedBox(width: boxW, height: boxH, child: stack);
              },
            ),
          );
        },
      ),
    );
  }

  static double _containScale({
    required double boxW,
    required double boxH,
    required double refW,
    required double refH,
  }) {
    final sX = boxW / refW;
    final sY = boxH / refH;
    return sX < sY ? sX : sY;
  }

  static void _showInfo(BuildContext context, _PointItem item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          item.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static void _showBuildingInfo(BuildContext context, String buildingCode) {
    final key = buildingCode.trim().toUpperCase();
    final BuildingInfo? info = buildingInfoByCode[key];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info?.name ?? key,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(info?.description ?? "No description yet."),
            const SizedBox(height: 12),
            Text("Campus: ${info?.campus ?? "Unknown"}"),
            const SizedBox(height: 8),
            Text(
              "Floors: ${info?.floors.isNotEmpty == true ? info!.floors.join(", ") : "N/A"}",
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorData {
  final String building;
  final double svgW;
  final double svgH;
  final bool flipHorizontally;
  final List<_PointItem> items;

  const _FloorData({
    required this.building,
    required this.svgW,
    required this.svgH,
    required this.flipHorizontally,
    required this.items,
  });
}

enum _PointType { classroom, poi }

class _PointItem {
  final String name;
  final double x;
  final double y;
  final _PointType type;

  const _PointItem({
    required this.name,
    required this.x,
    required this.y,
    required this.type,
  });
}
