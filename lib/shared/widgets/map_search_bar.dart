import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../data/search_suggestion.dart';
import 'package:campus_app/shared/widgets/rooms_field_section.dart';

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
  final bool showRoomFields;

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
    this.controller,
    this.onSubmitted,
    this.suggestions,
    this.onSuggestionSelected,
    this.onFocus,
    this.selectedBuildingCode,
    required this.originRoomController,
    required this.destinationRoomController,
    this.onDestinationRoomSubmitted,
    this.showRoomFields = false,
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

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.originRoomController.addListener(_onRoomFieldChanged);
    widget.destinationRoomController.addListener(_onRoomFieldChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.originRoomController.removeListener(_onRoomFieldChanged);
    widget.destinationRoomController.removeListener(_onRoomFieldChanged);
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    print(
      "[DEBUG MapSearchBar] destinationRoomController text: '${widget.destinationRoomController.text}'",
    );
    print("[DEBUG MapSearchBar] showRoomFields: ${widget.showRoomFields}");
    print(
      "[DEBUG MapSearchBar] selectedBuildingCode: ${widget.selectedBuildingCode}",
    );
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
              color: burgundy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Main search field
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: widget.onSubmitted,
                    onChanged: (_) => _updateSuggestionsVisibility(),
                  ),

                  // Only show room fields if a Concordia building is selected
                  if (_isConcordiaBuilding)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: RoomFieldsSection(
                        buildingCode: widget.selectedBuildingCode,
                        originRoomController: widget.originRoomController,
                        destinationRoomController:
                            widget.destinationRoomController,
                        showOriginRoom: false,
                        showDestinationRoom: true,
                        onDestinationRoomSubmitted:
                            widget.onDestinationRoomSubmitted,
                      ),
                    ),

                  // Show disabled fields if no building selected
                  if (!_isConcordiaBuilding)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: RoomFieldsSection(
                        buildingCode: null,
                        originRoomController: widget.originRoomController,
                        destinationRoomController:
                            widget.destinationRoomController,
                        showOriginRoom: false,
                        showDestinationRoom: false,
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
