import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../data/building_polygons.dart';
import '../../../features/indoor/data/building_info.dart';
import '../../../shared/widgets/building_info_popup.dart';

class OutdoorBuildingPopup extends StatelessWidget {
  final BuildingPolygon building;
  final Offset position;

  final Map<String, BuildingInfo> buildingInfoByCode;
  final String? debugLinkOverride;

  final VoidCallback onClose;
  final Future<void> Function() onIndoorMap;
  final Future<void> Function() onGetDirections;
  final Future<void> Function(String url) onOpenLink;

  final bool isLoggedIn;

  const OutdoorBuildingPopup({
    super.key,
    required this.building,
    required this.position,
    required this.buildingInfoByCode,
    required this.debugLinkOverride,
    required this.onClose,
    required this.onIndoorMap,
    required this.onGetDirections,
    required this.onOpenLink,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final info = buildingInfoByCode[building.code];

    final title = '${info?.name ?? building.name} - ${building.code}';
    final description = info?.description ?? 'No description available.';
    final accessibility = info?.accessibility ?? false;
    final facilities = info?.facilities ?? const [];

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: PointerInterceptor(
        child: BuildingInfoPopup(
          title: title,
          description: description,
          accessibility: accessibility,
          facilities: facilities,
          onMore: () {
            final link = debugLinkOverride ?? (info?.link ?? '');
            onOpenLink(link);
          },
          onClose: onClose,
          isLoggedIn: isLoggedIn,
          onIndoorMap: onIndoorMap,
          onGetDirections: onGetDirections,
        ),
      ),
    );
  }
}