import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/building_polygons.dart';
import '../utils/geo.dart';
import '../widgets/campus_toggle.dart';
import '../widgets/map_search_bar.dart';

//concordia campus coordinates
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
  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;
  BuildingPolygon? _currentBuildingPoly;

  BuildingPolygon? _detectBuildingPoly(LatLng userLocation) {
  for (final b in buildingPolygons) {
    if (pointInPolygon(userLocation, b.points)) return b;
  }
  return null;
}

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
        strokeColor: isCurrent ? Colors.blue.withOpacity(0.8) : burgundy.withOpacity(0.55),
        fillColor: isCurrent ? Colors.blue.withOpacity(0.25) : burgundy.withOpacity(0.22),
        zIndex: isCurrent ? 2 : 1,
      ),
    );
  }

  return polys;
}
  // _currentCampus = what GPS detects right now (can become Campus.none if you leave the zone)
  Campus _currentCampus = Campus.none;

  // _selectedCampus = what the user picked in the toggle (we keep it even if GPS goes off-campus)
  Campus _selectedCampus = Campus.none;

  @override
  void initState() {
    super.initState();

    // Start the toggle on the campus passed to the page 
    _selectedCampus = widget.initialCampus;

    _createBlueDotIcon();
    _startLocationUpdates();
  }

  // Create a custom blue dot icon
  Future<void> _createBlueDotIcon() async {
    _blueDotIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/blue_dot.png', // You can use default marker as fallback
    ).catchError((_) {
      // Fallback to default blue marker if custom icon fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });

    // If the above fails, just use the default blue marker
    if (_blueDotIcon == null) {
      _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
  }

  Future<void> _startLocationUpdates() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = _detectBuildingPoly(newLatLng);
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newLatLng),
      );
    } catch (e) {
      print('Error getting initial position: $e');
    }

    // Listen to location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((position) {
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = _detectBuildingPoly(newLatLng);
      });
    });
  }

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

  Set<Circle> _createCircles() {
    if (_currentLocation == null) return {};

    return {
      Circle(
        circleId: const CircleId('current_location_accuracy'),
        center: _currentLocation!,
        radius: 20, // Accuracy circle in meters
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 1,
      ),
    };
  }

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
        return; // Don't change if none
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(targetLocation, 16),
    );

    setState(() {
      _selectedCampus = newCampus;
    });
  }
  
@override
  Widget build(BuildContext context) {
    final LatLng initialTarget =
        widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

    //for the search bar text
  
    final Campus effectiveCampus =
        _currentCampus != Campus.none ? _currentCampus : _selectedCampus;

    
    // ''  the search bar will just show "Search"
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
            onMapCreated: (controller) => _mapController = controller,
            markers: _createMarkers(),
            circles: _createCircles(),
	          polygons: _createBuildingPolygons(),

          ),

          
          Positioned(
            top: 40, // distance from top
            left: 40, // horizontal margin
            right: 20,
            child: SizedBox(
              height: 70,
              child: MapSearchBar(campusLabel: campusLabel),
            ),
          ),

          // My Location + Campus Indicator
          Positioned(
            bottom: 70,
            left: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Button that recenters the camera on the user's current GPS location
                FloatingActionButton(
                  heroTag: 'location_button',
                  mini: true,
                  onPressed: () {
                    // Jump back to the user's current position.
                    if (_currentLocation != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 17),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),

                // Simple label showing if GPS currently detects SGW/Loyola or none (Off Campus)
                FloatingActionButton.extended(
                  heroTag: 'campus_button',
                  onPressed: null,
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

          // Toggle Button 
          Positioned(
            bottom: 20, // Distance from bottom
            left: 0,
            right: 0,
            child: Center(
              // Campus selector overlay
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
    _mapController?.dispose();
    super.dispose();
  }
}
