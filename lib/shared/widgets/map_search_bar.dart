import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../data/search_suggestion.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../features/settings/app_settings.dart';
import '../../data/building_polygons.dart';
import '../../features/saved/saved_place.dart';
import '../../features/saved/saved_place_metadata_service.dart';
import '../../features/saved/saved_places_controller.dart';
import '../../services/google_places_service.dart';

const Color burgundy = Color(0xFF76263D);

class MapSearchBar extends StatefulWidget {
  final String campusLabel;
  final TextEditingController? controller;
  final Function(String)? onSubmitted;
  final List<SearchSuggestion>? suggestions;
  final Function(SearchSuggestion)? onSuggestionSelected;
  final VoidCallback? onFocus;
  final String? selectedBuildingCode;
  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final Function(String, String)? onDestinationRoomSubmitted;
  final Function(String, String)? onOriginRoomSubmitted;
  final Function(String buildingCode)? isConcordiaBuilding;
  final LatLng? userLocation;
  final String? currentBuildingCode;
  final bool showRoomFields;
  final bool highContrastMode;

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
    this.controller,
    this.onSubmitted,
    this.suggestions,
    this.onSuggestionSelected,
    this.onFocus,
    this.selectedBuildingCode,
    this.isConcordiaBuilding,
    required this.originRoomController,
    required this.destinationRoomController,
    this.onOriginRoomSubmitted,
    this.onDestinationRoomSubmitted,
    this.userLocation,
    this.currentBuildingCode,
    this.showRoomFields = false,
    this.highContrastMode = false,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  bool get _hasSuggestions => widget.suggestions?.isNotEmpty ?? false;

  bool get _isConcordiaBuilding =>
      widget.selectedBuildingCode != null &&
      widget.selectedBuildingCode!.isNotEmpty;

  bool get _isUserInConcordiaBuilding {
    if (widget.currentBuildingCode == null ||
        widget.currentBuildingCode!.isEmpty) {
      return false;
    }
    return widget.isConcordiaBuilding?.call(widget.currentBuildingCode!) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.originRoomController.addListener(_onRoomFieldChanged);
    widget.destinationRoomController.addListener(_onRoomFieldChanged);
    SavedPlacesController.notifier.addListener(_onSavedPlacesChanged);
    SavedPlacesController.ensureInitialized();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.originRoomController.removeListener(_onRoomFieldChanged);
    widget.destinationRoomController.removeListener(_onRoomFieldChanged);
    SavedPlacesController.notifier.removeListener(_onSavedPlacesChanged);
    super.dispose();
  }

  void _onSavedPlacesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onRoomFieldChanged() {
    /// Force rebuild if room text changes externally
    if (mounted) setState(() {});
  }

