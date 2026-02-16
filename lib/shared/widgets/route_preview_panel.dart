import 'package:flutter/material.dart';
import '../../data/search_suggestion.dart';

class RoutePreviewPanel extends StatefulWidget {
  final String originText;
  final String destinationText;
  final VoidCallback onClose;
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Directions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: burgundy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  color: burgundy,
                ),
              ],
            ),
          ),

          // Origin and Destination inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Origin field
                Row(
                  children: [
                    const Icon(Icons.my_location, color: burgundy, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _originController,
                        focusNode: _originFocus,
                        decoration: const InputDecoration(
                          hintText: 'Starting location',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Destination field
                Row(
                  children: [
                    const Icon(Icons.place, color: burgundy, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        focusNode: _destinationFocus,
                        decoration: const InputDecoration(
                          hintText: 'Choose destination',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Suggestions list - only show when actively searching
          if (_showOriginSuggestions && widget.originSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(
    List<SearchSuggestion> suggestions,
    Function(SearchSuggestion) onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
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
              size: 20,
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
