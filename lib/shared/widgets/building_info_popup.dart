import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_place_metadata_service.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/services/nearby_poi_service.dart';

class BuildingInfoPopup extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onClose;
  final VoidCallback? onIndoorMap;
  final bool accessibility;
  final List<String> facilities;
  final VoidCallback? onMore;
  final bool isLoggedIn;
  final VoidCallback onGetDirections;
  final bool highContrastMode;
  final SavedPlace? savedPlace;
  final PoiCategory? poiCategory;

  const BuildingInfoPopup({
    super.key,
    required this.title,
    required this.description,
    required this.onClose,
    this.accessibility = false,
    this.facilities = const [],
    this.onMore,
    this.onIndoorMap,
    required this.isLoggedIn,
    required this.onGetDirections,
    this.highContrastMode = false,
    this.savedPlace,
    this.poiCategory,
  });

  @override
  State<BuildingInfoPopup> createState() => _BuildingInfoPopupState();
}

class _BuildingInfoPopupState extends State<BuildingInfoPopup> {
  bool _isSaved = false;

  OverlayEntry? _labelEntry;
  Timer? _labelTimer;
  Widget poiCategoryTopIcon(PoiCategory category) {
    switch (category) {
      case PoiCategory.cafe:
        return _topIcon(icon: Icons.local_cafe, tooltip: 'Coffee');
      case PoiCategory.restaurant:
        return _topIcon(icon: Icons.restaurant, tooltip: 'Restaurant');
      case PoiCategory.pharmacy:
        return _topIcon(icon: Icons.local_pharmacy, tooltip: 'Pharmacy');
      case PoiCategory.depanneur:
        return _topIcon(icon: Icons.storefront, tooltip: 'Dépanneur');
    }
  }

  TooltipTriggerMode? get _triggerMode {
    final isTouch =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return isTouch ? TooltipTriggerMode.longPress : null;
  }

  @override
  void initState() {
    super.initState();
    SavedPlacesController.notifier.addListener(_syncSavedState);
    unawaited(_initializeSavedState());
  }

