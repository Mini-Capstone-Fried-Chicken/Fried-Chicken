import 'package:campus_app/screens/googlemaps_livelocation.dart';
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
          const OutdoorMapPage(initialCampus: Campus.none),
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
