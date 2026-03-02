import 'package:flutter/material.dart';
import '../../data/search_suggestion.dart';

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

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.originText);
    _destinationController = TextEditingController(text: widget.destinationText);

    // Listen to text changes
    _originController.addListener(() {
      widget.onOriginChanged(_originController.text);
    });

    _destinationController.addListener(() {
      widget.onDestinationChanged(_destinationController.text);
    });

    _originFocus.addListener(() {
      setState(() {
        _showOriginSuggestions = _originFocus.hasFocus && widget.originSuggestions.isNotEmpty;
      });
    });

    _destinationFocus.addListener(() {
      setState(() {
        _showDestinationSuggestions = _destinationFocus.hasFocus && widget.destinationSuggestions.isNotEmpty;
      });
    });
  }

  @override
  void didUpdateWidget(RoutePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers only if the text changed from parent
    if (oldWidget.originText != widget.originText && _originController.text != widget.originText) {
      _originController.text = widget.originText;
    }
    if (oldWidget.destinationText != widget.destinationText && _destinationController.text != widget.destinationText) {
      _destinationController.text = widget.destinationText;
    }

    // Only update suggestions visibility if field has focus (actively typing)
    if (oldWidget.originSuggestions != widget.originSuggestions) {
      setState(() {
        _showOriginSuggestions = _originFocus.hasFocus && widget.originSuggestions.isNotEmpty;
      });
    }
    if (oldWidget.destinationSuggestions != widget.destinationSuggestions) {
      setState(() {
        _showDestinationSuggestions = _destinationFocus.hasFocus && widget.destinationSuggestions.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    return Center(
      child: SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _originController,
                                focusNode: _originFocus,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Starting location',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            IconButton(
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
                        child: Container(
                          height: 1,
                          color: Colors.white24,
                        ),
                      ),

                      // Destination field with switch button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _destinationController,
                                focusNode: _destinationFocus,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Choose destination',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                    ],
                  ),
                ),
              ),
            ),

            // Suggestions list - only show when actively searching
            if (_showOriginSuggestions && widget.originSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildSuggestionsList(
                  widget.originSuggestions,
                  (suggestion) {
                    // Immediately hide suggestions
                    setState(() {
                      _showOriginSuggestions = false;
                    });
                    // Update text and notify parent
                    _originController.text = suggestion.name;
                    widget.onOriginSelected(suggestion);
                    _originFocus.unfocus();
                  },
                ),
              ),

            if (_showDestinationSuggestions && widget.destinationSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildSuggestionsList(
                  widget.destinationSuggestions,
                  (suggestion) {
                    // Immediately hide suggestions
                    setState(() {
                      _showDestinationSuggestions = false;
                    });
                    // Update text and notify parent
                    _destinationController.text = suggestion.name;
                    widget.onDestinationSelected(suggestion);
                    _destinationFocus.unfocus();
                  },
                ),
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
            title: Text(
              suggestion.name,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: suggestion.subtitle != null
                ? Text(
                    suggestion.subtitle!,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            dense: true,
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }
}
