import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shared/widgets/map_search_bar.dart';

import '../../data/building_polygons.dart';
import '../../shared/widgets/campus_toggle.dart';
import '../../utils/geo.dart';
import '../../shared/widgets/building_info_popup.dart';
import '../../shared/widgets/learn_more_popup.dart';
import '../../features/indoor/data/building_info.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// Concordia campus coordinates
const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
const double campusRadius = 500; // meters

enum Campus { sgw, loyola, none }

//knowing which campus the user is in
Campus detectCampus(LatLng userLocation) {
  final sgwDistance = Geolocator.distanceBetween(
    userLocation.latitude,
    userLocation.longitude,
    concordiaSGW.latitude,
    concordiaSGW.longitude,
  );

  final loyolaDistance = Geolocator.distanceBetween(
    userLocation.latitude,
    userLocation.longitude,
    concordiaLoyola.latitude,
    concordiaLoyola.longitude,
  );

  if (sgwDistance <= campusRadius) return Campus.sgw;
  if (loyolaDistance <= campusRadius) return Campus.loyola;
  return Campus.none;
}

class OutdoorMapPage extends StatefulWidget {
  final Campus initialCampus;

  const OutdoorMapPage({
    super.key,
    required this.initialCampus,
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _cameraMoving = false;
  bool _showLearnMore = false;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription; // fix for e2e test
  bool _mapReady = false; // Flag to check if map is created

  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;
  BuildingPolygon? _currentBuildingPoly;
  BuildingPolygon? _selectedBuildingPoly;

  // Detect which building polygon the user is inside
  BuildingPolygon? _detectBuildingPoly(LatLng userLocation) {
    for (final b in buildingPolygons) {
      if (pointInPolygon(userLocation, b.points)) return b;
    }
    return null;
  }

  // Create polygons for all buildings, highlighting the current one
  Set<Polygon> _createBuildingPolygons() {
    const burgundy = Color(0xFF800020);

    final polys = <Polygon>{};

    for (final b in buildingPolygons) {
      final isCurrent = _currentBuildingPoly?.code == b.code;

      polys.add(
        Polygon(
          polygonId: PolygonId('poly_${b.code}'),
          points: b.points,
          strokeWidth: isCurrent ? 3 : 2,
          strokeColor: isCurrent
              ? Colors.blue.withOpacity(0.8)
              : burgundy.withOpacity(0.55),
          fillColor: isCurrent
              ? Colors.blue.withOpacity(0.25)
              : burgundy.withOpacity(0.22),
          zIndex: isCurrent ? 2 : 1,
        ),
      );
    }

    return polys;
  }

  // _currentCampus = what GPS detects right now (can become Campus.none if you leave the zone)
  Campus _currentCampus = Campus.none;

  Campus _currentCampus = Campus.none;
  Campus _selectedCampus = Campus.none;

  @override
  void initState() {
    super.initState();

    // Start the toggle on the campus passed to the page
    _selectedCampus = widget.initialCampus;

    _createBlueDotIcon(); // Create a custom blue dot icon for user location
    _startLocationUpdates(); // Start GPS tracking
  }

  Future<void> _createBlueDotIcon() async {
    _blueDotIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/blue_dot.png',
    ).catchError((_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });

    _blueDotIcon ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
  }

  // Start tracking the user's location
  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return; // fix for the e2e test to display the map
      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = _detectBuildingPoly(newLatLng);
      });

      // Move camera to current location if map controller is ready
      if (_mapReady && _mapController != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newLatLng),
        );
      }
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Listen to location updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return; // fix for the e2e test to display the map
      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = _detectBuildingPoly(newLatLng);
      });
    });
  }

  // Create marker for user's current location
  Set<Marker> _createMarkers() {
    if (_currentLocation == null) return {};

    return {
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 999,
      ),
    };
  }

  // Create accuracy circle around user's location
  Set<Circle> _createCircles() {
    if (_currentLocation == null) return {};

    return {
      Circle(
        circleId: const CircleId('current_location_accuracy'),
        center: _currentLocation!,
        radius: 20,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 1,
      ),
    };
  }

  // Switch campus when user uses the toggle
  void _switchCampus(Campus newCampus) {
    LatLng targetLocation;

    switch (newCampus) {
      case Campus.sgw:
        targetLocation = concordiaSGW;
        break;
      case Campus.loyola:
        targetLocation = concordiaLoyola;
        break;
      case Campus.none:
        return;
    }

    // Only animate camera if map is ready
    if (_currentLocation != null && _mapReady && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 17),
      );
    }

    setState(() {
      _selectedCampus = newCampus;
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _showLearnMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget =
        widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

    // For the search bar text
    final Campus effectiveCampus =
        _currentCampus != Campus.none ? _currentCampus : _selectedCampus;

    // '' the search bar will just show "Search"
    final String campusLabel = effectiveCampus == Campus.none
        ? ''
        : (effectiveCampus == Campus.loyola ? 'Loyola' : 'SGW');

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16,
            ),
            myLocationEnabled: false, // Disabled to use custom marker
            myLocationButtonEnabled: false, // We'll add our own button
            onMapCreated: (controller) {
              _mapController = controller;
              _mapReady = true; // Map is ready to animate camera safely
            },
            markers: _createMarkers(),
            circles: _createCircles(),
            polygons: _createBuildingPolygons(),
          ),

          // Positioned(
          //   top: 40, // distance from top
          //   left: 40, // horizontal margin
          //   right: 20,
          //   child: SizedBox(
          //     height: 70,
          //     child: MapSearchBar(campusLabel: campusLabel),
          //   ),
          // ),

          // My Location + Campus Indicator
          Positioned(
            top: 65,
            left: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Button that recenters the camera on the user's current GPS location
                FloatingActionButton(
                  heroTag: 'location_button',
                  mini: true,
                  onPressed: () {
                    if (_currentLocation != null && _mapReady && _mapController != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 17),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),

          if (_showLearnMore && _selectedBuildingPoly != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomPad + 180,
              child: PointerInterceptor(
                child: LearnMorePopup(
                  onClose: _closeLearnMore,
                  purposeText: 'No purpose available.',
                  facilitiesText: 'No facilities available.',
                ),
              ),
            ),

         Positioned(
  bottom: 70,
  left: 20,
  child: PointerInterceptor(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'location_button',
          mini: true,
          onPressed: () {
            final loc = _currentLocation;
            if (loc == null) return;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(loc, 17),
            );
          },
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'campus_button',
          onPressed: _goToMyLocation,
          icon: const Icon(Icons.school),
          label: Text(
            _currentCampus == Campus.sgw
                ? 'SGW Campus'
                : _currentCampus == Campus.loyola
                    ? 'Loyola Campus'
                    : 'Off Campus',
          ),
        ),
      ],
    ),
  ),
),


          // Toggle Button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 800,
                child: CampusToggle(
                  currentCampus: _selectedCampus,
                  onCampusChanged: _switchCampus,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel(); // cancel subscription to prevent memory leaks (fix for e2e test)
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
