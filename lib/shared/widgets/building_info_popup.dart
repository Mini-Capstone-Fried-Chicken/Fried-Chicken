import 'package:flutter/material.dart';

class BuildingInfoPopup extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onClose;
  final bool accessibility;
  final List<String> facilities;
  final VoidCallback? onMore;

  const BuildingInfoPopup({
    super.key,
    required this.title,
    required this.description,
    required this.onClose,
    this.accessibility = false,
    this.facilities = const [],
    this.onMore,
  });

  @override
  State<BuildingInfoPopup> createState() => _BuildingInfoPopupState();
}

class _BuildingInfoPopupState extends State<BuildingInfoPopup> {
  bool _isSaved = false;

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    const burgundy = Color(0xFF76263D);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: burgundy,
        ),
        iconSize: 25,
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

  Widget _topIcon({
    required IconData icon,
    required String tooltip,
  }) {
    const burgundy = Color(0xFF76263D);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Icon(
          icon,
          color: burgundy,
          size: 22,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    final topIcons = <Widget>[];

    if (widget.accessibility) {
      topIcons.add(_topIcon(icon: Icons.accessible, tooltip: 'Accessible'));
    }

    if (_hasFacility(['washroom', 'washrooms', 'washroms', 'restroom', 'toilet'])) {
      topIcons.add(_topIcon(icon: Icons.wc, tooltip: 'Washrooms'));
    }
    if (_hasFacility(['coffee', 'coffee shop', 'cafe'])) {
      topIcons.add(_topIcon(icon: Icons.local_cafe, tooltip: 'Coffee'));
    }
    if (_hasFacility(['restaurant', 'restaurants', 'food'])) {
      topIcons.add(_topIcon(icon: Icons.restaurant, tooltip: 'Restaurants'));
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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  tooltip: _isSaved ? 'Unsave' : 'Save',
                  onPressed: () {
                    setState(() {
                      _isSaved = !_isSaved;
                    });
                  },
                ),
                const SizedBox(width: 4),
                if (topIcons.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.start,
                        children: topIcons,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  color: burgundy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(
                  icon: Icons.directions,
                  tooltip: 'Get directions',
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                _buildIconButton(
                  icon: Icons.map,
                  tooltip: 'Indoor map',
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 6),

            Opacity(
              opacity: 0.7,
              child: TextButton(
                onPressed: widget.onMore ?? () {},
                style: TextButton.styleFrom(
                  foregroundColor: burgundy,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
}
