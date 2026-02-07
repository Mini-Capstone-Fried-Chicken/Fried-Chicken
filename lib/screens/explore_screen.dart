import 'package:campus_app/screens/googlemaps_livelocation.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  final bool isLoggedIn;
  const ExploreScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const OutdoorMapPage(initialCampus: Campus.none),
        ],
      ),
    );
  }
}
