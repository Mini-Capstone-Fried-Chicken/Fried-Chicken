import 'package:flutter/material.dart';

import '../../../services/location/googlemaps_livelocation.dart';
import '../../../shared/widgets/map_search_bar.dart';

export '../../../services/location/googlemaps_livelocation.dart' show Campus, OutdoorMapPage;  

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
          
        ],
      ),
    );
  }
}
