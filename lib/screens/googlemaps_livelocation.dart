import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  Campus _currentCampus = Campus.none;
  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget =
        widget.initialCampus == Campus.sgw ? concordiaSGW : concordiaLoyola;

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: 16,
        ),
        myLocationEnabled: false, // Disabled to use custom marker
        myLocationButtonEnabled: false, // We'll add our own button
        onMapCreated: (controller) => _mapController = controller,
        markers: _createMarkers(),
        circles: _createCircles(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // My Location Button
          FloatingActionButton(
            heroTag: 'location_button',
            mini: true,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 17),
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          // Campus Indicator
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
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
