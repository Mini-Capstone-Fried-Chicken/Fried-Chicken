import 'package:flutter/material.dart';

const Color burgundy = Color(0xFF76263D);

class MapSearchBar extends StatelessWidget {
  final String campusLabel;
  final TextEditingController? controller;

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final String hint =
        campusLabel.trim().isEmpty ? "Search" : "Search Concordia $campusLabel";

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: burgundy,
        clipBehavior: Clip.antiAlias, // prevents overflow outside rounded corners
        child: SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              isCollapsed: true,
              hintText: hint,
              hintStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white, size: 22),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
