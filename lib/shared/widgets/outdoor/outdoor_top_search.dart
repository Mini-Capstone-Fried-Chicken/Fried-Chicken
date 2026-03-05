import 'package:flutter/material.dart';
import '../../../shared/widgets/map_search_bar.dart';
import '../../../shared/widgets/indoor_floor_dropdown.dart';
import '../../../services/indoor_maps/indoor_floor_config.dart';
import '../../../data/search_suggestion.dart';

class OutdoorTopSearch extends StatelessWidget {
  final String campusLabel;
  final TextEditingController controller;

  final void Function(String) onSubmitted;
  final List<SearchSuggestion> suggestions;
  final void Function(SearchSuggestion) onSuggestionSelected;
  final VoidCallback onFocus;

  final bool showIndoor;
  final List<IndoorFloorOption> floors;
  final String? selectedAssetPath;
  final Future<void> Function(String assetPath) onFloorChanged;

  const OutdoorTopSearch({
    super.key,
    required this.campusLabel,
    required this.controller,
    required this.onSubmitted,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.onFocus,
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