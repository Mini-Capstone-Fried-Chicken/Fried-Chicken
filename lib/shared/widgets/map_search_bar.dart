import 'dart:async';

import 'package:campus_app/services/indoors_routing/core/indoor_route_plan_models.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../data/building_polygons.dart';
import '../../data/search_suggestion.dart';
import '../../features/saved/saved_place.dart';
import '../../features/saved/saved_place_metadata_service.dart';
import '../../features/saved/saved_places_controller.dart';
import '../../features/settings/app_settings.dart';
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
  final IndoorTransitionMode? selectedTransitionMode;
  final ValueChanged<IndoorTransitionMode?>? onTransitionModeChanged;
  final Function(String buildingCode)? isConcordiaBuilding;
  final LatLng? userLocation;
  final String? currentBuildingCode;
  final bool showRoomFields;
  final bool highContrastMode;
  final GooglePlacesService? placesService;
  final bool wheelchairRoutingDefaultEnabled;

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
    this.selectedTransitionMode,
    this.onTransitionModeChanged,
    this.userLocation,
    this.currentBuildingCode,
    this.showRoomFields = false,
    this.highContrastMode = false,
    this.placesService,
    this.wheelchairRoutingDefaultEnabled = false,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  static const String _actionSuggestionPrefix = '__action_';

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

  bool _isActionSuggestion(SearchSuggestion suggestion) {
    final placeId = suggestion.placeId;
    if (placeId == null) return false;
    return placeId.startsWith(_actionSuggestionPrefix);
  }

  Future<void> _toggleSuggestionSaved(SearchSuggestion suggestion) async {
    await SavedPlacesController.ensureInitialized();

    final existingId = _savedIdForSuggestion(suggestion);
    if (existingId != null &&
        existingId.isNotEmpty &&
        SavedPlacesController.isSaved(existingId)) {
      await SavedPlacesController.removePlace(existingId);
      return;
    }

    final placeToSave = await _buildSavedPlaceFromSuggestion(suggestion);
    if (placeToSave == null) return;

    final enriched = await SavedPlaceMetadataService.enrichFromGoogle(
      placeToSave,
    );
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

    final placesService = widget.placesService ?? GooglePlacesService.instance;
    final details = await placesService.getPlaceDetails(
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

  String _searchHint() {
    final label = widget.campusLabel.trim();
    if (label.isEmpty) {
      return 'Search anywhere';
    }
    return 'Search anywhere near $label';
  }

  Widget _buildSearchPanel({
    required Color barColor,
    required Color primaryTextColor,
    required Color hintTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: barColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('map_search_input'),
              controller: widget.controller,
              focusNode: _focusNode,
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                hintText: _searchHint(),
                hintStyle: TextStyle(color: hintTextColor),
                prefixIcon: Icon(Icons.search, color: primaryTextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: widget.onSubmitted,
              onChanged: (_) => _updateSuggestionsVisibility(),
            ),
            if (_shouldShowRoomFields()) _buildRoomFieldsSection(),
          ],
        ),
      ),
    );
  }

  bool _shouldShowRoomFields() {
    return _isUserInConcordiaBuilding || _isConcordiaBuilding;
  }

  Widget _buildRoomFieldsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: RoomFieldsSection(
        originBuildingCode: widget.currentBuildingCode,
        destinationBuildingCode: widget.selectedBuildingCode,
        originRoomController: widget.originRoomController,
        destinationRoomController: widget.destinationRoomController,
        originEnabled: _isUserInConcordiaBuilding,
        destinationEnabled: _isConcordiaBuilding,
        onOriginRoomSubmitted: widget.onOriginRoomSubmitted,
        onDestinationRoomSubmitted: widget.onDestinationRoomSubmitted,
        selectedTransitionMode: widget.selectedTransitionMode,
        onTransitionModeChanged: widget.onTransitionModeChanged,
        wheelchairRoutingDefaultEnabled: widget.wheelchairRoutingDefaultEnabled,
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    if (!(_showSuggestions && _hasSuggestions)) {
      return const SizedBox.shrink();
    }

    return PointerInterceptor(
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
              return _buildSuggestionTile(suggestion);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(SearchSuggestion suggestion) {
    final isActionSuggestion = _isActionSuggestion(suggestion);
    final isSaved = _isSuggestionSaved(suggestion);
    final IconData suggestionIcon;
    if (isActionSuggestion) {
      suggestionIcon = Icons.directions;
    } else if (suggestion.isConcordiaBuilding) {
      suggestionIcon = Icons.school;
    } else {
      suggestionIcon = Icons.place;
    }
    final saveTooltip = isSaved ? 'Remove from saved' : 'Add to saved';
    final bookmarkIcon = isSaved ? Icons.bookmark : Icons.bookmark_border;
    final Color? bookmarkColor;
    if (isSaved) {
      bookmarkColor = AppUiColors.primary(
        highContrastEnabled: widget.highContrastMode,
      );
    } else {
      bookmarkColor = Colors.grey[700];
    }
    final Widget? trailingWidget;
    if (isActionSuggestion) {
      trailingWidget = null;
    } else {
      trailingWidget = IconButton(
        tooltip: saveTooltip,
        icon: Icon(bookmarkIcon, size: 20, color: bookmarkColor),
        onPressed: () => unawaited(_toggleSuggestionSaved(suggestion)),
      );
    }

    return ListTile(
      leading: Icon(
        suggestionIcon,
        color: suggestion.isConcordiaBuilding
            ? AppUiColors.primary(highContrastEnabled: widget.highContrastMode)
            : Colors.grey,
        size: 20,
      ),
      title: Row(
        children: [
          Expanded(child: Text(suggestion.name)),
          if (isActionSuggestion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppUiColors.primary(
                  highContrastEnabled: widget.highContrastMode,
                ).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Recommended',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppUiColors.primary(
                    highContrastEnabled: widget.highContrastMode,
                  ),
                ),
              ),
            ),
        ],
      ),
      subtitle: _buildSuggestionSubtitle(suggestion),
      trailing: trailingWidget,
      dense: true,
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  Widget? _buildSuggestionSubtitle(SearchSuggestion suggestion) {
    final subtitle = suggestion.subtitle;
    if (subtitle == null) {
      return null;
    }

    final Color? subtitleColor;
    if (suggestion.isConcordiaBuilding) {
      subtitleColor = AppUiColors.primary(
        highContrastEnabled: widget.highContrastMode,
      ).withValues(alpha: 0.7);
    } else {
      subtitleColor = Colors.grey[600];
    }

    return Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor));
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.highContrastMode
        ? AppUiColors.highContrastPrimary
        : burgundy;
    final primaryTextColor = widget.highContrastMode
        ? Colors.black
        : Colors.white;
    final hintTextColor = widget.highContrastMode
        ? Colors.black54
        : Colors.white70;

    return TapRegion(
      onTapOutside: (_) {
        _focusNode.unfocus();
        _updateSuggestionsVisibility();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchPanel(
            barColor: barColor,
            primaryTextColor: primaryTextColor,
            hintTextColor: hintTextColor,
          ),
          _buildSuggestionsDropdown(),
        ],
      ),
    );
  }
}
