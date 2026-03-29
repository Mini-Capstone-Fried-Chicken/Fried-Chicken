import 'package:flutter/material.dart';
import '../../../services/location/googlemaps_livelocation.dart';
import 'package:campus_app/models/campus.dart';
import 'package:campus_app/features/settings/app_settings.dart';

export '../../../services/location/googlemaps_livelocation.dart' show OutdoorMapPage;
export 'package:campus_app/models/campus.dart' show Campus;

class ExploreScreen extends StatelessWidget {
  final bool isLoggedIn;
  const ExploreScreen({super.key, required this.isLoggedIn});

  Campus _initialCampusFromSettings() {
    return AppSettingsController.state.defaultCampus ==
            AppSettingsState.defaultCampusLoyola
        ? Campus.loyola
        : Campus.sgw;
  }

  @override
  Widget build(BuildContext context) {
    final initialCampus = _initialCampusFromSettings();
    return Scaffold(
      body: Stack(
        children: [
          OutdoorMapPage(
            initialCampus: initialCampus,
            isLoggedIn: isLoggedIn,
          ),
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
