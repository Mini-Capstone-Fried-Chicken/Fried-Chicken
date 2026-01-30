import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter_svg/flutter_svg.dart";

class IndoorPage extends StatelessWidget {
  const IndoorPage({super.key});

  Future<_FloorData> _loadMB1Data() async {
    final raw = await rootBundle.loadString("assets/json/mb1.json");
    final map = jsonDecode(raw) as Map<String, dynamic>;

    double readNum(dynamic v, {double fallback = 0}) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final building = map["building"]?.toString() ?? "MB";
    final floor = map["floor"]?.toString() ?? "MB1";

    // Coordinate system your JSON points were taken from (yellow reference map size)
    final refW = readNum(map["refWidth"], fallback: 1024);
    final refH = readNum(map["refHeight"], fallback: 1024);

    // The SVG coordinate system (from your SVG header width/height)
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

            // Convert from ref coords -> svg coords
            final sx = (refW == 0) ? 1.0 : (svgW / refW);
            final sy = (refH == 0) ? 1.0 : (svgH / refH);

            return _PointItem(
              name: name,
              x: x * sx,
              y: y * sy,
              type: type,
            );
          })
          .toList();
    }

    final classrooms =
        parsePoints(map["classrooms"] as List<dynamic>?, _PointType.classroom);
    final poi = parsePoints(map["poi"] as List<dynamic>?, _PointType.poi);

    return _FloorData(
      building: building,
      floor: floor,
      svgW: svgW,
      svgH: svgH,
      flipHorizontally: flipHorizontally,
      items: [...classrooms, ...poi],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Indoor Map - MB1")),
      body: FutureBuilder<_FloorData>(
        future: _loadMB1Data(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxW = constraints.maxWidth;
                final boxH = constraints.maxHeight;

                // Fit the SVG coordinate box (svgW x svgH) into available space
                final scale = _containScale(
                  boxW: boxW,
                  boxH: boxH,
                  refW: data.svgW,
                  refH: data.svgH,
                );

                final drawW = data.svgW * scale;
                final drawH = data.svgH * scale;

                final offsetX = (boxW - drawW) / 2;
                final offsetY = (boxH - drawH) / 2;

                Widget stack = Stack(
                  children: [
                    // SVG floorplan (red)
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: drawW,
                      height: drawH,
                      child: SvgPicture.asset(
                        "assets/indoor_svg/MB-1.svg",
                        fit: BoxFit.fill,
                      ),
                    ),

                    // Points (clickable)
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

                // Flip entire layer (SVG + points) so your JSON coords stay the same
                if (data.flipHorizontally) {
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
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          item.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FloorData {
  final String building;
  final String floor;
  final double svgW;
  final double svgH;
  final bool flipHorizontally;
  final List<_PointItem> items;

  const _FloorData({
    required this.building,
    required this.floor,
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
