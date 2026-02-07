import 'package:flutter/material.dart';

const Color burgundy = Color(0xFF76263D); 

class MapSearchBar extends StatelessWidget {
  final String campusLabel;

  const MapSearchBar({
    super.key,
    this.campusLabel = '',
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
        child: TextField(
          enabled: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
