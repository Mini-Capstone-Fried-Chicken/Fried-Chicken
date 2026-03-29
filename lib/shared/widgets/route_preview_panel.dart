import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import 'package:flutter/material.dart';

import '../../data/search_suggestion.dart';
import '../../features/settings/app_settings.dart';
import '../../services/location/shuttle_route_service.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';
import '../../services/indoors_routing/core/indoor_route_plan_models.dart';

enum RouteTravelMode { driving, walking, bicycling, transit, shuttle }

extension RouteTravelModeX on RouteTravelMode {
  String get apiValue {
    switch (this) {
      case RouteTravelMode.driving:
        return 'driving';
      case RouteTravelMode.walking:
        return 'walking';
      case RouteTravelMode.bicycling:
        return 'bicycling';
      case RouteTravelMode.transit:
        return 'transit';
      case RouteTravelMode.shuttle:
        return 'shuttle';
    }
  }

  String get label {
    switch (this) {
      case RouteTravelMode.driving:
        return 'Driving';
      case RouteTravelMode.walking:
        return 'Walking';
      case RouteTravelMode.bicycling:
        return 'Biking';
      case RouteTravelMode.transit:
        return 'Transit';
      case RouteTravelMode.shuttle:
        return 'Shuttle';
    }
  }
}

class RoutePreviewPanel extends StatefulWidget {
  final String originText;
  final String destinationText;
  final VoidCallback onClose;
  final VoidCallback onSwitch;
  final Function(String) onOriginChanged;
  final Function(String) onDestinationChanged;
  final Function(SearchSuggestion) onOriginSelected;
  final Function(SearchSuggestion) onDestinationSelected;
  final List<SearchSuggestion> originSuggestions;
  final List<SearchSuggestion> destinationSuggestions;
  final String? originBuildingCode;
  final String? currentBuildingCode;
  final String? destinationBuildingCode;
  final Function(String buildingCode)? isConcordiaBuilding;
  final bool isOriginPoi;
  final bool isDestinationPoi;
  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final Function(String buildingCode, String roomCode)? onStartValid;
  final Function(String buildingCode, String roomCode)? onDestinationValid;
  final Function(String buildingCode, String roomCode)?
  onDestinationRoomSubmitted;
  final Function(String, String)? onOriginRoomSubmitted;
  final IndoorMapRepository? indoorRepository;
  final bool highContrastMode;
  final IndoorTransitionMode? selectedTransitionMode;
  final ValueChanged<IndoorTransitionMode?>? onTransitionModeChanged;
  final bool wheelchairRoutingDefaultEnabled;

  const RoutePreviewPanel({
    super.key,
    required this.originText,
    required this.destinationText,
    required this.onClose,
    required this.onSwitch,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.originSuggestions,
    required this.destinationSuggestions,
    this.originBuildingCode,
    this.destinationBuildingCode,
    this.currentBuildingCode,
    required this.originRoomController,
    required this.destinationRoomController,
    this.onStartValid,
    this.onDestinationValid,
    this.isConcordiaBuilding,
    this.onDestinationRoomSubmitted,
    this.onOriginRoomSubmitted,
    this.indoorRepository,
    this.highContrastMode = false,
    this.isOriginPoi = false,
    this.isDestinationPoi = false,
    this.selectedTransitionMode,
    this.onTransitionModeChanged,
    this.wheelchairRoutingDefaultEnabled = false,
  });

  @override
  State<RoutePreviewPanel> createState() => _RoutePreviewPanelState();
}

class _RoutePreviewPanelState extends State<RoutePreviewPanel> {
  late TextEditingController _originController;
  late TextEditingController _destinationController;
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();
  bool _showOriginSuggestions = false;
  bool _showDestinationSuggestions = false;

  bool get _isOriginConcordiaBuilding {
    if (widget.originBuildingCode == null ||
        widget.originBuildingCode!.isEmpty) {
      return false;
    }
    return widget.isConcordiaBuilding?.call(widget.originBuildingCode!) ??
        false;
  }

  bool get _isDestinationConcordiaBuilding {
    if (widget.destinationBuildingCode == null ||
        widget.destinationBuildingCode!.isEmpty) {
      return false;
    }
    return widget.isConcordiaBuilding?.call(widget.destinationBuildingCode!) ??
        false;
  }

