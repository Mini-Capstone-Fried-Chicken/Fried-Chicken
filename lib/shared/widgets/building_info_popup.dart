import 'package:flutter/material.dart';

class BuildingInfoPopup extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onClose;

  const BuildingInfoPopup({
    super.key,
    required this.title,
    required this.description,
    required this.onClose,
  });

  @override
  State<BuildingInfoPopup> createState() => _BuildingInfoPopupState();
}

class _BuildingInfoPopupState extends State<BuildingInfoPopup> {
  bool _isSaved = false; // Track whether the building is saved or not

  // Reusable method to build an icon button with tooltip
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    const burgundy = Color(0xFF76263D);
    return Tooltip(
      message: tooltip, // Tooltip text
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: burgundy,
        ),
        iconSize: 30, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
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
                      _isSaved = !_isSaved; // Toggle the saved state
                    });
                  },
                ),
                const Spacer(),
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

            // Building name + code 
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

            // Short description
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // Row for Get Directions and Indoor Map icons 
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center icons horizontally
              children: [
                _buildIconButton(
                  icon: Icons.directions, // Direction icon
                  tooltip: 'Get directions',
                  onPressed: () {
                    // Future implementation getting directions here
                  },
                ),
                const SizedBox(width: 10), 

                _buildIconButton(
                  icon: Icons.map, // Indoor map icon
                  tooltip: 'Indoor map',
                  onPressed: () {
                    // Future implementation for indoor map here
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
