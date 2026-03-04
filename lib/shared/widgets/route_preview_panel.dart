import 'package:flutter/material.dart';
import '../../data/search_suggestion.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';

enum RouteTravelMode { driving, walking, bicycling, transit }

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
  final String? destinationBuildingCode;
  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final Function(String buildingCode, String roomCode)? onStartValid;
  final Function(String buildingCode, String roomCode)? onDestinationValid;
  final Function(String buildingCode, String roomCode)?
  onDestinationRoomSubmitted;
  final IndoorMapRepository? indoorRepository;

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
    required this.originRoomController,
    required this.destinationRoomController,
    this.onStartValid,
    this.onDestinationValid,
    this.onDestinationRoomSubmitted,
    this.indoorRepository,
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

  bool get _isOriginConcordiaBuilding =>
      widget.originBuildingCode != null &&
      widget.originBuildingCode!.isNotEmpty;

  bool get _isDestinationConcordiaBuilding =>
      widget.destinationBuildingCode != null &&
      widget.destinationBuildingCode!.isNotEmpty;

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
    // Update controllers only if the text changed from parent
    if (oldWidget.originText != widget.originText &&
        _originController.text != widget.originText) {
      _originController.text = widget.originText;
    }
    if (oldWidget.destinationText != widget.destinationText &&
        _destinationController.text != widget.destinationText) {
      _destinationController.text = widget.destinationText;
    }

    // Only update suggestions visibility if field has focus (actively typing)
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
    const burgundy = Color(0xFF76263D);
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
                  color: burgundy,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                            const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: const Key('start_field'),
                                controller: _originController,
                                focusNode: _originFocus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Starting location',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
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
                              color: Colors.white,
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
                        child: Container(height: 1, color: Colors.white24),
                      ),

                      // Destination field with switch button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                key: const Key('destination_field'),
                                controller: _destinationController,
                                focusNode: _destinationFocus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Choose destination',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
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
                              color: Colors.white,
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      if (_isOriginConcordiaBuilding ||
                          _isDestinationConcordiaBuilding)
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
                            originEnabled: _isOriginConcordiaBuilding,
                            destinationEnabled: _isDestinationConcordiaBuilding,
                            onOriginValid: widget.onStartValid,
                            onDestinationValid: widget.onDestinationValid,
                            onDestinationRoomSubmitted:
                                widget.onDestinationRoomSubmitted,
                            indoorRepository: widget.indoorRepository,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Suggestions list - only show when actively searching
            if (_showOriginSuggestions && widget.originSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildSuggestionsList(widget.originSuggestions, (
                  suggestion,
                ) {
                  // Immediately hide suggestions
                  setState(() {
                    _showOriginSuggestions = false;
                  });
                  // Update text and notify parent
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
                  // Immediately hide suggestions
                  setState(() {
                    _showDestinationSuggestions = false;
                  });
                  // Update text and notify parent
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
            color: Colors.black.withOpacity(0.1),
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
  });

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);
    final selectedLabel = selectedTravelMode.label;
    final selectedDuration = modeDurations[selectedTravelMode.apiValue];
    final durationLabel = isLoadingDurations
        ? '...'
        : (selectedDuration?.trim().isNotEmpty == true
              ? selectedDuration!
              : 'N/A');

    final durationParts = _splitDuration(durationLabel);

    return Container(
      width: 360,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: burgundy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Steps button
              TextButton(
                onPressed: onShowSteps,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Steps',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),

              TextButton(
                onPressed: isNavigating ? null : onStart,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(
                    isNavigating ? 0.10 : 0.18,
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
                color: Colors.white,
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
                    labelSize: 11,
                    selectedColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.walking,
                    icon: Icons.directions_walk,
                    label: _durationLabelFor(RouteTravelMode.walking),
                    labelSize: 11,
                    selectedColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.bicycling,
                    icon: Icons.directions_bike,
                    label: _durationLabelFor(RouteTravelMode.bicycling),
                    labelSize: 11,
                    selectedColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildTravelModeButton(
                    mode: RouteTravelMode.transit,
                    icon: Icons.directions_transit,
                    label: _durationLabelFor(RouteTravelMode.transit),
                    labelSize: 11,
                    selectedColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white24),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Opacity(
                      opacity: durationParts.$2.isNotEmpty ? 1 : 0,
                      child: Text(
                        durationParts.$2.isNotEmpty ? durationParts.$2 : '--',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
    final duration = modeDurations[mode.apiValue];
    if (isLoadingDurations) {
      return '...';
    }
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

    return GestureDetector(
      onTap: () => onTravelModeSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? foreground : Colors.white70,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: labelSize,
                color: isSelected ? foreground : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(height: 2, width: 20, color: Colors.white),
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
    if (selectedTravelMode == RouteTravelMode.transit) {
      if (transitDetails.isEmpty) {
        return const Text(
          'Transit details unavailable',
          style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      );
    }

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          distanceLabel,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
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