  @override
  void didUpdateWidget(covariant BuildingInfoPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savedPlace?.id != widget.savedPlace?.id) {
      unawaited(_initializeSavedState());
    }
  }

  Future<void> _initializeSavedState() async {
    await SavedPlacesController.ensureInitialized();
    _syncSavedState();
  }

  Set<String> _savedIdAliases(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return const <String>{};

    final aliases = <String>{trimmed};
    if (trimmed.startsWith('places/')) {
      aliases.add(trimmed.substring('places/'.length));
    } else {
      aliases.add('places/$trimmed');
    }
    return aliases;
  }

  bool _isAnyAliasSaved(String id) {
    final aliases = _savedIdAliases(id);
    if (aliases.isEmpty) return false;
    return aliases.any(SavedPlacesController.isSaved);
  }

  Future<void> _removeAllAliases(String id) async {
    final aliases = _savedIdAliases(id);
    for (final alias in aliases) {
      await SavedPlacesController.removePlace(alias);
    }
  }

  void _syncSavedState() {
    final placeId = widget.savedPlace?.id;
    if (placeId == null || !mounted) return;
    final savedNow = _isAnyAliasSaved(placeId);
    if (savedNow != _isSaved) {
      setState(() {
        _isSaved = savedNow;
      });
    }
  }

  Future<void> _toggleSavedPlace() async {
    final place = widget.savedPlace;
    if (place == null) {
      if (!mounted) return;
      setState(() {
        _isSaved = !_isSaved;
      });
      return;
    }
    await SavedPlacesController.ensureInitialized();
    final alreadySaved = _isAnyAliasSaved(place.id);

    bool isSavedNow;
    if (alreadySaved) {
      await _removeAllAliases(place.id);
      isSavedNow = false;
    } else {
      final enriched = await SavedPlaceMetadataService.enrichFromGoogle(place);
      await SavedPlacesController.savePlace(enriched);
      isSavedNow = true;
    }

    if (!mounted) return;
    setState(() {
      _isSaved = isSavedNow;
    });
  }

  void _hideIconLabel() {
    _labelTimer?.cancel();
    _labelTimer = null;
    _labelEntry?.remove();
    _labelEntry = null;
  }

  void _showIconLabel(LayerLink link, String label) {
    _hideIconLabel();

    final overlay = Overlay.of(context);

    final chipBackground = widget.highContrastMode
        ? AppUiColors.highContrastPrimary.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.92);
    final chipText = widget.highContrastMode ? Colors.black : Colors.black87;

    _labelEntry = OverlayEntry(
      builder: (_) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: link,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.topCenter,
                  followerAnchor: Alignment.bottomCenter,
                  offset: const Offset(0, -6),
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 120),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: chipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              color: Colors.black.withValues(alpha: 0.92),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: chipText,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                            decorationColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_labelEntry!);
    _labelTimer = Timer(const Duration(milliseconds: 900), _hideIconLabel);
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Key? key,
  }) {
    final iconColor = widget.highContrastMode
        ? Colors.black
        : const Color(0xFF76263D);
    return Tooltip(
      message: tooltip,
      triggerMode: _triggerMode,
      showDuration: const Duration(seconds: 1),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        iconSize: 25,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      ),
    );
  }

  bool _hasFacility(List<String> keywords) {
    final list = widget.facilities.map((e) => e.toLowerCase()).toList();
    for (final f in list) {
      for (final k in keywords) {
        if (f.contains(k)) return true;
      }
    }
    return false;
  }

  Widget _topIcon({required IconData icon, required String tooltip}) {
    final iconColor = widget.highContrastMode
        ? Colors.black
        : const Color(0xFF76263D);
    final link = LayerLink();

    return CompositedTransformTarget(
      link: link,
      child: IconButton(
        onPressed: () => _showIconLabel(link, tooltip),
        icon: Icon(icon, color: iconColor, size: 22),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 22, height: 22),
        splashRadius: 18,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }

  List<Widget> _collectTopIcons() {
    final topIcons = <Widget>[];

    if (widget.accessibility) {
      topIcons.add(_topIcon(icon: Icons.accessible, tooltip: 'Accessible'));
    }

    if (widget.poiCategory != null) {
      topIcons.add(poiCategoryTopIcon(widget.poiCategory!));
    }

    if (_hasFacility([
      'washroom',
      'washrooms',
      'washroms',
      'restroom',
      'toilet',
    ])) {
      topIcons.add(_topIcon(icon: Icons.wc, tooltip: 'Washrooms'));
    }

    // Facility-based coffee/restaurant icons only for non-POI popups.
    if (widget.poiCategory == null) {
      if (_hasFacility(['coffee', 'coffee shop', 'cafe'])) {
        topIcons.add(_topIcon(icon: Icons.local_cafe, tooltip: 'Coffee'));
      }
      if (_hasFacility(['restaurant', 'restaurants', 'food'])) {
        topIcons.add(_topIcon(icon: Icons.restaurant, tooltip: 'Restaurants'));
      }
    }

    if (_hasFacility(['zen den', 'zen', 'yoga', 'meditation'])) {
      topIcons.add(_topIcon(icon: Icons.self_improvement, tooltip: 'Zen Den'));
    }
    if (_hasFacility(['metro', 'subway'])) {
      topIcons.add(_topIcon(icon: Icons.subway, tooltip: 'Metro'));
    }
    if (_hasFacility(['parking'])) {
      topIcons.add(_topIcon(icon: Icons.local_parking, tooltip: 'Parking'));
    }

    return topIcons;
  }

  Widget _buildTopIconsContent(List<Widget> topIcons) {
    if (topIcons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Wrap(spacing: -15, runSpacing: -15, children: topIcons),
    );
  }

  Widget _buildHeaderRow({
    required Color accent,
    required List<Widget> topIcons,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isLoggedIn) ...[
          _buildIconButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            tooltip: _isSaved ? 'Unsave' : 'Save',
            key: const Key('save_toggle_button'),
            onPressed: () => unawaited(_toggleSavedPlace()),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(child: _buildTopIconsContent(topIcons)),
        Tooltip(
          message: 'Close',
          triggerMode: _triggerMode,
          showDuration: const Duration(seconds: 1),
          child: IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            color: accent,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.highContrastMode
        ? Colors.black
        : const Color(0xFF76263D);
    final popupBackground = widget.highContrastMode
        ? AppUiColors.highContrastPrimary
        : Colors.white;
    final primaryText = Colors.black;
    final secondaryText = Colors.black54;

    final topIcons = _collectTopIcons();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: popupBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderRow(accent: accent, topIcons: topIcons),
            const SizedBox(height: 2),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: secondaryText),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(
                  icon: Icons.directions,
                  tooltip: 'Get directions',
                  key: const Key('get_directions_button'),
                  onPressed: widget.onGetDirections,
                ),
                const SizedBox(width: 10),
                _buildIconButton(
                  icon: Icons.map,
                  tooltip: 'Indoor map',
                  onPressed: widget.onIndoorMap ?? () {},
                ),
              ],
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: 0.7,
              child: TextButton(
                onPressed: widget.onMore ?? () {},
                key: const Key('more_info_button'),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('More'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SavedPlacesController.notifier.removeListener(_syncSavedState);
    _hideIconLabel();
    super.dispose();
  }
}
