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
          // App logo
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30, // center horizontally
            top: 15, // distance from top
            child: SizedBox(
              height: 60, 
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
          // Search bar
          Positioned(

            top: 65, // distance from top
            left: 20, // horizontal margin
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
