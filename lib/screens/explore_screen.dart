import 'package:flutter/material.dart';
import '../widgets/map_search_bar.dart';

class ExploreScreen extends StatelessWidget {
  final bool isLoggedIn;
  const ExploreScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blank map area (container for now)
          Container(
            color: Colors.grey[300],
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Text(
                "Map placeholder",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
          ),
          // Search bar
          Positioned(
            top: 40, // distance from top
            left: 40, // horizontal margin
            right: 20,
            child: SizedBox(
              height: 70, 
              child: const MapSearchBar(),
            ),
          ),
        ],
      ),
    );
  }
}
