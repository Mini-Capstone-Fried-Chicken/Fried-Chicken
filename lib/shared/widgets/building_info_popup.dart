import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BuildingInfoPopup extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onClose;
  final VoidCallback onLearnMore;

  const BuildingInfoPopup({
    super.key,
    required this.title,
    required this.description,
    required this.onClose,
    required this.onLearnMore,
  });

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
                // quick icons row 
                const Icon(Icons.wc, size: 18, color: burgundy),
                const SizedBox(width: 6),
                const Icon(Icons.accessible, size: 18, color: burgundy),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  color: burgundy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // building name + code 
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            // short description from building_info.dart
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // buttons 
            _pillButton('Get directions', burgundy, () {}),
            const SizedBox(height: 10),
            _pillButton('Indoor map', burgundy, () {}),
            const SizedBox(height: 10),
            _pillButton('Save', burgundy, () {}),
            const SizedBox(height: 10),
            _pillButton('Learn more', burgundy, () {
              // only logs in debug mode
              if (kDebugMode) {
                debugPrint('[BuildingInfoPopup] Learn more pressed for: $title');
              }
              onLearnMore();
            }),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 190,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
