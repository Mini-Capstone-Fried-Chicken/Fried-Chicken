import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";

import "../../data/building_info.dart";
import "../../data/indoor_id_parser.dart";

class IndoorMapViewerPage extends StatelessWidget {
  final String assetPath;
  final String title;

  const IndoorMapViewerPage({
    super.key,
    required this.assetPath,
    required this.title,
  });

  bool get _isSvg => assetPath.toLowerCase().endsWith(".svg");

  @override
  Widget build(BuildContext context) {
    final id = _extractId(title);
    final parsed = parseIndoorId(id);

    final buildingKey = parsed.buildingCode.toUpperCase();
    final BuildingInfo? info = buildingInfoByCode[buildingKey];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 6,
        child: Center(
          child: Stack(
            children: [
              _isSvg
                  ? SvgPicture.asset(assetPath, fit: BoxFit.contain)
                  : Image.asset(assetPath, fit: BoxFit.contain),

              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showPopup(
                      context,
                      buildingKey,
                      parsed.floor,
                      info,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractId(String title) {
    const prefix = "Indoor Map - ";
    return title.startsWith(prefix)
        ? title.substring(prefix.length).trim()
        : title.trim();
  }

  static void _showPopup(
    BuildContext context,
    String buildingKey,
    String? floor,
    BuildingInfo? info,
  ) {
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
              info?.name ?? buildingKey,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (floor != null) ...[
              const SizedBox(height: 6),
              Text("Floor: $floor"),
            ],
            const SizedBox(height: 10),
            Text(info?.description ?? "No description available."),
            const SizedBox(height: 12),
            Text("Campus: ${info?.campus ?? "Unknown"}"),
            const SizedBox(height: 8),
            Text(
              "Floors available: ${info?.floors.isNotEmpty == true ? info!.floors.join(", ") : "N/A"}",
            ),
          ],
        ),
      ),
    );
  }
}