  void _updateSuggestionsVisibility() {
    final shouldShow = _focusNode.hasFocus && _hasSuggestions;

    if (_showSuggestions == shouldShow) return;

    setState(() {
      _showSuggestions = shouldShow;
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocus?.call();
    }
    _updateSuggestionsVisibility();
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    widget.controller?.text = suggestion.name;
    widget.onSuggestionSelected?.call(suggestion);
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
  }

  String? _savedIdForSuggestion(SearchSuggestion suggestion) {
    if (suggestion.isConcordiaBuilding) {
      return suggestion.buildingName?.code;
    }
    return suggestion.placeId;
  }

  bool _isSuggestionSaved(SearchSuggestion suggestion) {
    final id = _savedIdForSuggestion(suggestion);
    if (id == null || id.isEmpty) return false;
    return SavedPlacesController.isSaved(id);
  }

  Future<void> _toggleSuggestionSaved(SearchSuggestion suggestion) async {
    await SavedPlacesController.ensureInitialized();

    final existingId = _savedIdForSuggestion(suggestion);
    if (existingId != null && existingId.isNotEmpty && SavedPlacesController.isSaved(existingId)) {
      await SavedPlacesController.removePlace(existingId);
      return;
    }

    final placeToSave = await _buildSavedPlaceFromSuggestion(suggestion);
    if (placeToSave == null) return;

    final enriched = await SavedPlaceMetadataService.enrichFromGoogle(placeToSave);
    await SavedPlacesController.savePlace(enriched);
  }

  Future<SavedPlace?> _buildSavedPlaceFromSuggestion(
    SearchSuggestion suggestion,
  ) async {
    if (suggestion.isConcordiaBuilding) {
      final code = suggestion.buildingName?.code;
      if (code == null || code.isEmpty) return null;

      BuildingPolygon? building;
      for (final item in buildingPolygons) {
        if (item.code.toUpperCase() == code.toUpperCase()) {
          building = item;
          break;
        }
      }
      if (building == null) return null;

      return SavedPlace(
        id: code,
        name: suggestion.name,
        category: 'all',
        latitude: building.center.latitude,
        longitude: building.center.longitude,
        openingHoursToday: 'Open today: Hours unavailable',
      );
    }

    final placeId = suggestion.placeId;
    if (placeId == null || placeId.isEmpty) return null;

    final details = await GooglePlacesService.instance.getPlaceDetails(
      placeId,
      includeMetadata: true,
    );
    if (details == null) return null;

    return SavedPlace(
      id: placeId,
      name: details.name,
      category: 'all',
      latitude: details.location.latitude,
      longitude: details.location.longitude,
      openingHoursToday: 'Open today: Hours unavailable',
      googlePlaceType: details.primaryType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.highContrastMode
        ? AppUiColors.highContrastPrimary
      : burgundy;
    final primaryTextColor = widget.highContrastMode ? Colors.black : Colors.white;
    final hintTextColor = widget.highContrastMode
      ? Colors.black54
      : Colors.white70;

    final String hint = widget.campusLabel.trim().isEmpty
        ? "Search anywhere"
        : "Search anywhere near ${widget.campusLabel}";

    return TapRegion(
      onTapOutside: (_) {
        _focusNode.unfocus();
        _updateSuggestionsVisibility();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: barColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Main search field
                  TextField(
                    key: const Key('map_search_input'),
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: hintTextColor),
                      prefixIcon: Icon(Icons.search, color: primaryTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: widget.onSubmitted,
                    onChanged: (_) => _updateSuggestionsVisibility(),
                  ),
                  if (_isUserInConcordiaBuilding || _isConcordiaBuilding)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: RoomFieldsSection(
                        originBuildingCode: widget.currentBuildingCode,
                        destinationBuildingCode: widget.selectedBuildingCode,
                        originRoomController: widget.originRoomController,
                        destinationRoomController:
                            widget.destinationRoomController,
                        originEnabled: _isUserInConcordiaBuilding,
                        destinationEnabled: _isConcordiaBuilding,
                        onOriginRoomSubmitted: widget.onOriginRoomSubmitted,
                        onDestinationRoomSubmitted:
                            widget.onDestinationRoomSubmitted,
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// Suggestions dropdown
          if (_showSuggestions && _hasSuggestions)
            PointerInterceptor(
              child: Material(
                elevation: 4,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.suggestions!.length,
                    itemBuilder: (context, index) {
                      final suggestion = widget.suggestions![index];

                      return ListTile(
                        leading: Icon(
                          suggestion.isConcordiaBuilding
                              ? Icons.school
                              : Icons.place,
                          color: suggestion.isConcordiaBuilding
                              ? AppUiColors.primary(
                                highContrastEnabled: widget.highContrastMode,
                              )
                              : Colors.grey,
                          size: 20,
                        ),
                        title: Text(suggestion.name),
                        subtitle: suggestion.subtitle != null
                            ? Text(
                                suggestion.subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: suggestion.isConcordiaBuilding
                                      ? AppUiColors.primary(
                                          highContrastEnabled:
                                              widget.highContrastMode,
                                        ).withOpacity(0.7)
                                      : Colors.grey[600],
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          tooltip: _isSuggestionSaved(suggestion)
                              ? 'Remove from saved'
                              : 'Add to saved',
                          icon: Icon(
                            _isSuggestionSaved(suggestion)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 20,
                            color: _isSuggestionSaved(suggestion)
                                ? AppUiColors.primary(
                                    highContrastEnabled: widget.highContrastMode,
                                  )
                                : Colors.grey[700],
                          ),
                          onPressed: () => unawaited(_toggleSuggestionSaved(suggestion)),
                        ),
                        dense: true,
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
