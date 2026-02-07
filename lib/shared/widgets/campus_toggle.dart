import 'package:flutter/material.dart';

import '../../services/location/googlemaps_livelocation.dart';

class CampusToggle extends StatelessWidget {
  final Campus currentCampus;
  final ValueChanged<Campus> onCampusChanged;

  const CampusToggle({
    super.key,
    required this.currentCampus,
    required this.onCampusChanged,
  });


  static const Color _maroon = Color(0xFF800020);
  static const Color _pillBg = Color(0xFFF3D6DC);

  @override
  Widget build(BuildContext context) {
    // Outer pill container (background + border)
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 34,
        padding: const EdgeInsets.all(3), // inner padding to create the inset look
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _maroon, width: 1.4),
        ),
        child: Row(
          children: [
            // Left option: SGW
            Expanded(
              child: _buildSegment(
                campus: Campus.sgw,
                label: 'Sir George William',
                isLeft: true,
              ),
            ),

            // Small gap between the two segments.
            const SizedBox(width: 4),

            // Right option: Loyola
            Expanded(
              child: _buildSegment(
                campus: Campus.loyola,
                label: 'Loyola',
                isLeft: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSegment({
    required Campus campus,
    required String label,
    required bool isLeft, // kept for readability / possible future tweaks
  }) {
    final bool isSelected = currentCampus == campus;

    return Material(
      color: Colors.transparent, // needed for InkWell ripple to render correctly
      child: InkWell(
        onTap: () => onCampusChanged(campus),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? _maroon : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // prevents overflow for long labels
              style: TextStyle(
                color: isSelected ? Colors.white : _maroon,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
