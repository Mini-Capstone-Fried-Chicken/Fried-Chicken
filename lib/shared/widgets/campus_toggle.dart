import 'package:flutter/material.dart';
import 'package:campus_app/models/campus.dart';

class CampusToggle extends StatelessWidget {
  final Campus currentCampus;
  final ValueChanged<Campus> onCampusChanged;
  final bool highContrastMode;

  const CampusToggle({
    super.key,
    required this.currentCampus,
    required this.onCampusChanged,
    this.highContrastMode = false,
  });


  static const Color _maroon = Color(0xFF800020);
  static const Color _pillBg = Color(0xFFF3D6DC);

  @override
  Widget build(BuildContext context) {
    final bgColor = highContrastMode ? const Color(0xFF002620) : _pillBg;
    final borderColor = highContrastMode ? const Color(0xFF89D9C2) : _maroon;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: double.infinity,
        height: 40,
        padding: const EdgeInsets.all(3), // inner padding to create the inset look
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.4),
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
    final selectedFill = highContrastMode ? const Color(0xFF014136) : _maroon;
    final selectedTextColor = highContrastMode
        ? const Color(0xFF89D9C2)
        : Colors.white;
    final unselectedTextColor = highContrastMode
        ? const Color(0xFF89D9C2).withValues(alpha: 0.82)
        : _maroon;

    return Material(
      color: Colors.transparent, 
      child: InkWell(
        onTap: () => onCampusChanged(campus),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
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
