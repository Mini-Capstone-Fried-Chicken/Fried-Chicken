import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/search_suggestion.dart';
import '../../../services/indoor_maps/indoor_floor_config.dart';
import '../../../shared/widgets/indoor_floor_dropdown.dart';
import '../../../shared/widgets/map_search_bar.dart';

class OutdoorTopSearch extends StatelessWidget {
  final String campusLabel;
  final TextEditingController controller;
  final bool highContrastMode;

  final void Function(String) onSubmitted;
  final List<SearchSuggestion> suggestions;
  final void Function(SearchSuggestion) onSuggestionSelected;
  final VoidCallback onFocus;

  final bool showIndoor;
  final List<IndoorFloorOption> floors;
  final String? selectedAssetPath;
  final Future<void> Function(String assetPath) onFloorChanged;

  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final void Function(String buildingCode, String roomCode)
  onOriginRoomSubmitted;
  final void Function(String buildingCode, String roomCode)
  onDestinationRoomSubmitted;

  final String? selectedBuildingCode;
  final String? currentBuildingCode;
  final LatLng? userLocation;
  final bool Function(String buildingCode) isConcordiaBuilding;

  const OutdoorTopSearch({
    super.key,
    required this.campusLabel,
    required this.controller,
    this.highContrastMode = false,
    required this.onSubmitted,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.onFocus,
    required this.originRoomController,
    required this.destinationRoomController,
    required this.onOriginRoomSubmitted,
    required this.onDestinationRoomSubmitted,
    required this.selectedBuildingCode,
    required this.currentBuildingCode,
    required this.userLocation,
    required this.isConcordiaBuilding,
    required this.showIndoor,
    required this.floors,
    required this.selectedAssetPath,
    required this.onFloorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 65,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MapSearchBar(
            key: const Key('destination_search_bar'),
            campusLabel: campusLabel,
            controller: controller,
            onSubmitted: onSubmitted,
            suggestions: suggestions,
            onSuggestionSelected: onSuggestionSelected,
            onFocus: onFocus,
            originRoomController: originRoomController,
            destinationRoomController: destinationRoomController,
            onOriginRoomSubmitted: onOriginRoomSubmitted,
            onDestinationRoomSubmitted: onDestinationRoomSubmitted,
            selectedBuildingCode: selectedBuildingCode,
            currentBuildingCode: showIndoor
                ? selectedBuildingCode
                : currentBuildingCode,
            userLocation: userLocation,
            isConcordiaBuilding: isConcordiaBuilding,
            highContrastMode: highContrastMode,
            showRoomFields:
                showIndoor && (selectedBuildingCode?.isNotEmpty ?? false),
          ),
          if (showIndoor && floors.isNotEmpty) ...[
            const SizedBox(height: 10),
            IndoorFloorDropdown(
              visible: showIndoor,
              floors: floors,
              selectedAssetPath: selectedAssetPath,
              onChanged: (asset) async => onFloorChanged(asset),
            ),
          ],
        ],
      ),
    );
  }
}
