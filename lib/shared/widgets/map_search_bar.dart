import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../data/building_names.dart';

const Color burgundy = Color(0xFF76263D);

class MapSearchBar extends StatefulWidget {
  final String campusLabel;
  final TextEditingController? controller;
  final Function(String)? onSubmitted;
  final List<BuildingName>? suggestions;
  final Function(BuildingName)? onSuggestionSelected;
  final VoidCallback? onFocus;

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
    this.controller,
    this.onSubmitted,
    this.suggestions,
    this.onSuggestionSelected,
    this.onFocus,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  bool get _hasSuggestions => widget.suggestions?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      _updateSuggestionsVisibility();
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

  void _selectSuggestion(BuildingName building) {
    widget.controller?.text = building.name;
    widget.onSuggestionSelected?.call(building);
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String hint =
        widget.campusLabel.trim().isEmpty ? "Search" : "Search Concordia ${widget.campusLabel}";

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
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: widget.onSubmitted,
                onChanged: (_) {
                  _updateSuggestionsVisibility();
                },
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
                      final building = widget.suggestions![index];
                      return ListTile(
                        title: Text(building.name),
                        subtitle: Text(building.code, style: const TextStyle(fontSize: 12)),
                        dense: true,
                        onTap: () => _selectSuggestion(building),
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
