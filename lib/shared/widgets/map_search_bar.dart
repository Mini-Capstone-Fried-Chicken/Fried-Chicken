import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../data/search_suggestion.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';

const Color burgundy = Color(0xFF76263D);
const Color disabledGrey = Color(0xFFB0B0B0);
const Color validGreen = Color(0xFF4CAF50);
const Color invalidRed = Color(0xFFE53935);

class MapSearchBar extends StatefulWidget {
  final String campusLabel;
  final TextEditingController? controller;
  final Function(String)? onSubmitted;
  final List<SearchSuggestion>? suggestions;
  final Function(SearchSuggestion)? onSuggestionSelected;
  final VoidCallback? onFocus;
  final String? selectedBuildingCode;
  final TextEditingController? startRoomController;
  final TextEditingController? destinationRoomController;
  final Function(String, String)?
  onDestinationRoomSubmitted; // building code, room code
  final bool
  showRoomFields; // New parameter to show room fields in route preview

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
    this.controller,
    this.onSubmitted,
    this.suggestions,
    this.onSuggestionSelected,
    this.onFocus,
    this.selectedBuildingCode,
    this.startRoomController,
    this.destinationRoomController,
    this.onDestinationRoomSubmitted,
    this.showRoomFields = false,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  bool _startRoomIsValid = false;
  bool _destinationRoomIsValid = false;

  final _indoorRepository = IndoorMapRepository();

  bool get _hasSuggestions => widget.suggestions?.isNotEmpty ?? false;

  bool get _isConcordiaBuilding =>
      widget.selectedBuildingCode != null &&
      widget.selectedBuildingCode!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Add listeners for room validation
    widget.startRoomController?.addListener(_validateStartRoom);
    widget.destinationRoomController?.addListener(_validateDestinationRoom);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.startRoomController?.removeListener(_validateStartRoom);
    widget.destinationRoomController?.removeListener(_validateDestinationRoom);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      _updateSuggestionsVisibility();
    }
    // Clear validation when building changes
    if (oldWidget.selectedBuildingCode != widget.selectedBuildingCode) {
      if (!_isConcordiaBuilding) {
        widget.startRoomController?.clear();
        widget.destinationRoomController?.clear();
        setState(() {
          _startRoomIsValid = false;
          _destinationRoomIsValid = false;
        });
      }
    }
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

  Future<void> _validateStartRoom() async {
    if (!_isConcordiaBuilding) return;

    final roomCode = widget.startRoomController?.text ?? '';
    if (roomCode.isEmpty) {
      setState(() => _startRoomIsValid = false);
      return;
    }

    final isValid = await _indoorRepository.roomExists(
      widget.selectedBuildingCode!,
      roomCode,
    );

    if (mounted) {
      setState(() => _startRoomIsValid = isValid);
    }
  }

  Future<void> _validateDestinationRoom() async {
    if (!_isConcordiaBuilding) return;

    final roomCode = widget.destinationRoomController?.text ?? '';
    if (roomCode.isEmpty) {
      setState(() => _destinationRoomIsValid = false);
      return;
    }

    final isValid = await _indoorRepository.roomExists(
      widget.selectedBuildingCode!,
      roomCode,
    );

    if (mounted) {
      setState(() => _destinationRoomIsValid = isValid);
    }

    if (isValid) {
      widget.onDestinationRoomSubmitted?.call(
        widget.selectedBuildingCode!,
        roomCode,
      );
    }
  }

  Color _getRoomFieldBorderColor(bool isValid, bool hasInput) {
    if (!hasInput) return Colors.grey[400]!;
    return isValid ? validGreen : invalidRed;
  }

  @override
  Widget build(BuildContext context) {
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
          // Main search bar with building selection and room fields
          Opacity(
            opacity: 0.95,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: burgundy,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main search field
                    TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: widget.onSubmitted,
                      onChanged: (_) {
                        _updateSuggestionsVisibility();
                      },
                    ),

                    // Divider
                    if (_isConcordiaBuilding ||
                        widget.selectedBuildingCode != null)
                      const Divider(color: Colors.white24, height: 1),

                    // Selected building display and room fields
                    if (_isConcordiaBuilding || widget.showRoomFields)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selected building label
                            Text(
                              'Selected: ${widget.selectedBuildingCode}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Origin and Destination room fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: widget.startRoomController,
                                    enabled: true,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      hintText: 'Origin room',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: _getRoomFieldBorderColor(
                                            _startRoomIsValid,
                                            (widget.startRoomController?.text ??
                                                    '')
                                                .isNotEmpty,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: _getRoomFieldBorderColor(
                                            _startRoomIsValid,
                                            (widget.startRoomController?.text ??
                                                    '')
                                                .isNotEmpty,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller:
                                        widget.destinationRoomController,
                                    enabled: true,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      hintText: 'Destination room',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: _getRoomFieldBorderColor(
                                            _destinationRoomIsValid,
                                            (widget
                                                        .destinationRoomController
                                                        ?.text ??
                                                    '')
                                                .isNotEmpty,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: _getRoomFieldBorderColor(
                                            _destinationRoomIsValid,
                                            (widget
                                                        .destinationRoomController
                                                        ?.text ??
                                                    '')
                                                .isNotEmpty,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                    onSubmitted: (_) {
                                      if (_destinationRoomIsValid) {
                                        widget.onDestinationRoomSubmitted?.call(
                                          widget.selectedBuildingCode!,
                                          widget
                                                  .destinationRoomController
                                                  ?.text ??
                                              '',
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Disabled N/A fields (when no building selected)
                    if (!_isConcordiaBuilding)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Building not selected label
                            const Text(
                              'No building selected',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Disabled room fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    enabled: false,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      hintText: 'Not Applicable',
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[600],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    enabled: false,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      hintText: 'Not Applicable',
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[600],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

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
                        key: Key('suggestion_${suggestion.name}'),
                        leading: Icon(
                          suggestion.isConcordiaBuilding
                              ? Icons.school
                              : Icons.place,
                          color: suggestion.isConcordiaBuilding
                              ? burgundy
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
                                      ? burgundy.withOpacity(0.7)
                                      : Colors.grey[600],
                                ),
                              )
                            : null,
                        dense: true,
                        onTap: () => _selectSuggestion(suggestion),
                        hoverColor: burgundy.withOpacity(0.1),
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