  void _onRoomFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.originText);
    _destinationController = TextEditingController(
      text: widget.destinationText,
    );

    _originController.addListener(() {
      widget.onOriginChanged(_originController.text);
    });

    _destinationController.addListener(() {
      widget.onDestinationChanged(_destinationController.text);
    });

    _originFocus.addListener(() {
      setState(() {
        _showOriginSuggestions =
            _originFocus.hasFocus && widget.originSuggestions.isNotEmpty;
      });
    });

    _destinationFocus.addListener(() {
      setState(() {
        _showDestinationSuggestions =
            _destinationFocus.hasFocus &&
            widget.destinationSuggestions.isNotEmpty;
      });
    });
    widget.originRoomController.addListener(_onRoomFieldChanged);
    widget.destinationRoomController.addListener(_onRoomFieldChanged);
  }

  @override
  void didUpdateWidget(RoutePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originText != widget.originText &&
        _originController.text != widget.originText) {
      _originController.text = widget.originText;
    }
    if (oldWidget.destinationText != widget.destinationText &&
        _destinationController.text != widget.destinationText) {
      _destinationController.text = widget.destinationText;
    }

    if (oldWidget.originSuggestions != widget.originSuggestions) {
      setState(() {
        _showOriginSuggestions =
            _originFocus.hasFocus && widget.originSuggestions.isNotEmpty;
      });
    }
    if (oldWidget.destinationSuggestions != widget.destinationSuggestions) {
      setState(() {
        _showDestinationSuggestions =
            _destinationFocus.hasFocus &&
            widget.destinationSuggestions.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.dispose();
    _destinationFocus.dispose();
    widget.originRoomController.removeListener(_onRoomFieldChanged);
    widget.destinationRoomController.removeListener(_onRoomFieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = widget.highContrastMode
        ? AppUiColors.highContrastPrimary
        : const Color(0xFF76263D);
    final headerText = widget.highContrastMode ? Colors.black : Colors.white;
    final headerHint = widget.highContrastMode
        ? Colors.black54
        : Colors.white70;
    return Center(
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.95,
              child: Container(
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Origin field with close button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: headerText,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: const Key('start_field'),
                                controller: _originController,
                                focusNode: _originFocus,
                                style: TextStyle(
                                  color: headerText,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Starting location',
                                  hintStyle: TextStyle(color: headerHint),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('clear_route_button'),
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close),
                              color: headerText,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // Divider line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          height: 1,
                          color: widget.highContrastMode
                              ? Colors.black26
                              : Colors.white24,
                        ),
                      ),

                      // Destination field with switch button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.place, color: headerText, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: const Key('destination_field'),
                                controller: _destinationController,
                                focusNode: _destinationFocus,
                                style: TextStyle(
                                  color: headerText,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Choose destination',
                                  hintStyle: TextStyle(color: headerHint),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onSwitch,
                              icon: const Icon(Icons.swap_vert),
                              color: headerText,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      if ((_isOriginConcordiaBuilding ||
                              _isDestinationConcordiaBuilding) &&
                          !(widget.isOriginPoi && widget.isDestinationPoi))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: RoomFieldsSection(
                            originBuildingCode: widget.originBuildingCode,
                            destinationBuildingCode:
                                widget.destinationBuildingCode,
                            originRoomController: widget.originRoomController,
                            destinationRoomController:
                                widget.destinationRoomController,
                            originEnabled:
                                _isOriginConcordiaBuilding &&
                                !widget.isOriginPoi,
                            destinationEnabled:
                                _isDestinationConcordiaBuilding &&
                                !widget.isDestinationPoi,
                            onOriginValid: widget.onStartValid,
                            onDestinationValid: widget.onDestinationValid,
                            onOriginRoomSubmitted: widget.onOriginRoomSubmitted,
                            onDestinationRoomSubmitted:
                                widget.onDestinationRoomSubmitted,
                            indoorRepository: widget.indoorRepository,
                            selectedTransitionMode:
                                widget.selectedTransitionMode,
                            onTransitionModeChanged:
                                widget.onTransitionModeChanged,
                            wheelchairRoutingDefaultEnabled:
                                widget.wheelchairRoutingDefaultEnabled,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Suggestions list — only shown when actively typing
            if (_showOriginSuggestions && widget.originSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildSuggestionsList(widget.originSuggestions, (
                  suggestion,
                ) {
                  setState(() {
                    _showOriginSuggestions = false;
                  });
                  _originController.text = suggestion.name;
                  widget.onOriginSelected(suggestion);
                  _originFocus.unfocus();
                }),
              ),

            if (_showDestinationSuggestions &&
                widget.destinationSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildSuggestionsList(widget.destinationSuggestions, (
                  suggestion,
                ) {
                  setState(() {
                    _showDestinationSuggestions = false;
                  });
                  _destinationController.text = suggestion.name;
                  widget.onDestinationSelected(suggestion);
                  _destinationFocus.unfocus();
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
    List<SearchSuggestion> suggestions,
    Function(SearchSuggestion) onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: Icon(
              suggestion.isConcordiaBuilding ? Icons.school : Icons.place,
              color: const Color(0xFF76263D),
              size: 18,
            ),
            title: Text(suggestion.name, style: const TextStyle(fontSize: 14)),
            subtitle: suggestion.subtitle != null
                ? Text(
                    suggestion.subtitle!,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            dense: true,
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }
}

class RouteTravelModeBar extends StatelessWidget {
  final RouteTravelMode selectedTravelMode;
  final ValueChanged<RouteTravelMode> onTravelModeSelected;
  final Map<String, String?> modeDurations;
  final bool isLoadingDurations;
  final VoidCallback onClose;
  final List<TransitDetailItem> transitDetails;
  final Map<String, String?> modeDistances;
  final Map<String, String?> modeArrivalTimes;
  final VoidCallback onShowSteps;
  final VoidCallback onStart;
  final bool isNavigating;
  final bool highContrastMode;

  final List<String> shuttleNextBuses;

  final int? shuttleWalkingToDestinationMinutes;
  final int? shuttleWalkingFromDestinationMinutes;
  final String? shuttleNearestStop;
  final int? shuttleTotalTripDuration;
  final ShuttleRouteData? shuttleRouteData;

  final VoidCallback? onViewSchedule;

  const RouteTravelModeBar({
    super.key,
    required this.selectedTravelMode,
    required this.onTravelModeSelected,
    required this.modeDurations,
    required this.isLoadingDurations,
    required this.onClose,
    required this.transitDetails,
    required this.modeDistances,
    required this.modeArrivalTimes,
    required this.onShowSteps,
    required this.onStart,
    required this.isNavigating,
    this.highContrastMode = false,
    this.shuttleNextBuses = const [],
    this.shuttleWalkingFromDestinationMinutes,
    this.shuttleWalkingToDestinationMinutes,
    this.shuttleNearestStop,
    this.shuttleTotalTripDuration,
    this.onViewSchedule,
    this.shuttleRouteData,
  });

  @override
  Widget build(BuildContext context) {
    final barBg = highContrastMode
        ? AppUiColors.highContrastPrimary
        : const Color(0xFF76263D);
    final selectedText = highContrastMode ? Colors.black : Colors.white;
    final mutedText = highContrastMode ? Colors.black54 : Colors.white70;
    final buttonActive = highContrastMode
        ? const Color(0xFF89D9C2)
        : Colors.white;
    final selectedLabel = selectedTravelMode.label;
    final selectedDuration = modeDurations[selectedTravelMode.apiValue];
    final resolvedDuration = selectedDuration?.trim().isNotEmpty == true
        ? selectedDuration!
        : 'N/A';
    final durationLabel = isLoadingDurations ? '...' : resolvedDuration;

    final durationParts = _splitDuration(durationLabel);

    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    color: selectedText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Steps button
              TextButton(
                onPressed: selectedTravelMode == RouteTravelMode.shuttle
                    ? onViewSchedule
                    : onShowSteps,
                style: TextButton.styleFrom(
                  foregroundColor: selectedText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  selectedTravelMode == RouteTravelMode.shuttle
                      ? 'Schedule'
                      : 'Steps',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),

              TextButton(
                onPressed:
                    (isNavigating ||
                        selectedTravelMode == RouteTravelMode.shuttle)
                    ? null
                    : onStart,
                style: TextButton.styleFrom(
                  foregroundColor: selectedText,
                  backgroundColor: buttonActive.withValues(
                    alpha:
                        (isNavigating ||
                            selectedTravelMode == RouteTravelMode.shuttle)
                        ? 0.20
                        : 0.40,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isNavigating ? 'Started' : 'Start',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),

              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: selectedText,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.driving,
                    icon: Icons.directions_car,
                    label: _durationLabelFor(RouteTravelMode.driving),
                    labelSize: 10,
                    selectedColor: selectedText,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.walking,
                    icon: Icons.directions_walk,
                    label: _durationLabelFor(RouteTravelMode.walking),
                    labelSize: 10,
                    selectedColor: selectedText,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.bicycling,
                    icon: Icons.directions_bike,
                    label: _durationLabelFor(RouteTravelMode.bicycling),
                    labelSize: 10,
                    selectedColor: selectedText,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.transit,
                    icon: Icons.directions_transit,
                    label: _durationLabelFor(RouteTravelMode.transit),
                    labelSize: 10,
                    selectedColor: selectedText,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.shuttle,
                    icon: Icons.directions_bus_filled,
                    label: _durationLabelFor(RouteTravelMode.shuttle),
                    labelSize: 10,
                    selectedColor: selectedText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            height: 1,
            color: highContrastMode ? Colors.black26 : Colors.white24,
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      durationParts.$1,
                      style: TextStyle(
                        color: selectedText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Opacity(
                      opacity: durationParts.$2.isNotEmpty ? 1 : 0,
                      child: Text(
                        durationParts.$2.isNotEmpty ? durationParts.$2 : '--',
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildRouteDetails()),
            ],
          ),
        ],
      ),
    );
  }

  String _durationLabelFor(RouteTravelMode mode) {
    if (mode == RouteTravelMode.shuttle) {
      final raw = modeDurations['shuttle'];
      if (isLoadingDurations) return '...';
      return raw?.trim().isNotEmpty == true ? raw! : '–';
    }
    final duration = modeDurations[mode.apiValue];
    if (isLoadingDurations) return '...';
    return duration?.trim().isNotEmpty == true ? duration! : 'N/A';
  }

  Widget _buildTravelModeButton({
    required RouteTravelMode mode,
    required IconData icon,
    required String label,
    double labelSize = 10,
    Color selectedColor = const Color(0xFF76263D),
  }) {
    final isSelected = selectedTravelMode == mode;
    final foreground = selectedColor;
    final inactiveColor = highContrastMode ? Colors.black54 : Colors.white70;
    final selectedBg = highContrastMode
        ? const Color(0xFF5EBFA7)
        : Colors.white.withValues(alpha: 0.15);
    final selectedBorder = highContrastMode
        ? Colors.black26
        : Colors.transparent;

    return GestureDetector(
      onTap: () => onTravelModeSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedBorder : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? foreground : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                color: isSelected ? foreground : inactiveColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  height: 2,
                  width: 20,
                  color: highContrastMode ? Colors.black : Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (String, String) _splitDuration(String label) {
    final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(label);
    if (match == null) {
      return (label, '');
    }
    final leading = match.group(1) ?? label;
    final trailing = match.group(2)?.trim() ?? '';
    return (leading, trailing);
  }

  Widget _buildRouteDetails() {
    final primaryText = highContrastMode ? Colors.black : Colors.white;
    final secondaryText = highContrastMode ? Colors.black54 : Colors.white70;

    if (selectedTravelMode == RouteTravelMode.shuttle) {
      return _buildShuttleDetails(shuttleRouteData);
    }

    if (selectedTravelMode == RouteTravelMode.transit) {
      if (transitDetails.isEmpty) {
        return Text(
          'Transit details unavailable',
          style: TextStyle(color: secondaryText, fontSize: 12),
        );
      }

      return Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          for (final detail in transitDetails)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(detail.icon, size: 16, color: detail.color),
                const SizedBox(width: 4),
                Text(
                  detail.title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    // ── Default: distance + arrival time ─────────────────────────────────
    final distance = modeDistances[selectedTravelMode.apiValue];
    final arrival = modeArrivalTimes[selectedTravelMode.apiValue];
    final distanceLabel = distance?.trim().isNotEmpty == true
        ? distance!
        : 'Distance N/A';
    final arrivalLabel = arrival?.trim().isNotEmpty == true
        ? 'Arrival by $arrival'
        : 'Arrival by --';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          arrivalLabel,
          style: TextStyle(
            color: primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          distanceLabel,
          style: TextStyle(color: secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildShuttleDetails(ShuttleRouteData? routeData) {
    final colors = _ShuttleColors(highContrastMode);

    if (isLoadingDurations) {
      return _buildLoadingState(colors);
    }

    if (routeData == null) {
      return _buildNoShuttleRequired(colors);
    }

    final children = <Widget>[];
    final isNoService = !routeData.isInService;

    _addNoServiceLabel(children, isNoService, colors);
    _addWalkToShuttle(children, routeData, isNoService, colors);
    _addWaitTime(children, routeData, isNoService, colors);
    _addBusList(children, routeData, isNoService, colors);
    _addWalkFromShuttle(children, routeData, isNoService, colors);
    _addViewScheduleLink(children, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildLoadingState(_ShuttleColors colors) {
    return Text(
      'Loading shuttle times…',
      style: TextStyle(color: colors.secondary, fontSize: 12),
    );
  }

  Widget _buildNoShuttleRequired(_ShuttleColors colors) {
    return Text(
      'No shuttle required — walking is faster',
      style: TextStyle(
        color: colors.secondary,
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _addNoServiceLabel(
    List<Widget> children,
    bool isNoService,
    _ShuttleColors colors,
  ) {
    if (!isNoService) return;

    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          'No service — next buses scheduled are shown below',
          style: TextStyle(
            color: colors.secondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _addWalkToShuttle(
    List<Widget> children,
    ShuttleRouteData route,
    bool isNoService,
    _ShuttleColors colors,
  ) {
    if (isNoService || (route.walkingToShuttleMinutes ?? 0) < 1) return;

    children.add(
      _buildDetailRow(
        icon: Icons.directions_walk,
        text:
            '${route.walkingToShuttleMinutes} min walk to ${route.nearestStop}',
        color: colors.secondary,
      ),
    );
  }

  void _addWaitTime(
    List<Widget> children,
    ShuttleRouteData route,
    bool isNoService,
    _ShuttleColors colors,
  ) {
    if (isNoService || route.buses.isEmpty) return;

    final busWaitMinutes =
        ShuttleRouteService.extractWaitMinutesFromStatusLabel(
          route.buses.first.statusLabel,
        );
    final actualWait = (busWaitMinutes - (route.walkingToShuttleMinutes ?? 0))
        .clamp(0, 999);

    children.add(
      _buildDetailRow(
        icon: Icons.schedule,
        text: 'Wait: $actualWait min',
        color: colors.tertiary,
      ),
    );
  }

  void _addBusList(
    List<Widget> children,
    ShuttleRouteData route,
    bool isNoService,
    _ShuttleColors colors,
  ) {
    if (route.buses.isEmpty) return;

    for (int i = 0; i < route.buses.length; i++) {
      final bus = route.buses[i];
      final isNext = i == 0;
      final displayTime = ShuttleRouteService.extractTimeFromStatusLabel(
        bus.statusLabel,
      );

      Color color;
      if (isNoService) {
        color = colors.tertiary;
      } else if (isNext) {
        color = colors.primary;
      } else {
        color = colors.secondary;
      }
      double fontSize;
      if (isNext) {
        fontSize = 12.0;
      } else {
        fontSize = 11.0;
      }
      FontWeight fontWeight;
      if (isNext) {
        fontWeight = FontWeight.w700;
      } else {
        fontWeight = FontWeight.w400;
      }

      children.add(
        _buildDetailRow(
          icon: Icons.directions_bus_filled,
          text: displayTime,
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      );
    }
  }

  void _addWalkFromShuttle(
    List<Widget> children,
    ShuttleRouteData route,
    bool isNoService,
    _ShuttleColors colors,
  ) {
    if (isNoService || (route.walkingFromShuttleMinutes ?? 0) < 1) return;

    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(Icons.directions_walk, color: colors.secondary, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${route.walkingFromShuttleMinutes} min walk from shuttle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.secondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addViewScheduleLink(List<Widget> children, _ShuttleColors colors) {
    if (onViewSchedule == null) return;

    children.add(
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: GestureDetector(
          onTap: onViewSchedule,
          child: Text(
            'View full schedule →',
            style: TextStyle(
              color: colors.tertiary,
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: colors.tertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShuttleColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;

  _ShuttleColors(bool highContrastMode)
    : primary = highContrastMode ? Colors.black : Colors.white,
      secondary = highContrastMode ? Colors.black54 : Colors.white70,
      tertiary = highContrastMode ? Colors.black45 : Colors.white60;
}

class TransitDetailItem {
  final IconData icon;
  final Color color;
  final String title;

  const TransitDetailItem({
    required this.icon,
    required this.color,
    required this.title,
  });
}
