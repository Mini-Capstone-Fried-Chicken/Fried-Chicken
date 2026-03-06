// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../shared/widgets/map_search_bar.dart';
// import '../building_detection.dart';
// import '../../data/building_polygons.dart';
// import '../../data/search_result.dart';
// import '../../data/search_suggestion.dart';
// import '../building_search_service.dart';
// import '../google_places_service.dart';
// import '../google_directions_service.dart';
// import '../../shared/widgets/campus_toggle.dart';
// import '../../shared/widgets/building_info_popup.dart';
// import '../../shared/widgets/route_preview_panel.dart';
// import '../../features/indoor/data/building_info.dart';
// import '../../services/navigation_steps.dart';
// import '../indoor_maps/indoor_floor_config.dart';
// import 'package:campus_app/utils/geo.dart' as geo;
// import '../../shared/widgets/indoor_floor_dropdown.dart';
// import '../indoor_maps/indoor_map_controller.dart';
// import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// import 'package:campus_app/models/campus.dart';
// import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// import '../indoor_maps/indoor_map_repository.dart';
// import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// import '../../services/concordia_shuttle_service.dart';

// // concordia campus coordinates
// const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// const double campusRadius = 500; // meters
// const String currentLocationTag = "Current location";

// // when camera center is within this distance auto-switch toggle
// const double campusAutoSwitchRadius = 500; // meters
// // knowing which campus the user is in
// Campus detectCampus(LatLng userLocation) {
//   final sgwDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaSGW.latitude,
//     concordiaSGW.longitude,
//   );

//   final loyolaDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaLoyola.latitude,
//     concordiaLoyola.longitude,
//   );

//   if (sgwDistance <= campusRadius) return Campus.sgw;
//   if (loyolaDistance <= campusRadius) return Campus.loyola;
//   return Campus.none;
// }

// class OutdoorMapPage extends StatefulWidget {
//   final Campus initialCampus;
//   final bool isLoggedIn;

//   @visibleForTesting
//   final BuildingPolygon? debugSelectedBuilding;

//   @visibleForTesting
//   final Offset? debugAnchorOffset;

//   @visibleForTesting
//   final bool debugDisableMap;

//   @visibleForTesting
//   final bool debugDisableLocation;

//   @visibleForTesting
//   final String? debugLinkOverride;

//   const OutdoorMapPage({
//     super.key,
//     required this.initialCampus,
//     this.debugSelectedBuilding,
//     this.debugAnchorOffset,
//     this.debugDisableMap = false,
//     this.debugDisableLocation = false,
//     this.debugLinkOverride,
//     required this.isLoggedIn,
//   });

//   @override
//   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// }

// class _OutdoorMapPageState extends State<OutdoorMapPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _originRoomController = TextEditingController();
//   final TextEditingController _destinationRoomController = TextEditingController();
//   bool _cameraMoving = false;
//   List<SearchSuggestion> _searchSuggestions = [];
//   Timer? _debounceTimer;

//   // Indoor overlay state
//   Set<Polygon> _indoorPolygons = {};
//   bool _showIndoor = false;
//   List<IndoorFloorOption> _indoorFloors = const [];
//   String? _selectedIndoorFloorAsset;
//   final IndoorMapController _indoorController = IndoorMapController();

//   // --- Indoor floors state ---
//   GoogleMapController? _mapController;

//   LatLng? _currentLocation;
//   BitmapDescriptor? _blueDotIcon;
//   BuildingPolygon? _currentBuildingPoly;
//   BuildingPolygon? _selectedBuildingPoly;
//   // ignore: unused_field
//   SearchResult? _selectedSearchResult;
//   // ignore: unused_field
//   Map<String, dynamic>? _indoorGeoJson;
//   Set<Marker> _roomLabelMarkers = {};

//   Set<Polyline> _routePolylines = {};

//   // Room location marker
//   Marker? _destinationRoomMarker;
//   String? _currentBuildingCode;

//   // Route preview mode
//   bool _showRoutePreview = false;
//   LatLng? _routeOrigin;
//   LatLng? _routeDestination;
//   String _routeOriginText = currentLocationTag;
//   String _routeDestinationText = '';
//   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
//   final Map<String, String?> _routeDurations = {};
//   final Map<String, String?> _routeDistances = {};
//   final Map<String, String?> _routeArrivalTimes = {};
//   final Map<String, List<LatLng>> _routePointsByMode = {};
//   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
//   String? _routeOriginBuildingCode;
//   String? _routeDestinationBuildingCode;

//   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
//   // --- Navigation camera follow state ---
//   bool _navigationFollowUser = false;
//   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//   static const double _navZoom = 18.0;
//   static const double _navTilt = 60.0;
//   static const double _defaultZoom = 15.0;
//   static const double _defaultTilt = 0.0;
//   static const double _defaultBearing = 0.0;
//   // ignore: unused_field
//   static const double _navBearingThresholdDegrees = 10.0;
//   // ignore: unused_field
//   static const double _navDistanceThresholdMeters = 5.0;
//   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
//   bool _isNavigating = false;
//   String? _navModeKey;
//   int _navStepIndex = 0;
//   bool _isLoadingRouteData = false;
//   List<SearchSuggestion> _routeOriginSuggestions = [];
//   List<SearchSuggestion> _routeDestinationSuggestions = [];
//   Timer? _routeDebounceTimer;

//   // Google Directions modes only — shuttle is handled separately
//   static const List<RouteTravelMode> _supportedTravelModes = [
//     RouteTravelMode.driving,
//     RouteTravelMode.walking,
//     RouteTravelMode.bicycling,
//     RouteTravelMode.transit,
//   ];

//   // Shuttle state
//   List<ShuttleDeparture> _shuttleNextBuses = [];
//   int? _shuttleWalkingMinutes;
//   String _shuttleNearestStop = 'SGW';
//   BitmapDescriptor? _shuttleStopIcon;

//   StreamSubscription<Position>? _posSub;

//   Timer? _popupDebounce;

//   static const double _popupW = 300;
//   static const double _popupH = 260;

//   LatLng? _selectedBuildingCenter;
//   Offset? _anchorOffset;

//   Campus _currentCampus = Campus.none;
//   Campus _selectedCampus = Campus.none;

//   LatLng? _lastCameraTarget;

//   void _clearIndoorState() {
//     _showIndoor = false;
//     _indoorFloors = const [];
//     _selectedIndoorFloorAsset = null;
//     _indoorPolygons = {};
//     _indoorGeoJson = null;
//     _roomLabelMarkers = {};
//   }

//   Campus _campusFromPoint(LatLng p) {
//     final dSgw = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaSGW.latitude,
//       concordiaSGW.longitude,
//     );

//     final dLoy = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaLoyola.latitude,
//       concordiaLoyola.longitude,
//     );

//     final minDist = dSgw < dLoy ? dSgw : dLoy;
//     if (minDist > campusAutoSwitchRadius) return Campus.none;

//     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
//   }

//   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
//     print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
//   }

//   Future<void> _syncToggleWithCameraCenter() async {
//     if (!mounted) return;

//     LatLng? center = _lastCameraTarget;

//     if (center == null) {
//       final controller = _mapController;
//       if (controller == null) return;

//       try {
//         final bounds = await controller.getVisibleRegion();
//         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
//         final lng =
//             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
//         center = LatLng(lat, lng);
//       } catch (_) {
//         return;
//       }
//     }

//     final newCampus = _campusFromPoint(center);

//     if (newCampus == _selectedCampus) return;

//     setState(() {
//       _selectedCampus = newCampus;
//     });
//   }

//   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//     return geo.pointInPolygon(point, polygon);
//   }

//   Future<void> _loadIndoorFloor(String assetPath) async {
//     try {
//       final result = await _indoorController.loadFloor(assetPath);
//       if (!mounted) return;
//       setState(() {
//         _showIndoor = true;
//         _selectedIndoorFloorAsset = assetPath;
//         _indoorPolygons = result.polygons;
//         _indoorGeoJson = result.geoJson;
//         _roomLabelMarkers = result.labels;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load indoor floor: $e')),
//       );
//     }
//   }

//   Future<void> _toggleIndoorMap() async {
//     // turn OFF
//     if (_showIndoor) {
//       setState(() {
//         _clearIndoorState();
//       });
//       return;
//     }

//     // turn ON (needs selected building)
//     final b = _selectedBuildingPoly;
//     if (b == null) return;

//     final floors = IndoorFloorConfig.floorsForBuilding(b.code);
//     if (floors.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No indoor maps available for this building')),
//       );
//       return;
//     }

//     setState(() {
//       _indoorFloors = floors;
//       _selectedIndoorFloorAsset = floors.first.assetPath;
//     });

//     await _loadIndoorFloor(floors.first.assetPath);
//   }

//   Future<void> _goToMyLocation() async {
//     final controller = _mapController;
//     if (controller == null) return;

//     var loc = _currentLocation;

//     if (loc == null) {
//       try {
//         final p = await Geolocator.getCurrentPosition();
//         loc = LatLng(p.latitude, p.longitude);
//         if (mounted) setState(() => _currentLocation = loc);
//       } catch (_) {
//         return;
//       }
//     }

//     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
//   }

//   Future<void> _openLink(String url) async {
//     if (url.trim().isEmpty) return;

//     final uri = Uri.tryParse(url);
//     if (uri == null) return;

//     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     if (!ok) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
//     }
//   }

//   void _schedulePopupUpdate() {
//     _popupDebounce?.cancel();
//     _popupDebounce = Timer(
//       const Duration(milliseconds: 16),
//       _updatePopupOffset,
//     );
//   }

//   Future<void> _updatePopupOffset() async {
//     final controller = _mapController;
//     final center = _selectedBuildingCenter;
//     if (!mounted || controller == null || center == null) return;

//     final sc = await controller.getScreenCoordinate(center);
//     if (!mounted) return;

//     double x = sc.x.toDouble();
//     double y = sc.y.toDouble();

//     final dpr = MediaQuery.of(context).devicePixelRatio;
//     x = x / dpr;
//     y = y / dpr;

//     setState(() {
//       _anchorOffset = Offset(x, y);
//     });
//   }

//   // ignore: unused_element
//   void _selectBuildingWithoutMap(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
//       _cameraMoving = false;
//     });
//   }

//   void _onBuildingTapped(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final controller = _mapController;
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = null;
//       _cameraMoving = true;
//       _clearIndoorState();
//       _roomLabelMarkers = {};
//     });

//     if (controller == null) return;

//     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
//       _,
//     ) async {
//       if (!mounted) return;
//       await _updatePopupOffset();
//       if (!mounted) return;
//       setState(() {
//         _cameraMoving = false;
//       });
//     });
//   }

//   void _closePopup() {
//     _clearSelectedBuilding(clearSearch: true);
//   }

//   void _clearSelectedBuilding({bool clearSearch = false}) {
//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = null;
//       _anchorOffset = null;
//       _routePolylines = {};
//       _showRoutePreview = false;
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//       _destinationRoomMarker = null;
//       if (clearSearch) {
//         _searchController.clear();
//       }
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//     });
//   }

//   Future<void> _getDirections() async {
//     print('[DEBUG] Get directions button clicked');
//     print('[DEBUG] Current location: $_currentLocation');
//     print(
//       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
//     );

//     final origin = _currentLocation;
//     final destination = _selectedBuildingPoly?.center;

//     if (origin == null) {
//       print('[ERROR] Cannot get directions: Current location is null');
//       print(
//         '[ERROR] Make sure location services are enabled and location is set in emulator',
//       );
//       return;
//     }

//     if (destination == null) {
//       print('[ERROR] Cannot get directions: Destination is null');
//       return;
//     }

//     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

//     // Enter route preview mode
//     setState(() {
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = origin;
//       _routeDestination = destination;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText =
//           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
//       _routeOriginBuildingCode = currentBuildingCode;
//       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
//       print(
//         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
//       );
//     });

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _fetchRoutesAndDurations() async {
//     final origin = _routeOrigin;
//     final destination = _routeDestination;

//     if (origin == null || destination == null) {
//       print('[ERROR] Cannot fetch route: origin or destination is null');
//       return;
//     }

//     print(
//       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
//     );

//     setState(() {
//       _isLoadingRouteData = true;
//     });

//     try {
//       final futures = _supportedTravelModes.map(
//         (mode) => GoogleDirectionsService.instance.getRouteDetails(
//           origin: origin,
//           destination: destination,
//           mode: mode.apiValue,
//         ),
//       );

//       final results = await Future.wait(futures);
//       final durations = <String, String?>{};
//       final distances = <String, String?>{};
//       final arrivalTimes = <String, String?>{};
//       final pointsByMode = <String, List<LatLng>>{};
//       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
//       final stepsByMode = <String, List<NavigationStep>>{};

//       for (var i = 0; i < _supportedTravelModes.length; i++) {
//         final mode = _supportedTravelModes[i].apiValue;
//         final route = results[i];
//         durations[mode] = route?.durationText;
//         distances[mode] = route?.distanceText;
//         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
//         stepsByMode[mode] = route?.steps ?? const [];
//         if (route != null && route.points.isNotEmpty) {
//           pointsByMode[mode] = route.points;
//         }
//         if (route != null && route.transitSegments.isNotEmpty) {
//           segmentsByMode[mode] = route.transitSegments;
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         _routeDurations
//           ..clear()
//           ..addAll(durations);
//         _routeDistances
//           ..clear()
//           ..addAll(distances);
//         _routeArrivalTimes
//           ..clear()
//           ..addAll(arrivalTimes);
//         _routePointsByMode
//           ..clear()
//           ..addAll(pointsByMode);
//         _routeSegmentsByMode
//           ..clear()
//           ..addAll(segmentsByMode);
//         _routeStepsByMode
//           ..clear()
//           ..addAll(stepsByMode);

//         _isLoadingRouteData = false;
//       });

//       _applySelectedModeRoute(animateCamera: true);

//       _fetchShuttleInfo();
//     } catch (e) {
//       print('Error getting directions: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoadingRouteData = false;
//       });
//     }
//   }

//   void _openStepsForSelectedMode() {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       _showShuttleScheduleModal();
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     showNavigationStepsModal(
//       context,
//       title: _selectedTravelMode.label,
//       steps: steps,
//       totalDuration: _routeDurations[key],
//       totalDistance: _routeDistances[key],
//     );
//   }

//   void _applySelectedModeRoute({required bool animateCamera}) {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

//     final selectedModeKey = _selectedTravelMode.apiValue;
//     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
//     if (_selectedTravelMode == RouteTravelMode.transit &&
//         selectedSegments != null &&
//         selectedSegments.isNotEmpty) {
//       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
//       return;
//     }

//     final selectedPoints = _routePointsByMode[selectedModeKey];

//     if (selectedPoints == null || selectedPoints.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = {
//         Polyline(
//           polylineId: const PolylineId('route'),
//           points: selectedPoints,
//           color: const Color(0xFF76263D),
//           width: 5,
//           patterns: _selectedTravelMode == RouteTravelMode.driving
//               ? const []
//               : [PatternItem.dot, PatternItem.gap(10)],
//         ),
//       };
//     });

//     if (!animateCamera || _mapController == null) return;
//     final bounds = geo.calculateBounds(selectedPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _applyTransitSegments(
//     List<DirectionsRouteSegment> segments, {
//     required bool animateCamera,
//   }) {
//     final polylines = <Polyline>{};
//     final allPoints = <LatLng>[];

//     for (var i = 0; i < segments.length; i++) {
//       final segment = segments[i];
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       allPoints.addAll(segment.points);

//       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
//       polylines.add(
//         Polyline(
//           polylineId: PolylineId('route_segment_$i'),
//           points: segment.points,
//           color: _resolveTransitSegmentColor(segment),
//           width: 5,
//           patterns: isWalking
//               ? [PatternItem.dot, PatternItem.gap(10)]
//               : const [],
//         ),
//       );
//     }

//     if (polylines.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = polylines;
//     });

//     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
//       return;
//     }

//     final bounds = geo.calculateBounds(allPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _startNavigation() {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
//           ),
//           duration: Duration(seconds: 3),
//         ),
//       );
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     if (steps.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No steps available for this route')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isNavigating = true;
//       _navModeKey = key;
//       _navStepIndex = 0;

//       _navigationFollowUser = true;
//       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//     });

//     if (_currentLocation != null && _mapController != null) {
//       try {
//         final currentPos = _currentLocation!;
//         final initialCam = CameraPosition(
//           target: currentPos,
//           zoom: _navZoom,
//           tilt: _navTilt,
//           bearing: 0.0,
//         );
//         _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(initialCam),
//         );
//       } catch (e) {
//         print('Error animating camera when starting navigation: $e');
//       }
//     }
//   }

//   void _stopNavigation() {
//     setState(() {
//       _isNavigating = false;
//       _navModeKey = null;
//       _navStepIndex = 0;
//       _navigationFollowUser = false;
//     });
//     if (_mapController != null && _currentLocation != null) {
//       try {
//         final cam = CameraPosition(
//           target: _currentLocation!,
//           zoom: _defaultZoom,
//           tilt: _defaultTilt,
//           bearing: _defaultBearing,
//         );

//         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//       } catch (e) {
//         print('Error resetting camera after navigation: $e');
//       }
//     }

//     _closeRoutePreview();
//   }

//   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
//     if (_mapController == null) return;
//     if (!_navigationFollowUser) return;

//     final now = DateTime.now();

//     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
//       return;
//     }

//     double bearing = 0.0;
//     if (heading != null && heading >= 0.0) {
//       bearing = heading;
//     }

//     final cam = CameraPosition(
//       target: userLatLng,
//       zoom: _navZoom,
//       tilt: _navTilt,
//       bearing: bearing,
//     );

//     try {
//       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//     } catch (e) {
//       print('Error animating navigation camera: $e');
//     }
//   }

//   void _maybeAdvanceNavigationStep(LatLng user) {
//     final key = _navModeKey;
//     if (key == null) return;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return;

//     if (_navStepIndex >= steps.length - 1) return;

//     final current = steps[_navStepIndex];
//     final end = current.endPoint;
//     if (end == null) return;

//     final d = Geolocator.distanceBetween(
//       user.latitude,
//       user.longitude,
//       end.latitude,
//       end.longitude,
//     );

//     if (d <= 20) {
//       setState(() => _navStepIndex += 1);
//     }
//   }

//   void _closeRoutePreview() {
//     setState(() {
//       _showRoutePreview = false;
//       _routePolylines = {};
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//       _searchController.clear();

//       //reset indoor map and building selection state
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//     });
//   }

//   String? _formatArrivalTime(int? durationSeconds) {
//     if (durationSeconds == null) {
//       return null;
//     }

//     final now = DateTime.now();
//     final arrival = now.add(Duration(seconds: durationSeconds));
//     int hour = arrival.hour;
//     final minute = arrival.minute.toString().padLeft(2, '0');
//     final isPm = hour >= 12;
//     final period = isPm ? 'pm' : 'am';
//     hour = hour % 12;
//     if (hour == 0) {
//       hour = 12;
//     }
//     return '$hour:$minute $period';
//   }

//   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
//     const defaultRed = Color(0xFF76263D);
//     final mode = segment.travelMode.toUpperCase();
//     if (mode == 'WALKING') {
//       return defaultRed;
//     }

//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Colors.blue;
//     }

//     final lineColor = parseHexColor(segment.transitLineColorHex);
//     if (lineColor != null) {
//       return lineColor;
//     }

//     return defaultRed;
//   }

//   List<TransitDetailItem> _buildTransitDetailItems() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     final items = <TransitDetailItem>[];

//     for (final segment in segments) {
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       final travelMode = segment.travelMode.toUpperCase();
//       if (travelMode == 'WALKING') {
//         continue;
//       }

//       final vehicleType = segment.transitVehicleType?.toUpperCase();
//       final lineLabel =
//           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
//       final color = _resolveTransitSegmentColor(segment);

//       IconData icon = Icons.directions_transit;
//       String title = 'Transit $lineLabel';

//       if (vehicleType == 'BUS') {
//         icon = Icons.directions_bus;
//         title = 'Bus $lineLabel';
//       } else if (vehicleType == 'SUBWAY' ||
//           vehicleType == 'METRO_RAIL' ||
//           vehicleType == 'HEAVY_RAIL' ||
//           vehicleType == 'COMMUTER_TRAIN' ||
//           vehicleType == 'RAIL' ||
//           vehicleType == 'TRAM' ||
//           vehicleType == 'LIGHT_RAIL' ||
//           vehicleType == 'MONORAIL') {
//         icon = Icons.directions_subway;
//         title = 'Metro $lineLabel';
//       }

//       items.add(TransitDetailItem(icon: icon, color: color, title: title));
//     }

//     return items;
//   }

//   // ignore: unused_element
//   List<DirectionsRouteSegment> _getTransitDetailSegments() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     return segments
//         .where(
//           (segment) =>
//               segment.travelMode.toUpperCase() == 'TRANSIT' &&
//               segment.points.isNotEmpty,
//         )
//         .toList();
//   }

//   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     final lineLabel =
//         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

//     if (vehicleType == 'BUS') {
//       return 'Bus $lineLabel';
//     }

//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return 'Metro $lineLabel';
//     }

//     return 'Transit $lineLabel';
//   }

//   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Icons.directions_bus;
//     }
//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return Icons.directions_subway;
//     }
//     return Icons.directions_transit;
//   }

//   // ignore: unused_element
//   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
//     const burgundy = Color(0xFF76263D);

//     return Container(
//       width: 340,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.15),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Transit details',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: burgundy,
//             ),
//           ),
//           const SizedBox(height: 6),
//           for (final segment in segments)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 6),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     _transitSegmentIcon(segment),
//                     size: 16,
//                     color: _resolveTransitSegmentColor(segment),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _formatTransitSegmentTitle(segment),
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         if (segment.transitHeadsign != null &&
//                             segment.transitHeadsign!.trim().isNotEmpty)
//                           Text(
//                             segment.transitHeadsign!,
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Colors.black54,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Color? parseHexColor(String? hex) {
//     if (hex == null || hex.trim().isEmpty) {
//       return null;
//     }

//     final normalized = hex.trim().replaceFirst('#', '');
//     if (normalized.length != 6) {
//       return null;
//     }

//     final value = int.tryParse(normalized, radix: 16);
//     if (value == null) {
//       return null;
//     }

//     return Color(0xFF000000 | value);
//   }

//   void _switchOriginDestination() {
//     setState(() {
//       final tempOrigin = _routeOriginText;
//       final tempOriginLatLng = _routeOrigin;
//       final tempDestination = _routeDestinationText;
//       final tempDestinationLatLng = _routeDestination;

//       _routeOriginText = tempDestination;
//       _routeOrigin = tempDestinationLatLng;
//       _routeDestinationText = tempOrigin;
//       _routeDestination = tempOriginLatLng;

//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//     });

//     _fetchRoutesAndDurations();
//   }

//   void _onTravelModeSelected(RouteTravelMode mode) {
//     setState(() {
//       _selectedTravelMode = mode;
//     });

//     if (mode == RouteTravelMode.shuttle) {
//       _fetchShuttleInfo();
//       return;
//     }

//     if (_routePointsByMode.containsKey(mode.apiValue)) {
//       _applySelectedModeRoute(animateCamera: false);
//       return;
//     }

//     _fetchRoutesAndDurations();
//   }

//   /// Shuttle stop marker icon
//   Future<void> _createShuttleStopIcon() async {
//     _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(600, 600)),
//       'assets/images/shuttle_icon.png',
//     );
//   }

//   /// Walking time + 4 next buses
//   Future<void> _fetchShuttleInfo() async {
//     final origin = _routeOrigin ?? _currentLocation;

//     if (origin == null) {
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//       return;
//     }

//     setState(() {
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//     });

//     try {
//       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
//       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

//       int walkingSeconds = 0;
//       List<LatLng> walkPoints = [];

//       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
//         origin: origin,
//         destination: stopLatLng,
//         mode: 'walking',
//       );

//       if (walkRoute != null) {
//         walkingSeconds = walkRoute.durationSeconds ?? 0;
//         walkPoints = walkRoute.points;
//       }

//       final walkingMinutes = (walkingSeconds / 60).ceil();

//       final buses = ConcordiaShuttleService.getNextDepartures(
//         fromStop: nearestStop,
//         now: DateTime.now(),
//         count: 4,
//         walkingDuration: Duration(seconds: walkingSeconds),
//       );

//       String shuttleDurationLabel;
//       if (!ConcordiaShuttleService.isInService()) {
//         shuttleDurationLabel = 'No service';
//       } else if (buses.isNotEmpty) {
//         shuttleDurationLabel = buses.first.statusLabel;
//       } else {
//         shuttleDurationLabel = '–';
//       }

//       if (walkPoints.isNotEmpty) {
//         setState(() {
//           _routePolylines = {
//             Polyline(
//               polylineId: const PolylineId('shuttle_walk'),
//               points: walkPoints,
//               color: const Color(0xFF76263D),
//               width: 5,
//               patterns: [PatternItem.dot, PatternItem.gap(10)],
//             ),
//           };
//         });

//         if (_mapController != null) {
//           final bounds = geo.calculateBounds([...walkPoints, stopLatLng]);
//           _mapController!
//               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//         }
//       } else {
//         setState(() {
//           _routePolylines = {};
//         });
//       }

//       if (!mounted) return;
//       setState(() {
//         _shuttleNearestStop = nearestStop;
//         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
//         _shuttleNextBuses = buses;
//         _routeDurations['shuttle'] = shuttleDurationLabel;
//       });
//     } catch (e) {
//       print('Error fetching shuttle info: $e');
//       if (!mounted) return;
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//     }
//   }

//   /// Open full day schedule
//   void _showShuttleScheduleModal() {
//     showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) =>
//           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
//     );
//   }

//   Future<void> _onRouteOriginChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeOriginSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeOriginSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for origin: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} origin suggestions');
//         if (mounted) {
//           setState(() {
//             _routeOriginSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting origin suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteDestinationChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeDestinationSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeDestinationSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for destination: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} destination suggestions');
//         if (mounted) {
//           setState(() {
//             _routeDestinationSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting destination suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
//     print(
//       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
//     );
//     LatLng? newOrigin;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       print('[DEBUG] Handling Concordia building');
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newOrigin = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//       print('[DEBUG] Concordia building origin: $newOrigin');
//     } else if (suggestion.placeId != null) {
//       print(
//         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
//       );
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         print('[DEBUG] Place details result: $placeDetails');
//         if (placeDetails != null) {
//           newOrigin = placeDetails.location;
//           buildingCode = null;
//           print('[DEBUG] Non-Concordia origin location: $newOrigin');
//         } else {
//           print(
//             '[ERROR] Place details returned null for ${suggestion.placeId}',
//           );
//         }
//       } catch (e) {
//         print('[ERROR] Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newOrigin != null) {
//       print('[DEBUG] Updating route origin state');
//       print('[DEBUG] New origin building code: $buildingCode');
//       setState(() {
//         _routeOrigin = newOrigin;
//         _routeOriginText = displayText;
//         _routeOriginSuggestions = [];
//         _routeOriginBuildingCode = buildingCode;
//         _originRoomController.clear();
//       });
//       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
//       await _fetchRoutesAndDurations();
//     } else {
//       print('[ERROR] Could not determine origin location');
//     }
//   }

//   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
//     LatLng? newDestination;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newDestination = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//     } else if (suggestion.placeId != null) {
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         if (placeDetails != null) {
//           newDestination = placeDetails.location;
//           buildingCode = null;
//         }
//       } catch (e) {
//         print('Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newDestination != null) {
//       print('[DEBUG] Updating route destination state');
//       print('[DEBUG] New destination building code: $buildingCode');
//       setState(() {
//         _routeDestination = newDestination;
//         _routeDestinationText = displayText;
//         _routeDestinationSuggestions = [];
//         _routeDestinationBuildingCode = buildingCode;
//         _destinationRoomController.clear();
//       });
//       await _fetchRoutesAndDurations();
//     }
//   }

//   void _hideBuildingPopup() {
//     if (_selectedBuildingPoly == null) return;

//     _clearSelectedBuilding();
//   }

//   Future<void> _onSearchSubmitted(String query) async {
//     if (query.trim().isEmpty) return;

//     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

//     if (concordiaBuilding != null) {
//       _onBuildingTapped(concordiaBuilding);
//       return;
//     }

//     final results = await BuildingSearchService.searchWithGooglePlaces(
//       query,
//       userLocation: _currentLocation,
//     );

//     if (results.isNotEmpty) {
//       SearchResult? selectedResult;

//       for (final result in results) {
//         if (!result.isConcordiaBuilding) {
//           selectedResult = result;
//           break;
//         }
//       }

//       if (selectedResult == null && results.isNotEmpty) {
//         selectedResult = results.first;
//       }

//       if (selectedResult != null) {
//         if (selectedResult.isConcordiaBuilding &&
//             selectedResult.buildingPolygon != null) {
//           _onBuildingTapped(selectedResult.buildingPolygon!);
//         } else {
//           _onPlaceSelected(selectedResult);
//         }
//       }
//     } else {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('"$query" not found'),
//           duration: const Duration(seconds: 2),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//       _searchController.clear();
//     }
//   }

//   void _onPlaceSelected(SearchResult result) {
//     final controller = _mapController;
//     if (controller == null) return;

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = result;
//     });

//     _searchController.value = TextEditingValue(
//       text: result.name,
//       selection: TextSelection.collapsed(offset: result.name.length),
//     );

//     if (result.isConcordiaBuilding) {
//       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${result.name} is a Concordia building'),
//           duration: const Duration(seconds: 3),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//     } else {
//       if (_currentLocation == null) {
//         controller.animateCamera(
//           CameraUpdate.newLatLngZoom(result.location, 18),
//         );
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${result.name} is not a Concordia building'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.grey[700],
//           ),
//         );
//       } else {
//         _enterRoutePreviewForPlace(result);
//       }
//     }
//   }

//   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
//     if (_currentLocation == null) return;

//     print(
//       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
//     );

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = _currentLocation;
//       _routeDestination = place.location;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText = place.name;
//       _selectedSearchResult = place;
//     });

//     print(
//       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
//     );

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final buildingPolygon = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       if (buildingPolygon == null) return;
//       _onBuildingTapped(buildingPolygon);
//     } else if (suggestion.placeId != null) {
//       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//         suggestion.placeId!,
//       );
//       if (placeDetails != null) {
//         final concordiaBuilding = BuildingSearchService.searchBuilding(
//           suggestion.name,
//         );

//         if (concordiaBuilding != null) {
//           _onBuildingTapped(concordiaBuilding);
//         } else {
//           final searchResult = SearchResult.fromGooglePlace(
//             name: placeDetails.name,
//             address: placeDetails.formattedAddress,
//             location: placeDetails.location,
//             isConcordiaBuilding: false,
//             placeId: placeDetails.placeId,
//           );
//           _onPlaceSelected(searchResult);
//         }
//       }
//     }
//   }

//   Set<Polygon> _createBuildingPolygons() {
//     const burgundy = Color(0xFF800020);
//     const selectedBlue = Color(0xFF7F83C3);

//     final polys = <Polygon>{};

//     for (final b in buildingPolygons) {
//       final isCurrent = _currentBuildingPoly?.code == b.code;
//       final isSelected = _selectedBuildingPoly?.code == b.code;

//       final strokeColor = isSelected
//           ? selectedBlue.withOpacity(0.95)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.8)
//           : burgundy.withOpacity(0.55);

//       final fillColor = isSelected
//           ? selectedBlue.withOpacity(0.25)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.25)
//           : burgundy.withOpacity(0.22);

//       final strokeWidth = isSelected
//           ? 3
//           : isCurrent
//           ? 3
//           : 2;
//       final zIndex = isSelected
//           ? 3
//           : isCurrent
//           ? 2
//           : 1;

//       polys.add(
//         Polygon(
//           polygonId: PolygonId('poly_${b.code}'),
//           points: b.points,
//           strokeWidth: strokeWidth,
//           strokeColor: strokeColor,
//           fillColor: fillColor,
//           zIndex: zIndex,
//           consumeTapEvents: true,
//           onTap: () => _onBuildingTapped(b),
//         ),
//       );
//     }

//     return polys;
//   }

//   List<Widget> _createBuildingGestureDetectors() {
//     final detectors = <Widget>[];

//     for (final building in buildingPolygons) {
//       detectors.add(
//         Positioned(
//           left: 0,
//           top: 0,
//           child: GestureDetector(
//             key: Key('building_detector_${building.code}'),
//             onTap: () => _onBuildingTapped(building),
//             child: Container(
//               width: 100,
//               height: 100,
//               color: Colors.transparent,
//             ),
//           ),
//         ),
//       );
//     }

//     return detectors;
//   }

//   @override
//   void initState() {
//     super.initState();

//     _selectedCampus = widget.initialCampus;

//     _lastCameraTarget = widget.initialCampus == Campus.loyola
//         ? concordiaLoyola
//         : concordiaSGW;

//     _createBlueDotIcon();
//     _createShuttleStopIcon();
//     _determineUserLocationAndBuilding().then((_) {
//       _startLocationUpdates();
//     });

//     _searchController.addListener(_onSearchChanged);
//     // Clear destination room marker when room input changes
//     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
//     _determineUserLocationAndBuilding();
//   }

//   Future<void> _determineUserLocationAndBuilding() async {
//     final position = await Geolocator.getCurrentPosition();
//     _currentLocation = LatLng(position.latitude, position.longitude);

//     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

//     setState(() {
//       _currentBuildingCode = buildingAtLocation?.code;
//     });
//   }

//   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
//     for (final building in buildingPolygons) {
//       if (_isPointInPolygon(location, building.points)) {
//         return building;
//       }
//     }
//     return null;
//   }

//   void _onDestinationRoomTextChanged() {
//     if (_destinationRoomMarker == null) return;

//     setState(() {
//       _destinationRoomMarker = null;
//     });
//   }

//   void _onSearchChanged() {
//     _debounceTimer?.cancel();

//     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       final query = _searchController.text;
//       try {
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('Error getting search suggestions: $e');
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = BuildingSearchService.getSuggestions(
//               query,
//             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
//           });
//         }
//       }
//     });
//   }

//   Future<void> _createBlueDotIcon() async {
//     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
//       BitmapDescriptor.hueAzure,
//     );
//   }

//   Future<void> _startLocationUpdates() async {
//     print('[DEBUG] Starting location updates...');

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     print('[DEBUG] Location service enabled: $serviceEnabled');

//     if (!serviceEnabled) {
//       print('[ERROR] Location services are disabled');
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     print('[DEBUG] Initial permission status: $permission');

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       print('[DEBUG] Permission after request: $permission');
//       if (permission == LocationPermission.denied) {
//         print('[ERROR] Location permission denied by user');
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       print('[ERROR] Location permission denied forever');
//       return;
//     }

//     try {
//       print('[DEBUG] Attempting to get current position...');
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           timeLimit: Duration(seconds: 10),
//         ),
//       );
//       final newLatLng = LatLng(position.latitude, position.longitude);

//       print(
//         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
//       );
//       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

//       if (!mounted) return;
//       setState(() {
//         _currentLocation = newLatLng;
//         _currentCampus = detectCampus(newLatLng);
//         _currentBuildingPoly = detectBuildingPoly(newLatLng);
//       });

//       print('[DEBUG] Current campus: $_currentCampus');
//       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

//       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
//     } catch (e) {
//       print('[ERROR] Failed to get current position: $e');
//       print(
//         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
//       );
//     }

//     _posSub =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.best,
//             distanceFilter: 5,
//           ),
//         ).listen((position) {
//           final newLatLng = LatLng(position.latitude, position.longitude);
//           print(
//             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
//           );

//           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

//           if (!mounted) return;
//           setState(() {
//             _currentLocation = newLatLng;
//             _currentCampus = detectCampus(newLatLng);
//             _currentBuildingPoly = detectBuildingPoly(newLatLng);
//             _currentBuildingCode = buildingAtLocation?.code;
//           });

//           if (_isNavigating) {
//             _maybeAdvanceNavigationStep(newLatLng);
//           }
//           if (_navigationFollowUser) {
//             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
//           }
//         });
//   }

//   Set<Marker> _createMarkers() {
//     final markers = <Marker>{};
//     // Add current location marker
//     if (_currentLocation != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLocation!,
//           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           zIndex: 999,
//         ),
//       );
//     }

//     // Shuttle stop markers
//     final shuttleIcon = _shuttleStopIcon;
//     if (shuttleIcon != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_sgw'),
//           position: shuttleStopSGW,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — SGW',
//             snippet: 'Hall Building stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_loyola'),
//           position: shuttleStopLoyola,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — Loyola',
//             snippet: 'Loyola campus stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//     }

//     // Add destination room marker only when indoor map is shown
//     if (_destinationRoomMarker != null && _showIndoor) {
//       markers.add(_destinationRoomMarker!);
//     }

//     if (_showRoutePreview) {
//       if (_routeDestination != null) {
//         markers.add(
//           Marker(
//             markerId: const MarkerId('route_destination'),
//             position: _routeDestination!,
//             infoWindow: InfoWindow(title: _routeDestinationText),
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueRed,
//             ),
//           ),
//         );
//       }
//     }

//     return markers;
//   }

//   Set<Circle> _createCircles() {
//     final circles = <Circle>{};

//     if (_currentLocation == null) return {};

//     circles.add(
//       Circle(
//         circleId: const CircleId('current_location_accuracy'),
//         center: _currentLocation!,
//         radius: 20,
//         fillColor: Colors.blue.withOpacity(0.1),
//         strokeColor: Colors.blue.withOpacity(0.3),
//         strokeWidth: 1,
//       ),
//     );

//     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
//       final segments = _routeSegmentsByMode['transit'] ?? const [];
//       final seen = <String>{};

//       for (final segment in segments) {
//         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
//           continue;
//         }
//         if (segment.points.isEmpty) {
//           continue;
//         }

//         final endpoints = [segment.points.first, segment.points.last];
//         for (final point in endpoints) {
//           final key =
//               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
//           if (!seen.add(key)) {
//             continue;
//           }

//           circles.add(
//             Circle(
//               circleId: CircleId('transit_stop_$key'),
//               center: point,
//               radius: 15,
//               fillColor: Colors.white,
//               strokeColor: const Color(0xFF76263D),
//               strokeWidth: 2,
//             ),
//           );
//         }
//       }
//     }

//     return circles;
//   }

//   NavigationStep? _getCurrentNavStep() {
//     final key = _navModeKey;
//     if (key == null) return null;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return null;

//     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
//     return steps[_navStepIndex];
//   }

//   void _switchCampus(Campus newCampus) {
//     LatLng targetLocation;

//     switch (newCampus) {
//       case Campus.sgw:
//         targetLocation = concordiaSGW;
//         break;
//       case Campus.loyola:
//         targetLocation = concordiaLoyola;
//         break;
//       case Campus.none:
//         return;
//     }

//     _lastCameraTarget = targetLocation;
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(targetLocation, 16),
//     );

//     setState(() {
//       _selectedCampus = newCampus;
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _cameraMoving = false;
//       _searchController.clear();
//     });
//   }

//   Offset? _computePopupPosition(BuildContext context) {
//     final screen = MediaQuery.of(context).size;
//     final topPad = MediaQuery.of(context).padding.top;

//     final anchor = widget.debugAnchorOffset ?? _anchorOffset;
//     if (anchor == null || _cameraMoving) return null;

//     final ax = anchor.dx;
//     final ay = anchor.dy;

//     final inView =
//         ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
//     if (!inView) return null;

//     double left = ax - (_popupW / 2);
//     double top = ay - (_popupH / 2);

//     const margin = 8.0;
//     final minLeft = margin;
//     final maxLeft = screen.width - _popupW - margin;
//     final minTop = topPad + margin;
//     final maxTop = screen.height - _popupH - margin;

//     if (left < minLeft) left = minLeft;
//     if (left > maxLeft) left = maxLeft;
//     if (top < minTop) top = minTop;
//     if (top > maxTop) top = maxTop;

//     return Offset(left, top);
//   }

//   Future<void> _onDestinationRoomSubmitted(
//     String buildingCode,
//     String roomCode,
//   ) async {
//     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

//     try {
//       final repo = IndoorMapRepository();
//       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

//       if (roomLocation == null) {
//         print('[ERROR] Could not find location for room $roomCode');
//         return;
//       }
//       print('[DEBUG] Room location found: $roomLocation');
//       final marker = Marker(
//         markerId: const MarkerId('destination_room'),
//         position: roomLocation,
//         infoWindow: InfoWindow(title: 'Room $roomCode'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       );

//       if (!mounted) return;
//       setState(() {
//         _destinationRoomMarker = marker;
//       });

//       print('[DEBUG] Destination room marker placed at $roomLocation');
//     } catch (e) {
//       print('[ERROR] Error processing destination room: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: const Color(0xFFE53935),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final LatLng initialTarget =
//         widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

//     final Campus labelCampus =
//         _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

//     final String campusLabel = labelCampus == Campus.sgw
//         ? 'SGW'
//         : labelCampus == Campus.loyola
//             ? 'Loyola'
//             : '';

//     final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
//     final popupPos = _computePopupPosition(context);

//     return Scaffold(
//       body: Stack(
//         children: [
//           if (widget.debugDisableMap)
//             const SizedBox.expand()
//           else
//             OutdoorMapView(
//               initialTarget: initialTarget,
//               showIndoorStyle: _showIndoor,
//               indoorMapStyle: _indoorMapStyle,
//               onMapCreated: (c) => _mapController = c,
//               onCameraMove: (pos) {
//                 _lastCameraTarget = pos.target;
//                 if (_selectedBuildingCenter != null) _schedulePopupUpdate();
//               },
//               onCameraMoveStarted: () {
//                 if (_selectedBuildingCenter == null) return;
//                 setState(() => _cameraMoving = true);
//               },
//               onCameraIdle: () {
//                 _syncToggleWithCameraCenter();
//                 if (_selectedBuildingCenter == null) return;
//                 setState(() => _cameraMoving = false);
//                 _updatePopupOffset();
//               },
//               markers: {
//                 ..._createMarkers(),
//                 ..._roomLabelMarkers,
//               },
//               circles: _createCircles(),
//               polygons: {
//                 ..._createBuildingPolygons(),
//                 ..._indoorPolygons,
//               },
//               polylines: _routePolylines,
//             ),

//           if (_isNavigating)
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: NavigationNextStepHeader(
//                   modeLabel: _selectedTravelMode.label,
//                   nextStep: _getCurrentNavStep(),
//                   onStop: _stopNavigation,
//                   onShowSteps: _openStepsForSelectedMode,
//                 ),
//               ),
//             ),

//           if (_showRoutePreview && !_isNavigating)
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: RoutePreviewPanel(
//                 originText: _routeOriginText,
//                 destinationText: _routeDestinationText,
//                 onClose: _closeRoutePreview,
//                 onSwitch: _switchOriginDestination,
//                 onOriginChanged: _onRouteOriginChanged,
//                 onDestinationChanged: _onRouteDestinationChanged,
//                 onOriginSelected: _onRouteOriginSelected,
//                 onDestinationSelected: _onRouteDestinationSelected,
//                 originSuggestions: _routeOriginSuggestions,
//                 destinationSuggestions: _routeDestinationSuggestions,
//                 originRoomController: _originRoomController,
//                 destinationRoomController: _destinationRoomController,
//                 onOriginRoomSubmitted: _onOriginRoomSubmitted,
//                 onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
//                 originBuildingCode: _routeOriginBuildingCode,
//                 destinationBuildingCode: _routeDestinationBuildingCode,
//                 isConcordiaBuilding: (buildingCode) {
//                   return buildingPolygons.any(
//                     (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
//                   );
//                 },
//               ),
//             ),

//           if (_showRoutePreview)
//             Positioned(
//               bottom: 25,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: Center(
//                   child: RouteTravelModeBar(
//                     selectedTravelMode: _selectedTravelMode,
//                     onTravelModeSelected: _onTravelModeSelected,
//                     modeDurations: _routeDurations,
//                     isLoadingDurations: _isLoadingRouteData,
//                     onClose: _closeRoutePreview,
//                     onStart: _startNavigation,
//                     isNavigating: _isNavigating,
//                     onShowSteps: _openStepsForSelectedMode,
//                     transitDetails: _buildTransitDetailItems(),
//                     modeDistances: _routeDistances,
//                     modeArrivalTimes: _routeArrivalTimes,
//                     shuttleNextBuses:
//                         _shuttleNextBuses.map((b) => b.statusLabel).toList(),
//                     shuttleWalkingMinutes: _shuttleWalkingMinutes,
//                     shuttleNearestStop: _shuttleNearestStop,
//                     onViewSchedule: _showShuttleScheduleModal,
//                   ),
//                 ),
//               ),
//             ),

//           if (!_showRoutePreview && !_isNavigating)
//             OutdoorTopSearch(
//               campusLabel: campusLabel,
//               controller: _searchController,
//               onSubmitted: _onSearchSubmitted,
//               suggestions: _searchSuggestions,
//               onSuggestionSelected: _onSuggestionSelected,
//               onFocus: _hideBuildingPopup,
//               originRoomController: _originRoomController,
//               destinationRoomController: _destinationRoomController,
//               onOriginRoomSubmitted: _onOriginRoomSubmitted,
//               onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
//               selectedBuildingCode: _selectedBuildingPoly?.code,
//               currentBuildingCode: _currentBuildingCode,
//               userLocation: _currentLocation,
//               isConcordiaBuilding: (buildingCode) {
//                 return buildingPolygons.any(
//                   (b) =>
//                       (b.code ?? '').toUpperCase() ==
//                       buildingCode.toUpperCase(),
//                 );
//               },
//               showIndoor: _showIndoor,
//               floors: _indoorFloors,
//               selectedAssetPath: _selectedIndoorFloorAsset,
//               onFloorChanged: _loadIndoorFloor,
//             ),

//           if (selectedBuilding != null && popupPos != null)
//             OutdoorBuildingPopup(
//               building: selectedBuilding,
//               position: popupPos,
//               buildingInfoByCode: buildingInfoByCode,
//               debugLinkOverride: widget.debugLinkOverride,
//               onClose: _closePopup,
//               onIndoorMap: _toggleIndoorMap,
//               onGetDirections: _getDirections,
//               onOpenLink: _openLink,
//               isLoggedIn: widget.isLoggedIn,
//             ),

//           if (!_showRoutePreview)
//             OutdoorBottomControls(
//               currentLocation: _currentLocation,
//               currentCampus: _currentCampus,
//               onGoToMyLocation: _goToMyLocation,
//               onCenterOnUser: () {
//                 final loc = _currentLocation;
//                 if (loc == null) return;
//                 _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
//               },
//             ),

//           if (!_showRoutePreview)
//             OutdoorBottomBar(
//               showRoutePreview: _showRoutePreview,
//               isNavigating: _isNavigating,
//               selectedCampus: _selectedCampus,
//               onCampusChanged: _switchCampus,
//               selectedTravelMode: _selectedTravelMode,
//               onTravelModeSelected: _onTravelModeSelected,
//               routeDurations: _routeDurations,
//               routeDistances: _routeDistances,
//               routeArrivalTimes: _routeArrivalTimes,
//               isLoadingRouteData: _isLoadingRouteData,
//               onCloseRoutePreview: _closeRoutePreview,
//               onStartNavigation: _startNavigation,
//               onShowSteps: _openStepsForSelectedMode,
//               transitDetails: _buildTransitDetailItems(),
//             ),

//           ..._createBuildingGestureDetectors(),
//         ],
//       ),
//     );
//   }

//   static const String _indoorMapStyle = '''
//   [
//     {
//       "featureType": "poi",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.school",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.business",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "transit",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     }
//   ]
//   ''';

//   @override
//   void dispose() {
//     _posSub?.cancel();
//     _popupDebounce?.cancel();
//     _debounceTimer?.cancel();
//     _routeDebounceTimer?.cancel();
//     _mapController?.dispose();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _originRoomController.dispose();
//     _destinationRoomController.dispose();
//     super.dispose();
//   }
// }


// class _ShuttleScheduleSheet extends StatelessWidget {
//   final String nearestStop;

//   const _ShuttleScheduleSheet({required this.nearestStop});

//   @override
//   Widget build(BuildContext context) {
//     const burgundy = Color(0xFF76263D);
//     final today = DateTime.now();
//     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
//     final isWeekday =
//         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

//     return DraggableScrollableSheet(
//       initialChildSize: 0.62,
//       minChildSize: 0.35,
//       maxChildSize: 0.92,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//           ),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 height: 4,
//                 width: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.directions_bus_filled, color: burgundy),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Concordia Shuttle Schedule',
//                             style: TextStyle(
//                               color: burgundy,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             isWeekday
//                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
//                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.of(context).maybePop(),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//               ),

//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Row(
//                   children: [
//                     _StopChip(
//                         label: 'SGW  (Hall Building)', color: burgundy),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Icon(Icons.sync_alt,
//                           size: 16, color: Colors.black45),
//                     ),
//                     _StopChip(label: 'Loyola', color: burgundy),
//                   ],
//                 ),
//               ),

//               const Divider(height: 1),

//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                   itemCount: times.length,
//                   itemBuilder: (context, index) {
//                     final t = times[index];
//                     final now = DateTime.now();
//                     final isPast = t.isBefore(now);
//                     final isNext = !isPast &&
//                         (index == 0 || times[index - 1].isBefore(now));

//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 6),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isNext
//                             ? burgundy.withOpacity(0.08)
//                             : Colors.transparent,
//                         border: isNext
//                             ? Border.all(color: burgundy.withOpacity(0.3))
//                             : null,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.directions_bus_filled,
//                             size: 16,
//                             color: isPast
//                                 ? Colors.black26
//                                 : isNext
//                                     ? burgundy
//                                     : Colors.black54,
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             ConcordiaShuttleService.formatTime(t),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: isNext
//                                   ? FontWeight.w700
//                                   : FontWeight.w400,
//                               color: isPast
//                                   ? Colors.black26
//                                   : isNext
//                                       ? burgundy
//                                       : Colors.black87,
//                             ),
//                           ),
//                           if (isNext) ...[
//                             const SizedBox(width: 10),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: burgundy,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Text(
//                                 'Next bus',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _StopChip extends StatelessWidget {
//   final String label;
//   final Color color;

//   const _StopChip({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         border: Border.all(color: color.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }


// // // import 'dart:async';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:geolocator/geolocator.dart';
// // // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // // import 'package:pointer_interceptor/pointer_interceptor.dart';
// // // import 'package:url_launcher/url_launcher.dart';

// // // import '../../shared/widgets/map_search_bar.dart';
// // // import '../building_detection.dart';
// // // import '../../data/building_polygons.dart';
// // // import '../../data/search_result.dart';
// // // import '../../data/search_suggestion.dart';
// // // import '../building_search_service.dart';
// // // import '../google_places_service.dart';
// // // import '../google_directions_service.dart';
// // // import '../../shared/widgets/campus_toggle.dart';
// // // import '../../shared/widgets/building_info_popup.dart';
// // // import '../../shared/widgets/route_preview_panel.dart';
// // // import '../../features/indoor/data/building_info.dart';
// // // import '../../services/navigation_steps.dart';
// // // import '../indoor_maps/indoor_floor_config.dart';
// // // import 'package:campus_app/utils/geo.dart' as geo;
// // // import '../../shared/widgets/indoor_floor_dropdown.dart';
// // // import '../indoor_maps/indoor_map_controller.dart';
// // // import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// // // import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// // // import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// // // import 'package:campus_app/models/campus.dart';
// // // import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// // // import '../indoor_maps/indoor_map_repository.dart';
// // // import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// // // import '../../services/concordia_shuttle_service.dart';

// // // // concordia campus coordinates
// // // const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// // // const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// // // const double campusRadius = 500; // meters
// // // const String currentLocationTag = "Current location";

// // // // when camera center is within this distance auto-switch toggle
// // // const double campusAutoSwitchRadius = 500; // meters
// // // // knowing which campus the user is in
// // // Campus detectCampus(LatLng userLocation) {
// // //   final sgwDistance = Geolocator.distanceBetween(
// // //     userLocation.latitude,
// // //     userLocation.longitude,
// // //     concordiaSGW.latitude,
// // //     concordiaSGW.longitude,
// // //   );

// // //   final loyolaDistance = Geolocator.distanceBetween(
// // //     userLocation.latitude,
// // //     userLocation.longitude,
// // //     concordiaLoyola.latitude,
// // //     concordiaLoyola.longitude,
// // //   );

// // //   if (sgwDistance <= campusRadius) return Campus.sgw;
// // //   if (loyolaDistance <= campusRadius) return Campus.loyola;
// // //   return Campus.none;
// // // }

// // // class OutdoorMapPage extends StatefulWidget {
// // //   final Campus initialCampus;
// // //   final bool isLoggedIn;

// // //   @visibleForTesting
// // //   final BuildingPolygon? debugSelectedBuilding;

// // //   @visibleForTesting
// // //   final Offset? debugAnchorOffset;

// // //   @visibleForTesting
// // //   final bool debugDisableMap;

// // //   @visibleForTesting
// // //   final bool debugDisableLocation;

// // //   @visibleForTesting
// // //   final String? debugLinkOverride;

// // //   const OutdoorMapPage({
// // //     super.key,
// // //     required this.initialCampus,
// // //     this.debugSelectedBuilding,
// // //     this.debugAnchorOffset,
// // //     this.debugDisableMap = false,
// // //     this.debugDisableLocation = false,
// // //     this.debugLinkOverride,
// // //     required this.isLoggedIn,
// // //   });

// // //   @override
// // //   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// // // }

// // // class _IndoorFloorOption {
// // //   final String label;
// // //   final String assetPath;

// // //   const _IndoorFloorOption({
// // //     required this.label,
// // //     required this.assetPath,
// // //   });
// // // }

// // // class _OutdoorMapPageState extends State<OutdoorMapPage> {
// // //   final TextEditingController _searchController = TextEditingController();
// // //   final TextEditingController _originRoomController = TextEditingController();
// // //   final TextEditingController _destinationRoomController = TextEditingController();
// // //   bool _cameraMoving = false;
// // //   List<SearchSuggestion> _searchSuggestions = [];
// // //   Timer? _debounceTimer;

// // //   // Indoor overlay state
// // //   Set<Polygon> _indoorPolygons = {};
// // //   bool _showIndoor = false;
// // //   List<IndoorFloorOption> _indoorFloors = const [];
// // //   String? _selectedIndoorFloorAsset;
// // //   final IndoorMapController _indoorController = IndoorMapController();

// // //   // --- Indoor floors state ---
// // //   String? _indoorBuildingCode; // building currently shown in indoor mode
// // //   String? _selectedIndoorFloorAsset; // which floor file is loaded
// // //   List<_IndoorFloorOption> _indoorFloors = []; // dropdown options

// // //   GoogleMapController? _mapController;

// // //   LatLng? _currentLocation;
// // //   BitmapDescriptor? _blueDotIcon;
// // //   BuildingPolygon? _currentBuildingPoly;
// // //   BuildingPolygon? _selectedBuildingPoly;
// // //   // ignore: unused_field
// // //   SearchResult? _selectedSearchResult;
// // //   // ignore: unused_field
// // //   Map<String, dynamic>? _indoorGeoJson;
// // //   Set<Marker> _roomLabelMarkers = {};

// // //   Set<Polyline> _routePolylines = {};

// // //   // Room location marker
// // //   Marker? _destinationRoomMarker;
// // //   String? _currentBuildingCode;

// // //   // Route preview mode
// // //   bool _showRoutePreview = false;
// // //   LatLng? _routeOrigin;
// // //   LatLng? _routeDestination;
// // //   String _routeOriginText = currentLocationTag;
// // //   String _routeDestinationText = '';
// // //   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
// // //   final Map<String, String?> _routeDurations = {};
// // //   final Map<String, String?> _routeDistances = {};
// // //   final Map<String, String?> _routeArrivalTimes = {};
// // //   final Map<String, List<LatLng>> _routePointsByMode = {};
// // //   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
// // //   String? _routeOriginBuildingCode;
// // //   String? _routeDestinationBuildingCode;

// // //   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
// // //   // --- Navigation camera follow state ---
// // //   bool _navigationFollowUser = false;
// // //   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// // //   static const double _navZoom = 18.0;
// // //   static const double _navTilt = 60.0;
// // //   static const double _defaultZoom = 15.0;
// // //   static const double _defaultTilt = 0.0;
// // //   static const double _defaultBearing = 0.0;
// // //   // ignore: unused_field
// // //   static const double _navBearingThresholdDegrees = 10.0;
// // //   // ignore: unused_field
// // //   static const double _navDistanceThresholdMeters = 5.0;
// // //   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
// // //   bool _isNavigating = false;
// // //   String? _navModeKey;
// // //   int _navStepIndex = 0;
// // //   bool _isLoadingRouteData = false;
// // //   List<SearchSuggestion> _routeOriginSuggestions = [];
// // //   List<SearchSuggestion> _routeDestinationSuggestions = [];
// // //   Timer? _routeDebounceTimer;

// // //   // Google Directions modes only — shuttle is handled separately
// // //   static const List<RouteTravelMode> _supportedTravelModes = [
// // //     RouteTravelMode.driving,
// // //     RouteTravelMode.walking,
// // //     RouteTravelMode.bicycling,
// // //     RouteTravelMode.transit,
// // //   ];

// // //   List<ShuttleDeparture> _shuttleNextBuses = [];
// // //   int? _shuttleWalkingMinutes;
// // //   String _shuttleNearestStop = 'SGW';
// // //   BitmapDescriptor? _shuttleStopIcon;

// // //   StreamSubscription<Position>? _posSub;

// // //   Timer? _popupDebounce;

// // //   static const double _popupW = 300;
// // //   static const double _popupH = 260;

// // //   LatLng? _selectedBuildingCenter;
// // //   Offset? _anchorOffset;

// // //   Campus _currentCampus = Campus.none;
// // //   Campus _selectedCampus = Campus.none;

// // //   LatLng? _lastCameraTarget;

// // //   List<_IndoorFloorOption> _floorsForBuilding(String code) {
// // //     switch (code.toUpperCase()) {
// // //       case 'HALL':
// // //         return const [
// // //           _IndoorFloorOption(
// // //             label: '1',
// // //             assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '2',
// // //             assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '8',
// // //             assetPath: 'assets/indoor_maps/geojson/Hall/h8.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '9',
// // //             assetPath: 'assets/indoor_maps/geojson/Hall/h9.geojson.json',
// // //           ),
// // //         ];

// // //       case 'MB':
// // //         return const [
// // //           _IndoorFloorOption(
// // //             label: '1',
// // //             assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '2',
// // //             assetPath: 'assets/indoor_maps/geojson/MB/mb2.geojson.json',
// // //           ),
// // //         ];

// // //       case 'VE':
// // //         return const [
// // //           _IndoorFloorOption(
// // //             label: '1',
// // //             assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '2',
// // //             assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json',
// // //           ),
// // //         ];

// // //       case 'VL':
// // //         return const [
// // //           _IndoorFloorOption(
// // //             label: '1',
// // //             assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
// // //           ),
// // //           _IndoorFloorOption(
// // //             label: '2',
// // //             assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json',
// // //           ),
// // //         ];

// // //       case 'CC':
// // //         return const [
// // //           _IndoorFloorOption(
// // //             label: '1',
// // //             assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
// // //           ),
// // //         ];

// // //       default:
// // //         return const [];
// // //     }
// // //   }
// // //   void _clearIndoorState() {
// // //     _showIndoor = false;
// // //     _indoorFloors = const [];
// // //     _selectedIndoorFloorAsset = null;
// // //     _indoorPolygons = {};
// // //     _indoorGeoJson = null;
// // //     _roomLabelMarkers = {};
// // //   }

// // //   Campus _campusFromPoint(LatLng p) {
// // //     final dSgw = Geolocator.distanceBetween(
// // //       p.latitude,
// // //       p.longitude,
// // //       concordiaSGW.latitude,
// // //       concordiaSGW.longitude,
// // //     );

// // //     final dLoy = Geolocator.distanceBetween(
// // //       p.latitude,
// // //       p.longitude,
// // //       concordiaLoyola.latitude,
// // //       concordiaLoyola.longitude,
// // //     );

// // //     final minDist = dSgw < dLoy ? dSgw : dLoy;
// // //     if (minDist > campusAutoSwitchRadius) return Campus.none;

// // //     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
// // //   }

// // //   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
// // //   print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
// // // }

// // //   Future<void> _syncToggleWithCameraCenter() async {
// // //     if (!mounted) return;

// // //     LatLng? center = _lastCameraTarget;

// // //     if (center == null) {
// // //       final controller = _mapController;
// // //       if (controller == null) return;

// // //       try {
// // //         final bounds = await controller.getVisibleRegion();
// // //         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
// // //         final lng =
// // //             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
// // //         center = LatLng(lat, lng);
// // //       } catch (_) {
// // //         return;
// // //       }
// // //     }

// // //     final newCampus = _campusFromPoint(center);

// // //     if (newCampus == _selectedCampus) return;

// // //     setState(() {
// // //       _selectedCampus = newCampus;
// // //     });
// // //   }

// // //   List<int> _getAvailableFloorsForBuilding(String code) {
// // //     switch (code.toUpperCase()) {
// // //       case 'HALL':
// // //         return [1];
// // //       case 'MB':
// // //         return [1];
// // //       case 'VE':
// // //         return [1];
// // //       case 'VL':
// // //         return [1];
// // //       case 'CC':
// // //         return [1];
// // //       default:
// // //         return [];
// // //     }
// // //   }

// // //   String? _getIndoorAssetPath(String buildingCode, int floor) {
// // //     final code = buildingCode.toUpperCase();
// // //     switch (code) {
// // //       case 'HALL':
// // //         return 'assets/indoor_maps/geojson/Hall/h$floor.geojson.json';
// // //       case 'MB':
// // //         return 'assets/indoor_maps/geojson/MB/mb$floor.geojson.json';
// // //       case 'VE':
// // //         return 'assets/indoor_maps/geojson/VE/ve$floor.geojson.json';
// // //       case 'VL':
// // //         return 'assets/indoor_maps/geojson/VL/vl$floor.geojson.json';
// // //       case 'CC':
// // //         return 'assets/indoor_maps/geojson/CC/cc$floor.geojson.json';
// // //       default:
// // //         return null;
// // //     }
// // //   }
// // // bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
// // //   return geo.pointInPolygon(point, polygon);
// // // }

// // //   Future<void> _loadIndoorFloor(String assetPath) async {
// // //     try {
// // //       final repo = IndoorMapRepository();
// // //       final geo = await repo.loadGeoJsonAsset(assetPath);

// // //       final polys = _geoJsonToPolygons(geo);
// // //       final labels = await _createRoomLabels(geo);

// // //       if (!mounted) return;
// // //       setState(() {
// // //         _showIndoor = true;
// // //         _selectedIndoorFloorAsset = assetPath;
// // //         _indoorPolygons = polys;
// // //         _indoorGeoJson = geo;
// // //         _roomLabelMarkers = labels;
// // //       });
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to load indoor floor: $e')),
// // //       );
// // //     }
// // //   }

// // //   Future<void> _loadIndoorMapForSelectedBuilding() async {
// // //     final b = _selectedBuildingPoly;
// // //     if (b == null) return;

// // //     final floors = _getAvailableFloorsForBuilding(b.code);
// // //     if (floors.isEmpty) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text(
// // //               'Indoor map currently only available for Hall, MB, VE, VL, and CC'),
// // //         ),
// // //       );
// // //       return;
// // //     }

// // //     if (!mounted) return;
// // //     setState(() {
// // //       _availableFloorsForSelectedBuilding = floors;

// // //       if (!floors.contains(_selectedIndoorFloor)) {
// // //         _selectedIndoorFloor = floors.first;
// // //       }
// // //     });

// // //     final assetPath = _getIndoorAssetPath(b.code, _selectedIndoorFloor);
// // //     if (assetPath == null) return;

// // //     setState(() {
// // //       _isLoadingRouteData = false;
// // //     });

// // //     try {
// // //       final repo = IndoorMapRepository();
// // //       final geo = await repo.loadGeoJsonAsset(assetPath);

// // //       final polys = _geoJsonToPolygons(geo);
// // //       final labels = await _createRoomLabels(geo);

// // //       if (!mounted) return;
// // //       setState(() {
// // //         _showIndoor = true;
// // //         _indoorPolygons = polys;
// // //         _indoorGeoJson = geo;
// // //         _roomLabelMarkers = labels;
// // //       });
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(content: Text('Failed to load indoor map: $e')),
// // //       );
// // //     }
// // //   }
// // // Future<void> _loadIndoorFloor(String assetPath) async {
// // //   try {
// // //     final result = await _indoorController.loadFloor(assetPath);
// // //     if (!mounted) return;
// // //     setState(() {
// // //       _showIndoor = true;
// // //       _selectedIndoorFloorAsset = assetPath;
// // //       _indoorPolygons = result.polygons;
// // //       _indoorGeoJson = result.geoJson;
// // //       _roomLabelMarkers = result.labels;
// // //     });
// // //   } catch (e) {
// // //     if (!mounted) return;
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(content: Text('Failed to load indoor floor: $e')),
// // //     );
// // //   }
// // // }

// // // Future<void> _toggleIndoorMap() async {
// // //   // turn OFF
// // //   if (_showIndoor) {
// // //     setState(() {
// // //       _clearIndoorState();
// // //     });
// // //     return;
// // //   }
// // //   Future<void> _toggleIndoorMap() async {
// // //     if (_showIndoor) {
// // //       setState(() {
// // //         _showIndoor = false;
// // //         _indoorBuildingCode = null;
// // //         _selectedIndoorFloorAsset = null;
// // //         _indoorFloors = [];
// // //         _indoorPolygons = {};
// // //         _indoorGeoJson = null;
// // //         _roomLabelMarkers = {};
// // //       });
// // //       return;
// // //     }

// // //   // turn ON (needs selected building)
// // //   final b = _selectedBuildingPoly;
// // //   if (b == null) return;
// // //     final b = _selectedBuildingPoly;
// // //     if (b == null) return;

// // //   final floors = IndoorFloorConfig.floorsForBuilding(b.code);
// // //   if (floors.isEmpty) {
// // //     if (!mounted) return;
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       const SnackBar(content: Text('No indoor maps available for this building')),
// // //     );
// // //     return;
// // //   }
// // //     final floors = _floorsForBuilding(b.code);
// // //     if (floors.isEmpty) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text('Indoor map not available for this building'),
// // //         ),
// // //       );
// // //       return;
// // //     }

// // //   setState(() {
// // //     _indoorFloors = floors;
// // //     _selectedIndoorFloorAsset = floors.first.assetPath;
// // //   });
// // //     setState(() {
// // //       _indoorBuildingCode = b.code;
// // //       _indoorFloors = floors;
// // //     });

// // //     await _loadIndoorFloor(floors.first.assetPath);
// // //   }

// // //   Future<void> _goToMyLocation() async {
// // //     final controller = _mapController;
// // //     if (controller == null) return;

// // //     var loc = _currentLocation;

// // //     if (loc == null) {
// // //       try {
// // //         final p = await Geolocator.getCurrentPosition();
// // //         loc = LatLng(p.latitude, p.longitude);
// // //         if (mounted) setState(() => _currentLocation = loc);
// // //       } catch (_) {
// // //         return;
// // //       }
// // //     }

// // //     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
// // //   }

// // //   Future<void> _openLink(String url) async {
// // //     if (url.trim().isEmpty) return;

// // //     final uri = Uri.tryParse(url);
// // //     if (uri == null) return;

// // //     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
// // //     if (!ok) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
// // //     }
// // //   }

// // //   LatLng _polygonCenter(List<LatLng> pts) {
// // //     if (pts.length < 3) return pts.first;

// // //     double lat = 0;
// // //     double lng = 0;
// // //     for (final p in pts) {
// // //       lat += p.latitude;
// // //       lng += p.longitude;
// // //     }
// // //     final avg = LatLng(lat / pts.length, lng / pts.length);

// // //     if (_isPointInPolygon(avg, pts)) return avg;

// // //     double maxDist = 0;
// // //     LatLng best = avg;
// // //     for (int i = 0; i < pts.length; i++) {
// // //       for (int j = i + 1; j < pts.length; j++) {
// // //         final mid = LatLng(
// // //           (pts[i].latitude + pts[j].latitude) / 2,
// // //           (pts[i].longitude + pts[j].longitude) / 2,
// // //         );
// // //         final dist =
// // //             (pts[i].latitude - pts[j].latitude) *
// // //                 (pts[i].latitude - pts[j].latitude) +
// // //             (pts[i].longitude - pts[j].longitude) *
// // //                 (pts[i].longitude - pts[j].longitude);
// // //         if (dist > maxDist && _isPointInPolygon(mid, pts)) {
// // //           maxDist = dist;
// // //           best = mid;
// // //         }
// // //       }
// // //     }

// // //     return best;
// // //   }

// // //   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
// // //     bool inside = false;
// // //     int j = polygon.length - 1;

// // //     for (int i = 0; i < polygon.length; i++) {
// // //       final xi = polygon[i].latitude;
// // //       final yi = polygon[i].longitude;
// // //       final xj = polygon[j].latitude;
// // //       final yj = polygon[j].longitude;

// // //       if (((yi > point.longitude) != (yj > point.longitude)) &&
// // //           (point.latitude <
// // //               (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
// // //         inside = !inside;
// // //       }
// // //       j = i;
// // //     }

// // //     return inside;
// // //   }

// // //   double _polygonArea(List<LatLng> pts) {
// // //     double area = 0;
// // //     int j = pts.length - 1;
// // //     for (int i = 0; i < pts.length; i++) {
// // //       area +=
// // //           (pts[j].longitude + pts[i].longitude) *
// // //           (pts[j].latitude - pts[i].latitude);
// // //       j = i;
// // //     }
// // //     return area.abs() / 2;
// // //   }

// // //   void _schedulePopupUpdate() {
// // //     _popupDebounce?.cancel();
// // //     _popupDebounce = Timer(
// // //       const Duration(milliseconds: 16),
// // //       _updatePopupOffset,
// // //     );
// // //   }

// // //   Future<void> _updatePopupOffset() async {
// // //     final controller = _mapController;
// // //     final center = _selectedBuildingCenter;
// // //     if (!mounted || controller == null || center == null) return;

// // //     final sc = await controller.getScreenCoordinate(center);
// // //     if (!mounted) return;

// // //     double x = sc.x.toDouble();
// // //     double y = sc.y.toDouble();

// // //     final dpr = MediaQuery.of(context).devicePixelRatio;
// // //     x = x / dpr;
// // //     y = y / dpr;

// // //     setState(() {
// // //       _anchorOffset = Offset(x, y);
// // //     });
// // //   }

// // //   // ignore: unused_element
// // //   void _selectBuildingWithoutMap(BuildingPolygon b) {
// // //     final center = geo.polygonCenter(b.points);
// // //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// // //     _searchController.value = TextEditingValue(
// // //       text: name,
// // //       selection: TextSelection.collapsed(offset: name.length),
// // //     );

// // //     setState(() {
// // //       _selectedBuildingPoly = b;
// // //       _selectedBuildingCenter = center;
// // //       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
// // //       _cameraMoving = false;
// // //     });
// // //   }

// // //   void _onBuildingTapped(BuildingPolygon b) {
// // //     final center = geo.polygonCenter(b.points);
// // //     final controller = _mapController;
// // //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// // //     _searchController.value = TextEditingValue(
// // //       text: name,
// // //       selection: TextSelection.collapsed(offset: name.length),
// // //     );

// // //     setState(() {
// // //       _selectedBuildingPoly = b;
// // //       _selectedBuildingCenter = center;
// // //       _anchorOffset = null;
// // //       _cameraMoving = true;
// // //       _clearIndoorState();
// // //       _roomLabelMarkers = {};

// // //       _availableFloorsForSelectedBuilding =
// // //           _getAvailableFloorsForBuilding(b.code);
// // //       _selectedIndoorFloor = _availableFloorsForSelectedBuilding.isNotEmpty
// // //           ? _availableFloorsForSelectedBuilding.first
// // //           : 1;
// // //     });

// // //     if (controller == null) return;

// // //     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
// // //       _,
// // //     ) async {
// // //       if (!mounted) return;
// // //       await _updatePopupOffset();
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _cameraMoving = false;
// // //       });
// // //     });
// // //   }

// // //   void _closePopup() {
// // //     _clearSelectedBuilding(clearSearch: true);
// // //   }

// // //   void _clearSelectedBuilding({bool clearSearch = false}) {
// // //     setState(() {
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _selectedSearchResult = null;
// // //       _anchorOffset = null;
// // //       _routePolylines = {};
// // //       _showRoutePreview = false;
// // //       _routeOriginSuggestions = [];
// // //       _routeDestinationSuggestions = [];
// // //       _routeDurations.clear();
// // //       _routeDistances.clear();
// // //       _routeArrivalTimes.clear();
// // //       _routePointsByMode.clear();
// // //       _routeSegmentsByMode.clear();
// // //       _isLoadingRouteData = false;
// // //       _selectedTravelMode = RouteTravelMode.driving;
// // //       _destinationRoomMarker = null;
// // //       _shuttleNextBuses = [];
// // //       _shuttleWalkingMinutes = null;
// // //       if (clearSearch) {
// // //         _searchController.clear();
// // //       }
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _anchorOffset = null;
// // //       _destinationRoomMarker = null;
// // //       _routeOriginBuildingCode = null;
// // //       _routeDestinationBuildingCode = null;
// // //       _originRoomController.clear();
// // //       _destinationRoomController.clear();
// // //     });
// // //   }

// // //   Future<void> _getDirections() async {
// // //     print('[DEBUG] Get directions button clicked');
// // //     print('[DEBUG] Current location: $_currentLocation');
// // //     print(
// // //       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
// // //     );

// // //     final origin = _currentLocation;
// // //     final destination = _selectedBuildingPoly?.center;

// // //     if (origin == null) {
// // //       print('[ERROR] Cannot get directions: Current location is null');
// // //       print(
// // //         '[ERROR] Make sure location services are enabled and location is set in emulator',
// // //       );
// // //       return;
// // //     }

// // //     if (destination == null) {
// // //       print('[ERROR] Cannot get directions: Destination is null');
// // //       return;
// // //     }

// // //     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

// // //     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

// // //     setState(() {
// // //       _selectedBuildingCenter = null;
// // //       _anchorOffset = null;
// // //       _showRoutePreview = true;
// // //       _routeOrigin = origin;
// // //       _routeDestination = destination;
// // //       _routeOriginText = currentLocationTag;
// // //       _routeDestinationText =
// // //           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
// // //       _routeOriginBuildingCode =
// // //           currentBuildingCode; // current location has no building code
// // //       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
// // //       print(
// // //         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
// // //       );
// // //     });

// // //     await _fetchRoutesAndDurations();
// // //   }

// // //   Future<void> _fetchRoutesAndDurations() async {
// // //     final origin = _routeOrigin;
// // //     final destination = _routeDestination;

// // //     if (origin == null || destination == null) {
// // //       print('[ERROR] Cannot fetch route: origin or destination is null');
// // //       return;
// // //     }

// // //     print(
// // //       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
// // //     );

// // //     setState(() {
// // //       _isLoadingRouteData = true;
// // //     });

// // //     try {
// // //       final futures = _supportedTravelModes.map(
// // //         (mode) => GoogleDirectionsService.instance.getRouteDetails(
// // //           origin: origin,
// // //           destination: destination,
// // //           mode: mode.apiValue,
// // //         ),
// // //       );

// // //       final results = await Future.wait(futures);
// // //       final durations = <String, String?>{};
// // //       final distances = <String, String?>{};
// // //       final arrivalTimes = <String, String?>{};
// // //       final pointsByMode = <String, List<LatLng>>{};
// // //       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
// // //       final stepsByMode = <String, List<NavigationStep>>{};

// // //       for (var i = 0; i < _supportedTravelModes.length; i++) {
// // //         final mode = _supportedTravelModes[i].apiValue;
// // //         final route = results[i];
// // //         durations[mode] = route?.durationText;
// // //         distances[mode] = route?.distanceText;
// // //         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
// // //         stepsByMode[mode] = route?.steps ?? const [];
// // //         if (route != null && route.points.isNotEmpty) {
// // //           pointsByMode[mode] = route.points;
// // //         }
// // //         if (route != null && route.transitSegments.isNotEmpty) {
// // //           segmentsByMode[mode] = route.transitSegments;
// // //         }
// // //       }

// // //       if (!mounted) return;

// // //       setState(() {
// // //         _routeDurations
// // //           ..clear()
// // //           ..addAll(durations);
// // //         _routeDistances
// // //           ..clear()
// // //           ..addAll(distances);
// // //         _routeArrivalTimes
// // //           ..clear()
// // //           ..addAll(arrivalTimes);
// // //         _routePointsByMode
// // //           ..clear()
// // //           ..addAll(pointsByMode);
// // //         _routeSegmentsByMode
// // //           ..clear()
// // //           ..addAll(segmentsByMode);
// // //         _routeStepsByMode
// // //           ..clear()
// // //           ..addAll(stepsByMode);

// // //         _isLoadingRouteData = false;
// // //       });

// // //       _applySelectedModeRoute(animateCamera: true);

// // //       _fetchShuttleInfo();
// // //     } catch (e) {
// // //       print('Error getting directions: $e');
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _isLoadingRouteData = false;
// // //       });
// // //     }
// // //   }

// // //   void _openStepsForSelectedMode() {
// // //     // ── NEW: shuttle uses a schedule modal instead of steps ───────────────
// // //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// // //       _showShuttleScheduleModal();
// // //       return;
// // //     }

// // //     final key = _selectedTravelMode.apiValue;
// // //     final steps = _routeStepsByMode[key] ?? const [];

// // //     showNavigationStepsModal(
// // //       context,
// // //       title: _selectedTravelMode.label,
// // //       steps: steps,
// // //       totalDuration: _routeDurations[key],
// // //       totalDistance: _routeDistances[key],
// // //     );
// // //   }

// // //   void _applySelectedModeRoute({required bool animateCamera}) {
// // //     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

// // //     final selectedModeKey = _selectedTravelMode.apiValue;
// // //     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
// // //     if (_selectedTravelMode == RouteTravelMode.transit &&
// // //         selectedSegments != null &&
// // //         selectedSegments.isNotEmpty) {
// // //       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
// // //       return;
// // //     }

// // //     final selectedPoints = _routePointsByMode[selectedModeKey];

// // //     if (selectedPoints == null || selectedPoints.isEmpty) {
// // //       setState(() {
// // //         _routePolylines = {};
// // //       });
// // //       return;
// // //     }

// // //     setState(() {
// // //       _routePolylines = {
// // //         Polyline(
// // //           polylineId: const PolylineId('route'),
// // //           points: selectedPoints,
// // //           color: const Color(0xFF76263D),
// // //           width: 5,
// // //           patterns: _selectedTravelMode == RouteTravelMode.driving
// // //               ? const []
// // //               : [PatternItem.dot, PatternItem.gap(10)],
// // //         ),
// // //       };
// // //     });

// // //     if (!animateCamera || _mapController == null) return;
// // //     final bounds = geo.calculateBounds(selectedPoints);
// // //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// // //   }

// // //   void _applyTransitSegments(
// // //     List<DirectionsRouteSegment> segments, {
// // //     required bool animateCamera,
// // //   }) {
// // //     final polylines = <Polyline>{};
// // //     final allPoints = <LatLng>[];

// // //     for (var i = 0; i < segments.length; i++) {
// // //       final segment = segments[i];
// // //       if (segment.points.isEmpty) {
// // //         continue;
// // //       }

// // //       allPoints.addAll(segment.points);

// // //       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
// // //       polylines.add(
// // //         Polyline(
// // //           polylineId: PolylineId('route_segment_$i'),
// // //           points: segment.points,
// // //           color: _resolveTransitSegmentColor(segment),
// // //           width: 5,
// // //           patterns: isWalking
// // //               ? [PatternItem.dot, PatternItem.gap(10)]
// // //               : const [],
// // //         ),
// // //       );
// // //     }

// // //     if (polylines.isEmpty) {
// // //       setState(() {
// // //         _routePolylines = {};
// // //       });
// // //       return;
// // //     }

// // //     setState(() {
// // //       _routePolylines = polylines;
// // //     });

// // //     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
// // //       return;
// // //     }

// // //     final bounds = geo.calculateBounds(allPoints);
// // //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// // //   }

// // //   void _startNavigation() {
// // //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text(
// // //             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
// // //           ),
// // //           duration: Duration(seconds: 3),
// // //         ),
// // //       );
// // //       return;
// // //     }

// // //     final key = _selectedTravelMode.apiValue;
// // //     final steps = _routeStepsByMode[key] ?? const [];

// // //     if (steps.isEmpty) {
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text('No steps available for this route')),
// // //         );
// // //       }
// // //       return;
// // //     }

// // //     setState(() {
// // //       _isNavigating = true;
// // //       _navModeKey = key;
// // //       _navStepIndex = 0;

// // //       _navigationFollowUser = true;
// // //       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// // //     });

// // //     if (_currentLocation != null && _mapController != null) {
// // //       try {
// // //         final currentPos = _currentLocation!;
// // //         final initialCam = CameraPosition(
// // //           target: currentPos,
// // //           zoom: _navZoom,
// // //           tilt: _navTilt,
// // //           bearing: 0.0,
// // //         );
// // //         _mapController!.animateCamera(
// // //           CameraUpdate.newCameraPosition(initialCam),
// // //         );
// // //       } catch (e) {
// // //         print('Error animating camera when starting navigation: $e');
// // //       }
// // //     }
// // //   }

// // //   void _stopNavigation() {
// // //     setState(() {
// // //       _isNavigating = false;
// // //       _navModeKey = null;
// // //       _navStepIndex = 0;
// // //       _navigationFollowUser = false;
// // //     });
// // //     if (_mapController != null && _currentLocation != null) {
// // //       try {
// // //         final cam = CameraPosition(
// // //           target: _currentLocation!,
// // //           zoom: _defaultZoom,
// // //           tilt: _defaultTilt,
// // //           bearing: _defaultBearing,
// // //         );

// // //         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// // //       } catch (e) {
// // //         print('Error resetting camera after navigation: $e');
// // //       }
// // //     }

// // //     _closeRoutePreview();
// // //   }

// // //   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
// // //     if (_mapController == null) return;
// // //     if (!_navigationFollowUser) return;

// // //     final now = DateTime.now();

// // //     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
// // //       return;
// // //     }

// // //     double bearing = 0.0;
// // //     if (heading != null && heading >= 0.0) {
// // //       bearing = heading;
// // //     }

// // //     final cam = CameraPosition(
// // //       target: userLatLng,
// // //       zoom: _navZoom,
// // //       tilt: _navTilt,
// // //       bearing: bearing,
// // //     );

// // //     try {
// // //       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// // //     } catch (e) {
// // //       print('Error animating navigation camera: $e');
// // //     }
// // //   }

// // //   void _maybeAdvanceNavigationStep(LatLng user) {
// // //     final key = _navModeKey;
// // //     if (key == null) return;

// // //     final steps = _routeStepsByMode[key] ?? const [];
// // //     if (steps.isEmpty) return;

// // //     if (_navStepIndex >= steps.length - 1) return;

// // //     final current = steps[_navStepIndex];
// // //     final end = current.endPoint;
// // //     if (end == null) return;

// // //     final d = Geolocator.distanceBetween(
// // //       user.latitude,
// // //       user.longitude,
// // //       end.latitude,
// // //       end.longitude,
// // //     );

// // //     if (d <= 20) {
// // //       setState(() => _navStepIndex += 1);
// // //     }
// // //   }

// // //   void _closeRoutePreview() {
// // //     setState(() {
// // //       _showRoutePreview = false;
// // //       _routePolylines = {};
// // //       _routeOriginSuggestions = [];
// // //       _routeDestinationSuggestions = [];
// // //       _routeDurations.clear();
// // //       _routeDistances.clear();
// // //       _routeArrivalTimes.clear();
// // //       _routePointsByMode.clear();
// // //       _routeSegmentsByMode.clear();
// // //       _isLoadingRouteData = false;
// // //       _selectedTravelMode = RouteTravelMode.driving;
// // //       _searchController.clear();

// // //       //reset indoor map and building selection state
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _anchorOffset = null;
// // //       _destinationRoomMarker = null;
// // //       _originRoomController.clear();
// // //       _destinationRoomController.clear();
// // //       _routeOriginBuildingCode = null;
// // //       _routeDestinationBuildingCode = null;
// // //       _shuttleNextBuses = [];
// // //       _shuttleWalkingMinutes = null;
// // //     });
// // //   }

// // //   String? _formatArrivalTime(int? durationSeconds) {
// // //     if (durationSeconds == null) {
// // //       return null;
// // //     }

// // //     final now = DateTime.now();
// // //     final arrival = now.add(Duration(seconds: durationSeconds));
// // //     int hour = arrival.hour;
// // //     final minute = arrival.minute.toString().padLeft(2, '0');
// // //     final isPm = hour >= 12;
// // //     final period = isPm ? 'pm' : 'am';
// // //     hour = hour % 12;
// // //     if (hour == 0) {
// // //       hour = 12;
// // //     }
// // //     return '$hour:$minute $period';
// // //   }

// // //   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
// // //     const defaultRed = Color(0xFF76263D);
// // //     final mode = segment.travelMode.toUpperCase();
// // //     if (mode == 'WALKING') {
// // //       return defaultRed;
// // //     }

// // //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// // //     if (vehicleType == 'BUS') {
// // //       return Colors.blue;
// // //     }

// // //     final lineColor = parseHexColor(segment.transitLineColorHex);
// // //     if (lineColor != null) {
// // //       return lineColor;
// // //     }

// // //     return defaultRed;
// // //   }

// // //   List<TransitDetailItem> _buildTransitDetailItems() {
// // //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// // //     final items = <TransitDetailItem>[];

// // //     for (final segment in segments) {
// // //       if (segment.points.isEmpty) {
// // //         continue;
// // //       }

// // //       final travelMode = segment.travelMode.toUpperCase();
// // //       if (travelMode == 'WALKING') {
// // //         continue;
// // //       }

// // //       final vehicleType = segment.transitVehicleType?.toUpperCase();
// // //       final lineLabel =
// // //           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
// // //       final color = _resolveTransitSegmentColor(segment);

// // //       IconData icon = Icons.directions_transit;
// // //       String title = 'Transit $lineLabel';

// // //       if (vehicleType == 'BUS') {
// // //         icon = Icons.directions_bus;
// // //         title = 'Bus $lineLabel';
// // //       } else if (vehicleType == 'SUBWAY' ||
// // //           vehicleType == 'METRO_RAIL' ||
// // //           vehicleType == 'HEAVY_RAIL' ||
// // //           vehicleType == 'COMMUTER_TRAIN' ||
// // //           vehicleType == 'RAIL' ||
// // //           vehicleType == 'TRAM' ||
// // //           vehicleType == 'LIGHT_RAIL' ||
// // //           vehicleType == 'MONORAIL') {
// // //         icon = Icons.directions_subway;
// // //         title = 'Metro $lineLabel';
// // //       }

// // //       items.add(TransitDetailItem(icon: icon, color: color, title: title));
// // //     }

// // //     return items;
// // //   }

// // //   // ignore: unused_element
// // //   List<DirectionsRouteSegment> _getTransitDetailSegments() {
// // //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// // //     return segments
// // //         .where(
// // //           (segment) =>
// // //               segment.travelMode.toUpperCase() == 'TRANSIT' &&
// // //               segment.points.isNotEmpty,
// // //         )
// // //         .toList();
// // //   }

// // //   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
// // //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// // //     final lineLabel =
// // //         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

// // //     if (vehicleType == 'BUS') {
// // //       return 'Bus $lineLabel';
// // //     }

// // //     if (vehicleType == 'SUBWAY' ||
// // //         vehicleType == 'METRO_RAIL' ||
// // //         vehicleType == 'HEAVY_RAIL' ||
// // //         vehicleType == 'COMMUTER_TRAIN' ||
// // //         vehicleType == 'RAIL' ||
// // //         vehicleType == 'TRAM' ||
// // //         vehicleType == 'LIGHT_RAIL' ||
// // //         vehicleType == 'MONORAIL') {
// // //       return 'Metro $lineLabel';
// // //     }

// // //     return 'Transit $lineLabel';
// // //   }

// // //   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
// // //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// // //     if (vehicleType == 'BUS') {
// // //       return Icons.directions_bus;
// // //     }
// // //     if (vehicleType == 'SUBWAY' ||
// // //         vehicleType == 'METRO_RAIL' ||
// // //         vehicleType == 'HEAVY_RAIL' ||
// // //         vehicleType == 'COMMUTER_TRAIN' ||
// // //         vehicleType == 'RAIL' ||
// // //         vehicleType == 'TRAM' ||
// // //         vehicleType == 'LIGHT_RAIL' ||
// // //         vehicleType == 'MONORAIL') {
// // //       return Icons.directions_subway;
// // //     }
// // //     return Icons.directions_transit;
// // //   }

// // //   // ignore: unused_element
// // //   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
// // //     const burgundy = Color(0xFF76263D);

// // //     return Container(
// // //       width: 340,
// // //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.15),
// // //             blurRadius: 8,
// // //             offset: const Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           const Text(
// // //             'Transit details',
// // //             style: TextStyle(
// // //               fontSize: 12,
// // //               fontWeight: FontWeight.w600,
// // //               color: burgundy,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 6),
// // //           for (final segment in segments)
// // //             Padding(
// // //               padding: const EdgeInsets.only(bottom: 6),
// // //               child: Row(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   Icon(
// // //                     _transitSegmentIcon(segment),
// // //                     size: 16,
// // //                     color: _resolveTransitSegmentColor(segment),
// // //                   ),
// // //                   const SizedBox(width: 8),
// // //                   Expanded(
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.start,
// // //                       children: [
// // //                         Text(
// // //                           _formatTransitSegmentTitle(segment),
// // //                           style: const TextStyle(
// // //                             fontSize: 12,
// // //                             fontWeight: FontWeight.w600,
// // //                             color: Colors.black87,
// // //                           ),
// // //                         ),
// // //                         if (segment.transitHeadsign != null &&
// // //                             segment.transitHeadsign!.trim().isNotEmpty)
// // //                           Text(
// // //                             segment.transitHeadsign!,
// // //                             style: const TextStyle(
// // //                               fontSize: 11,
// // //                               color: Colors.black54,
// // //                             ),
// // //                           ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Color? parseHexColor(String? hex) {
// // //     if (hex == null || hex.trim().isEmpty) {
// // //       return null;
// // //     }

// // //     final normalized = hex.trim().replaceFirst('#', '');
// // //     if (normalized.length != 6) {
// // //       return null;
// // //     }

// // //     final value = int.tryParse(normalized, radix: 16);
// // //     if (value == null) {
// // //       return null;
// // //     }

// // //     return Color(0xFF000000 | value);
// // //   }

// // //   void _switchOriginDestination() {
// // //     setState(() {
// // //       final tempOrigin = _routeOriginText;
// // //       final tempOriginLatLng = _routeOrigin;
// // //       final tempDestination = _routeDestinationText;
// // //       final tempDestinationLatLng = _routeDestination;

// // //       _routeOriginText = tempDestination;
// // //       _routeOrigin = tempDestinationLatLng;
// // //       _routeDestinationText = tempOrigin;
// // //       _routeDestination = tempOriginLatLng;

// // //       _routeOriginSuggestions = [];
// // //       _routeDestinationSuggestions = [];
// // //     });

// // //     _fetchRoutesAndDurations();
// // //   }

// // //   void _onTravelModeSelected(RouteTravelMode mode) {
// // //     setState(() {
// // //       _selectedTravelMode = mode;
// // //     });

// // //     if (mode == RouteTravelMode.shuttle) {
// // //       _fetchShuttleInfo();
// // //       return;
// // //     }

// // //     if (_routePointsByMode.containsKey(mode.apiValue)) {
// // //       _applySelectedModeRoute(animateCamera: false);
// // //       return;
// // //     }

// // //     _fetchRoutesAndDurations();
// // //   }


// // //   ///shuttle stop marker icon
// // //   Future<void> _createShuttleStopIcon() async {
// // //   _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
// // //     const ImageConfiguration(size: Size(600, 600)),
// // //     'assets/images/shuttle_icon.png',
// // //   );
// // // }

// // //   ///walking time + 4 next buses 
// // //   Future<void> _fetchShuttleInfo() async {
// // //     final origin = _routeOrigin ?? _currentLocation;

// // //     if (origin == null) {
// // //       setState(() {
// // //         _routeDurations['shuttle'] = '–';
// // //       });
// // //       return;
// // //     }

// // //     setState(() {
// // //       _shuttleNextBuses = [];
// // //       _shuttleWalkingMinutes = null;
// // //     });

// // //     try {
// // //       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
// // //       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

// // //       int walkingSeconds = 0;
// // //       List<LatLng> walkPoints = [];

// // //       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
// // //         origin: origin,
// // //         destination: stopLatLng,
// // //         mode: 'walking',
// // //       );

// // //       if (walkRoute != null) {
// // //         walkingSeconds = walkRoute.durationSeconds ?? 0;
// // //         walkPoints = walkRoute.points;
// // //       }

// // //       final walkingMinutes = (walkingSeconds / 60).ceil();

// // //       final buses = ConcordiaShuttleService.getNextDepartures(
// // //         fromStop: nearestStop,
// // //         now: DateTime.now(),
// // //         count: 4,
// // //         walkingDuration: Duration(seconds: walkingSeconds),
// // //       );

// // //       String shuttleDurationLabel;
// // //       if (!ConcordiaShuttleService.isInService()) {
// // //         shuttleDurationLabel = 'No service';
// // //       } else if (buses.isNotEmpty) {
// // //         shuttleDurationLabel = buses.first.statusLabel;
// // //       } else {
// // //         shuttleDurationLabel = '–';
// // //       }

// // //       if (walkPoints.isNotEmpty) {
// // //         setState(() {
// // //           _routePolylines = {
// // //             Polyline(
// // //               polylineId: const PolylineId('shuttle_walk'),
// // //               points: walkPoints,
// // //               color: const Color(0xFF76263D),
// // //               width: 5,
// // //               patterns: [PatternItem.dot, PatternItem.gap(10)],
// // //             ),
// // //           };
// // //         });

// // //         if (_mapController != null) {
// // //           final bounds = _calculateBounds([...walkPoints, stopLatLng]);
// // //           _mapController!
// // //               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// // //         }
// // //       } else {
// // //         setState(() {
// // //           _routePolylines = {};
// // //         });
// // //       }

// // //       if (!mounted) return;
// // //       setState(() {
// // //         _shuttleNearestStop = nearestStop;
// // //         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
// // //         _shuttleNextBuses = buses;
// // //         _routeDurations['shuttle'] = shuttleDurationLabel;
// // //       });
// // //     } catch (e) {
// // //       print('Error fetching shuttle info: $e');
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _routeDurations['shuttle'] = '–';
// // //       });
// // //     }
// // //   }

// // //   //open full day schedule 
// // //   void _showShuttleScheduleModal() {
// // //     showModalBottomSheet<void>(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) =>
// // //           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
// // //     );
// // //   }


// // //   Future<void> _onRouteOriginChanged(String query) async {
// // //     if (query.trim().isEmpty) {
// // //       setState(() {
// // //         _routeOriginSuggestions = [];
// // //       });
// // //       return;
// // //     }

// // //     setState(() {
// // //       _routeOriginSuggestions = [];
// // //     });

// // //     _routeDebounceTimer?.cancel();
// // //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// // //       try {
// // //         print('[DEBUG] Searching for origin: $query');
// // //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// // //           query,
// // //           userLocation: _currentLocation,
// // //         );
// // //         print('[DEBUG] Found ${suggestions.length} origin suggestions');
// // //         if (mounted) {
// // //           setState(() {
// // //             _routeOriginSuggestions = suggestions;
// // //           });
// // //         }
// // //       } catch (e) {
// // //         print('[ERROR] Error getting origin suggestions: $e');
// // //       }
// // //     });
// // //   }

// // //   Future<void> _onRouteDestinationChanged(String query) async {
// // //     if (query.trim().isEmpty) {
// // //       setState(() {
// // //         _routeDestinationSuggestions = [];
// // //       });
// // //       return;
// // //     }

// // //     setState(() {
// // //       _routeDestinationSuggestions = [];
// // //     });

// // //     _routeDebounceTimer?.cancel();
// // //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// // //       try {
// // //         print('[DEBUG] Searching for destination: $query');
// // //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// // //           query,
// // //           userLocation: _currentLocation,
// // //         );
// // //         print('[DEBUG] Found ${suggestions.length} destination suggestions');
// // //         if (mounted) {
// // //           setState(() {
// // //             _routeDestinationSuggestions = suggestions;
// // //           });
// // //         }
// // //       } catch (e) {
// // //         print('[ERROR] Error getting destination suggestions: $e');
// // //       }
// // //     });
// // //   }

// // //   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
// // //     print(
// // //       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
// // //     );
// // //     LatLng? newOrigin;
// // //     String displayText = suggestion.name;
// // //     String? buildingCode;

// // //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// // //       print('[DEBUG] Handling Concordia building');
// // //       final building = BuildingSearchService.searchBuilding(
// // //         suggestion.buildingName!.code,
// // //       );
// // //       newOrigin = building?.center;
// // //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// // //       buildingCode = suggestion.buildingName!.code;
// // //       print('[DEBUG] Concordia building origin: $newOrigin');
// // //     } else if (suggestion.placeId != null) {
// // //       print(
// // //         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
// // //       );
// // //       try {
// // //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// // //           suggestion.placeId!,
// // //         );
// // //         print('[DEBUG] Place details result: $placeDetails');
// // //         if (placeDetails != null) {
// // //           newOrigin = placeDetails.location;
// // //           buildingCode = null;
// // //           print('[DEBUG] Non-Concordia origin location: $newOrigin');
// // //         } else {
// // //           print(
// // //             '[ERROR] Place details returned null for ${suggestion.placeId}',
// // //           );
// // //         }
// // //       } catch (e) {
// // //         print('[ERROR] Error fetching place details: $e');
// // //         return;
// // //       }
// // //     }

// // //     if (newOrigin != null) {
// // //       print('[DEBUG] Updating route origin state');
// // //       print('[DEBUG] New origin building code: $buildingCode');
// // //       setState(() {
// // //         _routeOrigin = newOrigin;
// // //         _routeOriginText = displayText;
// // //         _routeOriginSuggestions = [];
// // //         _routeOriginBuildingCode = buildingCode;
// // //         _originRoomController.clear();
// // //       });
// // //       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
// // //       await _fetchRoutesAndDurations();
// // //     } else {
// // //       print('[ERROR] Could not determine origin location');
// // //     }
// // //   }

// // //   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
// // //     LatLng? newDestination;
// // //     String displayText = suggestion.name;
// // //     String? buildingCode;

// // //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// // //       final building = BuildingSearchService.searchBuilding(
// // //         suggestion.buildingName!.code,
// // //       );
// // //       newDestination = building?.center;
// // //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// // //       buildingCode = suggestion.buildingName!.code;
// // //     } else if (suggestion.placeId != null) {
// // //       try {
// // //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// // //           suggestion.placeId!,
// // //         );
// // //         if (placeDetails != null) {
// // //           newDestination = placeDetails.location;
// // //           buildingCode = null;
// // //         }
// // //       } catch (e) {
// // //         print('Error fetching place details: $e');
// // //         return;
// // //       }
// // //     }

// // //     if (newDestination != null) {
// // //       print('[DEBUG] Updating route destination state');
// // //       print('[DEBUG] New destination building code: $buildingCode');
// // //       setState(() {
// // //         _routeDestination = newDestination;
// // //         _routeDestinationText = displayText;
// // //         _routeDestinationSuggestions = [];
// // //         _routeDestinationBuildingCode = buildingCode;
// // //         _destinationRoomController.clear();
// // //       });
// // //       await _fetchRoutesAndDurations();
// // //     }
// // //   }

// // //   void _hideBuildingPopup() {
// // //     if (_selectedBuildingPoly == null) return;

// // //     _clearSelectedBuilding();
// // //   }

// // //   Future<void> _onSearchSubmitted(String query) async {
// // //     if (query.trim().isEmpty) return;

// // //     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

// // //     if (concordiaBuilding != null) {
// // //       _onBuildingTapped(concordiaBuilding);
// // //       return;
// // //     }

// // //     final results = await BuildingSearchService.searchWithGooglePlaces(
// // //       query,
// // //       userLocation: _currentLocation,
// // //     );

// // //     if (results.isNotEmpty) {
// // //       SearchResult? selectedResult;

// // //       for (final result in results) {
// // //         if (!result.isConcordiaBuilding) {
// // //           selectedResult = result;
// // //           break;
// // //         }
// // //       }

// // //       if (selectedResult == null && results.isNotEmpty) {
// // //         selectedResult = results.first;
// // //       }

// // //       if (selectedResult != null) {
// // //         if (selectedResult.isConcordiaBuilding &&
// // //             selectedResult.buildingPolygon != null) {
// // //           _onBuildingTapped(selectedResult.buildingPolygon!);
// // //         } else {
// // //           _onPlaceSelected(selectedResult);
// // //         }
// // //       }
// // //     } else {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('"$query" not found'),
// // //           duration: const Duration(seconds: 2),
// // //           backgroundColor: const Color(0xFF800020),
// // //         ),
// // //       );
// // //       _searchController.clear();
// // //     }
// // //   }

// // //   void _onPlaceSelected(SearchResult result) {
// // //     final controller = _mapController;
// // //     if (controller == null) return;

// // //     setState(() {
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _selectedSearchResult = result;
// // //     });

// // //     _searchController.value = TextEditingValue(
// // //       text: result.name,
// // //       selection: TextSelection.collapsed(offset: result.name.length),
// // //     );

// // //     if (result.isConcordiaBuilding) {
// // //       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('${result.name} is a Concordia building'),
// // //           duration: const Duration(seconds: 3),
// // //           backgroundColor: const Color(0xFF800020),
// // //         ),
// // //       );
// // //     } else {
// // //       if (_currentLocation == null) {
// // //         controller.animateCamera(
// // //           CameraUpdate.newLatLngZoom(result.location, 18),
// // //         );
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text('${result.name} is not a Concordia building'),
// // //             duration: const Duration(seconds: 2),
// // //             backgroundColor: Colors.grey[700],
// // //           ),
// // //         );
// // //       } else {
// // //         _enterRoutePreviewForPlace(result);
// // //       }
// // //     }
// // //   }

// // //   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
// // //     if (_currentLocation == null) return;

// // //     print(
// // //       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
// // //     );

// // //     setState(() {
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _anchorOffset = null;
// // //       _showRoutePreview = true;
// // //       _routeOrigin = _currentLocation;
// // //       _routeDestination = place.location;
// // //       _routeOriginText = currentLocationTag;
// // //       _routeDestinationText = place.name;
// // //       _selectedSearchResult = place;
// // //     });

// // //     print(
// // //       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
// // //     );

// // //     await _fetchRoutesAndDurations();
// // //   }

// // //   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
// // //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// // //       final buildingPolygon = BuildingSearchService.searchBuilding(
// // //         suggestion.buildingName!.code,
// // //       );
// // //       if (buildingPolygon == null) return;
// // //       _onBuildingTapped(buildingPolygon);
// // //     } else if (suggestion.placeId != null) {
// // //       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// // //         suggestion.placeId!,
// // //       );
// // //       if (placeDetails != null) {
// // //         final concordiaBuilding = BuildingSearchService.searchBuilding(
// // //           suggestion.name,
// // //         );

// // //         if (concordiaBuilding != null) {
// // //           _onBuildingTapped(concordiaBuilding);
// // //         } else {
// // //           final searchResult = SearchResult.fromGooglePlace(
// // //             name: placeDetails.name,
// // //             address: placeDetails.formattedAddress,
// // //             location: placeDetails.location,
// // //             isConcordiaBuilding: false,
// // //             placeId: placeDetails.placeId,
// // //           );
// // //           _onPlaceSelected(searchResult);
// // //         }
// // //       }
// // //     }
// // //   }

// // //   Set<Polygon> _createBuildingPolygons() {
// // //     const burgundy = Color(0xFF800020);
// // //     const selectedBlue = Color(0xFF7F83C3);

// // //     final polys = <Polygon>{};

// // //     for (final b in buildingPolygons) {
// // //       final isCurrent = _currentBuildingPoly?.code == b.code;
// // //       final isSelected = _selectedBuildingPoly?.code == b.code;

// // //       final strokeColor = isSelected
// // //           ? selectedBlue.withOpacity(0.95)
// // //           : isCurrent
// // //           ? Colors.blue.withOpacity(0.8)
// // //           : burgundy.withOpacity(0.55);

// // //       final fillColor = isSelected
// // //           ? selectedBlue.withOpacity(0.25)
// // //           : isCurrent
// // //           ? Colors.blue.withOpacity(0.25)
// // //           : burgundy.withOpacity(0.22);

// // //       final strokeWidth = isSelected
// // //           ? 3
// // //           : isCurrent
// // //           ? 3
// // //           : 2;
// // //       final zIndex = isSelected
// // //           ? 3
// // //           : isCurrent
// // //           ? 2
// // //           : 1;

// // //       polys.add(
// // //         Polygon(
// // //           polygonId: PolygonId('poly_${b.code}'),
// // //           points: b.points,
// // //           strokeWidth: strokeWidth,
// // //           strokeColor: strokeColor,
// // //           fillColor: fillColor,
// // //           zIndex: zIndex,
// // //           consumeTapEvents: true,
// // //           onTap: () => _onBuildingTapped(b),
// // //         ),
// // //       );
// // //     }

// // //     return polys;
// // //   }

// // //   List<Widget> _createBuildingGestureDetectors() {
// // //     final detectors = <Widget>[];

// // //     for (final building in buildingPolygons) {
// // //       detectors.add(
// // //         Positioned(
// // //           left: 0,
// // //           top: 0,
// // //           child: GestureDetector(
// // //             key: Key('building_detector_${building.code}'),
// // //             onTap: () => _onBuildingTapped(building),
// // //             child: Container(
// // //               width: 100,
// // //               height: 100,
// // //               color: Colors.transparent,
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     return detectors;
// // //   }

// // //   @override
// // //   void initState() {
// // //     super.initState();

// // //     _selectedCampus = widget.initialCampus;

// // //     _lastCameraTarget = widget.initialCampus == Campus.loyola
// // //         ? concordiaLoyola
// // //         : concordiaSGW;

// // //     _createBlueDotIcon();
// // //     _createShuttleStopIcon(); // NEW
// // //     _startLocationUpdates();
// // //     _determineUserLocationAndBuilding().then((_) {
// // //       _startLocationUpdates();
// // //     });

// // //     _searchController.addListener(_onSearchChanged);
// // //     // Clear destination room marker when room input changes
// // //     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
// // //     _determineUserLocationAndBuilding();
// // //   }

// // //   Future<void> _determineUserLocationAndBuilding() async {
// // //     // Get user's current location
// // //     final position = await Geolocator.getCurrentPosition();
// // //     _currentLocation = LatLng(position.latitude, position.longitude);

// // //     // Check which building polygon contains the user
// // //     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

// // //     setState(() {
// // //       _currentBuildingCode = buildingAtLocation?.code;
// // //     });
// // //   }

// // //   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
// // //     for (final building in buildingPolygons) {
// // //       if (_isPointInPolygon(location, building.points)) {
// // //         return building;
// // //       }
// // //     }
// // //     return null;
// // //   }

// // //   void _onDestinationRoomTextChanged() {
// // //     if (_destinationRoomMarker == null) return;

// // //     setState(() {
// // //       _destinationRoomMarker = null;
// // //     });
// // //   }

// // //   void _onSearchChanged() {
// // //     _debounceTimer?.cancel();

// // //     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
// // //       final query = _searchController.text;
// // //       try {
// // //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// // //           query,
// // //           userLocation: _currentLocation,
// // //         );
// // //         if (mounted) {
// // //           setState(() {
// // //             _searchSuggestions = suggestions;
// // //           });
// // //         }
// // //       } catch (e) {
// // //         print('Error getting search suggestions: $e');
// // //         if (mounted) {
// // //           setState(() {
// // //             _searchSuggestions = BuildingSearchService.getSuggestions(
// // //               query,
// // //             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
// // //           });
// // //         }
// // //       }
// // //     });
// // //   }

// // //   Future<void> _createBlueDotIcon() async {
// // //     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
// // //       BitmapDescriptor.hueAzure,
// // //     );
// // //   }

// // //   Future<void> _startLocationUpdates() async {
// // //     print('[DEBUG] Starting location updates...');

// // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // //     print('[DEBUG] Location service enabled: $serviceEnabled');

// // //     if (!serviceEnabled) {
// // //       print('[ERROR] Location services are disabled');
// // //       return;
// // //     }

// // //     LocationPermission permission = await Geolocator.checkPermission();
// // //     print('[DEBUG] Initial permission status: $permission');

// // //     if (permission == LocationPermission.denied) {
// // //       permission = await Geolocator.requestPermission();
// // //       print('[DEBUG] Permission after request: $permission');
// // //       if (permission == LocationPermission.denied) {
// // //         print('[ERROR] Location permission denied by user');
// // //         return;
// // //       }
// // //     }

// // //     if (permission == LocationPermission.deniedForever) {
// // //       print('[ERROR] Location permission denied forever');
// // //       return;
// // //     }

// // //     try {
// // //       print('[DEBUG] Attempting to get current position...');
// // //       final position = await Geolocator.getCurrentPosition(
// // //         locationSettings: const LocationSettings(
// // //           accuracy: LocationAccuracy.high,
// // //           timeLimit: Duration(seconds: 10),
// // //         ),
// // //       );
// // //       final newLatLng = LatLng(position.latitude, position.longitude);

// // //       print(
// // //         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
// // //       );
// // //       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

// // //       if (!mounted) return;
// // //       setState(() {
// // //         _currentLocation = newLatLng;
// // //         _currentCampus = detectCampus(newLatLng);
// // //         _currentBuildingPoly = detectBuildingPoly(newLatLng);
// // //       });

// // //       print('[DEBUG] Current campus: $_currentCampus');
// // //       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

// // //       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
// // //     } catch (e) {
// // //       print('[ERROR] Failed to get current position: $e');
// // //       print(
// // //         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
// // //       );
// // //     }

// // //     _posSub =
// // //         Geolocator.getPositionStream(
// // //           locationSettings: const LocationSettings(
// // //             accuracy: LocationAccuracy.best,
// // //             distanceFilter: 5,
// // //           ),
// // //         ).listen((position) {
// // //           final newLatLng = LatLng(position.latitude, position.longitude);
// // //           print(
// // //             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
// // //           );

// // //           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

// // //           if (!mounted) return;
// // //           setState(() {
// // //             _currentLocation = newLatLng;
// // //             _currentCampus = detectCampus(newLatLng);
// // //             _currentBuildingPoly = detectBuildingPoly(newLatLng);
// // //             _currentBuildingCode = buildingAtLocation?.code;
// // //           });

// // //           if (_isNavigating) {
// // //             _maybeAdvanceNavigationStep(newLatLng);
// // //           }
// // //           if (_navigationFollowUser) {
// // //             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
// // //           }
// // //         });
// // //   }

// // //   Set<Marker> _createMarkers() {
// // //     final markers = <Marker>{};
// // //     // Add current location marker
// // //     if (_currentLocation != null) {
// // //       markers.add(
// // //         Marker(
// // //           markerId: const MarkerId('current_location'),
// // //           position: _currentLocation!,
// // //           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
// // //           anchor: const Offset(0.5, 0.5),
// // //           flat: true,
// // //           zIndex: 999,
// // //         ),
// // //       );
// // //     }

// // //     // Add destination room marker only when indoor map is shown
// // //     if (_destinationRoomMarker != null && _showIndoor) {
// // //       markers.add(_destinationRoomMarker!);
// // //     }
// // //     final shuttleIcon = _shuttleStopIcon;
// // //     if (shuttleIcon != null) {
// // //       markers.add(
// // //         Marker(
// // //           markerId: const MarkerId('shuttle_stop_sgw'),
// // //           position: shuttleStopSGW,
// // //           icon: shuttleIcon,
// // //           infoWindow: const InfoWindow(
// // //             title: 'Concordia Shuttle — SGW',
// // //             snippet: 'Hall Building stop',
// // //           ),
// // //           onTap: () {
// // //             if (_showRoutePreview) {
// // //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// // //               _fetchShuttleInfo();
// // //             }
// // //           },
// // //         ),
// // //       );
// // //       markers.add(
// // //         Marker(
// // //           markerId: const MarkerId('shuttle_stop_loyola'),
// // //           position: shuttleStopLoyola,
// // //           icon: shuttleIcon,
// // //           infoWindow: const InfoWindow(
// // //             title: 'Concordia Shuttle — Loyola',
// // //             snippet: 'Loyola campus stop',
// // //           ),
// // //           onTap: () {
// // //             if (_showRoutePreview) {
// // //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// // //               _fetchShuttleInfo();
// // //             }
// // //           },
// // //         ),
// // //       );
// // //     }

// // //     if (_showRoutePreview) {
// // //       if (_routeDestination != null) {
// // //         markers.add(
// // //           Marker(
// // //             markerId: const MarkerId('route_destination'),
// // //             position: _routeDestination!,
// // //             infoWindow: InfoWindow(title: _routeDestinationText),
// // //             icon: BitmapDescriptor.defaultMarkerWithHue(
// // //               BitmapDescriptor.hueRed,
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //     }

// // //     return markers;
// // //   }

// // //   Set<Circle> _createCircles() {
// // //     final circles = <Circle>{};

// // //     if (_currentLocation == null) return {};

// // //     circles.add(
// // //       Circle(
// // //         circleId: const CircleId('current_location_accuracy'),
// // //         center: _currentLocation!,
// // //         radius: 20,
// // //         fillColor: Colors.blue.withOpacity(0.1),
// // //         strokeColor: Colors.blue.withOpacity(0.3),
// // //         strokeWidth: 1,
// // //       ),
// // //     );

// // //     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
// // //       final segments = _routeSegmentsByMode['transit'] ?? const [];
// // //       final seen = <String>{};

// // //       for (final segment in segments) {
// // //         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
// // //           continue;
// // //         }
// // //         if (segment.points.isEmpty) {
// // //           continue;
// // //         }

// // //         final endpoints = [segment.points.first, segment.points.last];
// // //         for (final point in endpoints) {
// // //           final key =
// // //               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
// // //           if (!seen.add(key)) {
// // //             continue;
// // //           }

// // //           circles.add(
// // //             Circle(
// // //               circleId: CircleId('transit_stop_$key'),
// // //               center: point,
// // //               radius: 15,
// // //               fillColor: Colors.white,
// // //               strokeColor: const Color(0xFF76263D),
// // //               strokeWidth: 2,
// // //             ),
// // //           );
// // //         }
// // //       }
// // //     }

// // //     return circles;
// // //   }

// // //   NavigationStep? _getCurrentNavStep() {
// // //     final key = _navModeKey;
// // //     if (key == null) return null;

// // //     final steps = _routeStepsByMode[key] ?? const [];
// // //     if (steps.isEmpty) return null;

// // //     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
// // //     return steps[_navStepIndex];
// // //   }

// // //   void _switchCampus(Campus newCampus) {
// // //     LatLng targetLocation;

// // //     switch (newCampus) {
// // //       case Campus.sgw:
// // //         targetLocation = concordiaSGW;
// // //         break;
// // //       case Campus.loyola:
// // //         targetLocation = concordiaLoyola;
// // //         break;
// // //       case Campus.none:
// // //         return;
// // //     }

// // //     _lastCameraTarget = targetLocation;
// // //     _mapController?.animateCamera(
// // //       CameraUpdate.newLatLngZoom(targetLocation, 16),
// // //     );

// // //     setState(() {
// // //       _selectedCampus = newCampus;
// // //       _selectedBuildingPoly = null;
// // //       _selectedBuildingCenter = null;
// // //       _anchorOffset = null;
// // //       _cameraMoving = false;
// // //       _searchController.clear();
// // //     });
// // //   }

// // //   Offset? _computePopupPosition(BuildContext context) {
// // //   final screen = MediaQuery.of(context).size;
// // //   final topPad = MediaQuery.of(context).padding.top;

// // //   final anchor = widget.debugAnchorOffset ?? _anchorOffset;
// // //   if (anchor == null || _cameraMoving) return null;

// // //   final ax = anchor.dx;
// // //   final ay = anchor.dy;

// // //   final inView =
// // //       ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
// // //   if (!inView) return null;

// // //   double left = ax - (_popupW / 2);
// // //   double top = ay - (_popupH / 2);

// // //   const margin = 8.0;
// // //   final minLeft = margin;
// // //   final maxLeft = screen.width - _popupW - margin;
// // //   final minTop = topPad + margin;
// // //   final maxTop = screen.height - _popupH - margin;

// // //   if (left < minLeft) left = minLeft;
// // //   if (left > maxLeft) left = maxLeft;
// // //   if (top < minTop) top = minTop;
// // //   if (top > maxTop) top = maxTop;

// // //   return Offset(left, top);
// // // }

// // //   Future<void> _onDestinationRoomSubmitted(
// // //     String buildingCode,
// // //     String roomCode,
// // //   ) async {
// // //     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

// // //     try {
// // //       final repo = IndoorMapRepository();
// // //       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

// // //       if (roomLocation == null) {
// // //         print('[ERROR] Could not find location for room $roomCode');
// // //         return;
// // //       }
// // //       print('[DEBUG] Room location found: $roomLocation');
// // //       // Create marker at room location
// // //       final marker = Marker(
// // //         markerId: const MarkerId('destination_room'),
// // //         position: roomLocation,
// // //         infoWindow: InfoWindow(title: 'Room $roomCode'),
// // //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
// // //       );

// // //       // Update state with the new marker
// // //       if (!mounted) return;
// // //       setState(() {
// // //         _destinationRoomMarker = marker;
// // //       });

// // //       print('[DEBUG] Destination room marker placed at $roomLocation');
// // //     } catch (e) {
// // //       print('[ERROR] Error processing destination room: $e');
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Error: $e'),
// // //           backgroundColor: const Color(0xFFE53935),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   @override
// // // Widget build(BuildContext context) {
// // //   final LatLng initialTarget =
// // //       widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

// // //   final Campus labelCampus =
// // //       _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

// // //   final String campusLabel = labelCampus == Campus.sgw
// // //       ? 'SGW'
// // //       : labelCampus == Campus.loyola
// // //           ? 'Loyola'
// // //           : '';

// // //   final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
// // //   final popupPos = _computePopupPosition(context);

// // //   return Scaffold(
// // //     body: Stack(
// // //       children: [
// // //         if (widget.debugDisableMap)
// // //           const SizedBox.expand()
// // //         else
// // //           OutdoorMapView(
// // //             initialTarget: initialTarget,
// // //             showIndoorStyle: _showIndoor,
// // //             indoorMapStyle: _indoorMapStyle,
// // //             onMapCreated: (c) => _mapController = c,
// // //             onCameraMove: (pos) {
// // //               _lastCameraTarget = pos.target;
// // //               if (_selectedBuildingCenter != null) _schedulePopupUpdate();
// // //             },
// // //             onCameraMoveStarted: () {
// // //               if (_selectedBuildingCenter == null) return;
// // //               setState(() => _cameraMoving = true);
// // //             },
// // //             onCameraIdle: () {
// // //               _syncToggleWithCameraCenter();
// // //               if (_selectedBuildingCenter == null) return;
// // //               setState(() => _cameraMoving = false);
// // //               _updatePopupOffset();
// // //             },
// // //             markers: {
// // //               ..._createMarkers(),
// // //               ..._roomLabelMarkers,
// // //             },
// // //             circles: _createCircles(),
// // //             polygons: {
// // //               ..._createBuildingPolygons(),
// // //               ..._indoorPolygons,
// // //             },
// // //             polylines: _routePolylines,
// // //           ),

// // //           if (_isNavigating)
// // //             Positioned(
// // //               top: 80,
// // //               left: 0,
// // //               right: 0,
// // //               child: PointerInterceptor(
// // //                 child: NavigationNextStepHeader(
// // //                   modeLabel: _selectedTravelMode.label,
// // //                   nextStep: _getCurrentNavStep(),
// // //                   onStop: _stopNavigation,
// // //                   onShowSteps: _openStepsForSelectedMode,
// // //                 ),
// // //               ),
// // //             ),
// // //           if (!_showRoutePreview && !_isNavigating)
// // //             Positioned(
// // //               top: 65,
// // //               left: 20,
// // //               right: 20,
// // //               child: Column(
// // //                 mainAxisSize: MainAxisSize.min,
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   MapSearchBar(
// // //                     key: const Key('destination_search_bar'),
// // //                     campusLabel: campusLabel,
// // //                     controller: _searchController,
// // //                     onSubmitted: _onSearchSubmitted,
// // //                     suggestions: _searchSuggestions,
// // //                     onSuggestionSelected: _onSuggestionSelected,
// // //                     onFocus: _hideBuildingPopup,
// // //                   ),
// // //                   if (_showIndoor && _indoorFloors.isNotEmpty) ...[
// // //                     const SizedBox(height: 10),
// // //                     Align(
// // //                       alignment: Alignment.centerRight,
// // //                       child: PointerInterceptor(
// // //                         child: IntrinsicWidth(
// // //                           child: Container(
// // //                             height: 40,
// // //                             padding:
// // //                                 const EdgeInsets.symmetric(horizontal: 12),
// // //                             decoration: BoxDecoration(
// // //                               color: const Color(0xFF8B1D3B),
// // //                               borderRadius: BorderRadius.circular(20),
// // //                               boxShadow: [
// // //                                 BoxShadow(
// // //                                   color: Colors.black.withOpacity(0.25),
// // //                                   blurRadius: 8,
// // //                                   offset: const Offset(0, 3),
// // //                                 ),
// // //                               ],
// // //                             ),
// // //                             child: Center(
// // //                               child: DropdownButtonHideUnderline(
// // //                                 child: DropdownButton<String>(
// // //                                   value: _selectedIndoorFloorAsset ??
// // //                                       _indoorFloors.first.assetPath,
// // //                                   isDense: true,
// // //                                   dropdownColor: const Color(0xFF8B1D3B),
// // //                                   icon: const Icon(
// // //                                     Icons.keyboard_arrow_down,
// // //                                     color: Colors.white,
// // //                                   ),
// // //                                   style: const TextStyle(
// // //                                     color: Colors.white,
// // //                                     fontSize: 15,
// // //                                     fontWeight: FontWeight.w600,
// // //                                   ),
// // //                                   items: _indoorFloors
// // //                                       .map(
// // //                                         (f) => DropdownMenuItem<String>(
// // //                                           value: f.assetPath,
// // //                                           child: Text(
// // //                                             f.label,
// // //                                             style: const TextStyle(
// // //                                                 color: Colors.white),
// // //                                           ),
// // //                                         ),
// // //                                       )
// // //                                       .toList(),
// // //                                   onChanged: (asset) async {
// // //                                     if (asset == null) return;
// // //                                     await _loadIndoorFloor(asset);
// // //                                   },
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ],
// // //               ),
// // //             ),
// // //           if ((widget.debugSelectedBuilding ?? _selectedBuildingPoly) != null &&
// // //               popupLeft != null &&
// // //               popupTop != null)
// // //             Positioned(
// // //               left: popupLeft,
// // //               top: popupTop,
// // //               child: PointerInterceptor(
// // //                 child: BuildingInfoPopup(
// // //                   title:
// // //                       '${buildingInfoByCode[(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code]?.name ?? (widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.name} - ${(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code}',
// // //                   description:
// // //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// // //                                   _selectedBuildingPoly)!
// // //                               .code]
// // //                           ?.description ??
// // //                       'No description available.',
// // //                   accessibility:
// // //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// // //                                   _selectedBuildingPoly)!
// // //                               .code]
// // //                           ?.accessibility ??
// // //                       false,
// // //                   facilities:
// // //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// // //                                   _selectedBuildingPoly)!
// // //                               .code]
// // //                           ?.facilities ??
// // //                       const [],
// // //                   onMore: () {
// // //                     final link =
// // //                         widget.debugLinkOverride ??
// // //                         (buildingInfoByCode[(widget.debugSelectedBuilding ??
// // //                                         _selectedBuildingPoly)!
// // //                                     .code]
// // //                                 ?.link ??
// // //                             '');
// // //                     _openLink(link);
// // //                   },
// // //                   onClose: _closePopup,
// // //                   isLoggedIn: widget.isLoggedIn,
// // //                   onIndoorMap: _toggleIndoorMap,
// // //                   onGetDirections: _getDirections,
// // //                 ),
// // //               ),
// // //             ),

// // //         if (_showRoutePreview && !_isNavigating)
// // //   Positioned(
// // //     top: 80,
// // //     left: 0,
// // //     right: 0,
// // //     child: RoutePreviewPanel(
// // //       originText: _routeOriginText,
// // //       destinationText: _routeDestinationText,
// // //       onClose: _closeRoutePreview,
// // //       onSwitch: _switchOriginDestination,
// // //       onOriginChanged: _onRouteOriginChanged,
// // //       onDestinationChanged: _onRouteDestinationChanged,
// // //       onOriginSelected: _onRouteOriginSelected,
// // //       onDestinationSelected: _onRouteDestinationSelected,
// // //       originSuggestions: _routeOriginSuggestions,
// // //       destinationSuggestions: _routeDestinationSuggestions,

// // //       originRoomController: _originRoomController,
// // //       destinationRoomController: _destinationRoomController,
// // //       onOriginRoomSubmitted: _onOriginRoomSubmitted,
// // //       onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
// // //       originBuildingCode: _routeOriginBuildingCode,
// // //       destinationBuildingCode: _routeDestinationBuildingCode,
// // //       isConcordiaBuilding: (buildingCode) {
// // //         return buildingPolygons.any(
// // //           (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
// // //         );
// // //       },
// // //     ),
// // //   ),

// // //           if (_showRoutePreview)
// // //             Positioned(
// // //               bottom: 25,
// // //               left: 0,
// // //               right: 0,
// // //               child: PointerInterceptor(
// // //                 child: Center(
// // //                   child: RouteTravelModeBar(
// // //                     selectedTravelMode: _selectedTravelMode,
// // //                     onTravelModeSelected: _onTravelModeSelected,
// // //                     modeDurations: _routeDurations,
// // //                     isLoadingDurations: _isLoadingRouteData,
// // //                     onClose: _closeRoutePreview,
// // //                     onStart: _startNavigation,
// // //                     isNavigating: _isNavigating,
// // //                     onShowSteps: _openStepsForSelectedMode,
// // //                     transitDetails: _buildTransitDetailItems(),
// // //                     modeDistances: _routeDistances,
// // //                     modeArrivalTimes: _routeArrivalTimes,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ),

// // //         OutdoorBottomBar(
// // //           showRoutePreview: _showRoutePreview,
// // //           isNavigating: _isNavigating,
// // //           selectedCampus: _selectedCampus,
// // //           onCampusChanged: _switchCampus,
// // //           selectedTravelMode: _selectedTravelMode,
// // //           onTravelModeSelected: _onTravelModeSelected,
// // //           routeDurations: _routeDurations,
// // //           routeDistances: _routeDistances,
// // //           routeArrivalTimes: _routeArrivalTimes,
// // //           isLoadingRouteData: _isLoadingRouteData,
// // //           onCloseRoutePreview: _closeRoutePreview,
// // //           onStartNavigation: _startNavigation,
// // //           onShowSteps: _openStepsForSelectedMode,
// // //           transitDetails: _buildTransitDetailItems(),
// // //         ),

// // //           // Invisible gesture detectors for building polygons (for testing)
// // //           ..._createBuildingGestureDetectors(),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Set<Polygon> _geoJsonToPolygons(Map<String, dynamic> geojson) {
// // //     final features = (geojson['features'] as List).cast<dynamic>();

// // //     final polygons = <Polygon>{};

// // //     for (final f in features) {
// // //       final feature = f as Map<String, dynamic>;
// // //       final geometry = feature['geometry'] as Map<String, dynamic>;
// // //       if (geometry['type'] != 'Polygon') continue;

// // //       final rings = geometry['coordinates'] as List;
// // //       if (rings.isEmpty) continue;

// // //       final outer = rings[0] as List;

// // //       final points = outer.map<LatLng>((p) {
// // //         final coords = p as List;
// // //         final lng = (coords[0] as num).toDouble();
// // //         final lat = (coords[1] as num).toDouble();
// // //         return LatLng(lat, lng); // GeoJSON is [lng,lat]
// // //       }).toList();

// // //       if (points.length < 3) continue;

// // //       final props =
// // //           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
// // //       final id = (props['ref'] ?? polygons.length).toString();

// // //       // Determine fill color based on feature type
// // //       Color fillColor;
// // //       if (props['escalators'] == 'yes') {
// // //         fillColor = Colors.green; // Escalator = green
// // //       } else if (props['highway'] == 'elevator') {
// // //         fillColor = Colors.orange; // Elevator = orange
// // //       } else if (props['highway'] == 'steps') {
// // //         fillColor = Colors.pink; // Steps = pink
// // //       } else if (props['amenity'] == 'toilets') {
// // //         fillColor = Colors.blue; // Toilets = blue
// // //       } else if (props['indoor'] == 'corridor') {
// // //         fillColor = const Color.fromARGB(
// // //           255,
// // //           232,
// // //           122,
// // //           149,
// // //         ); // Corridor = lighter red
// // //       } else {
// // //         fillColor = const Color(0xFF800020); // Default room = dark red
// // //       }

// // //       polygons.add(
// // //         Polygon(
// // //           polygonId: PolygonId('indoor-$id'),
// // //           points: points,
// // //           strokeWidth: 2,
// // //           strokeColor: Colors.black,
// // //           fillColor: fillColor.withOpacity(1.0),
// // //           zIndex: 20,
// // //         ),
// // //       );
// // //     }

// // //     return polygons;
// // //   }

// // //   Future<BitmapDescriptor> _createTextBitmap(
// // //     String text, {
// // //     double fontSize = 10,
// // //   }) async {
// // //     final painter = TextPainter(
// // //       text: TextSpan(
// // //         text: text,
// // //         style: TextStyle(
// // //           color: Colors.white,
// // //           fontSize: fontSize,
// // //           fontWeight: FontWeight.bold,
// // //         ),
// // //       ),
// // //       textDirection: ui.TextDirection.ltr,
// // //     );
// // //     painter.layout();

// // //     final width = painter.width.ceil();
// // //     final height = painter.height.ceil();

// // //     final recorder = ui.PictureRecorder();
// // //     final canvas = Canvas(
// // //       recorder,
// // //       Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
// // //     );

// // //     painter.paint(canvas, Offset.zero);

// // //     final picture = recorder.endRecording();
// // //     ui.Image? img;
// // //     ByteData? byteData;
// // //     try {
// // //       img = await picture.toImage(width, height);
// // //       byteData = await img.toByteData(format: ui.ImageByteFormat.png);
// // //     } finally {
// // //       img?.dispose();
// // //       picture.dispose();
// // //     }
// // //     final Uint8List bytes = byteData!.buffer.asUint8List();

// // //     return BitmapDescriptor.bytes(bytes);
// // //   }

// // //   /// Creates text labels at the center of each room polygon
// // //   Future<Set<Marker>> _createRoomLabels(Map<String, dynamic> geojson) async {
// // //     final features = (geojson['features'] as List).cast<dynamic>();
// // //     final markers = <Marker>{};
// // //     int index = 0;

// // //     for (final f in features) {
// // //       final feature = f as Map<String, dynamic>;
// // //       final geometry = feature['geometry'] as Map<String, dynamic>;
// // //       final props =
// // //           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

// // //       if (geometry['type'] != 'Polygon') continue;
// // //       if (props['ref'] == null) continue;

// // //       final rings = geometry['coordinates'] as List;
// // //       if (rings.isEmpty) continue;
// // //       final outer = rings[0] as List;

// // //       final points = outer.map<LatLng>((p) {
// // //         final coords = p as List;
// // //         final lng = (coords[0] as num).toDouble();
// // //         final lat = (coords[1] as num).toDouble();
// // //         return LatLng(lat, lng);
// // //       }).toList();

// // //       if (points.length < 3) continue;

// // //       // Skip very small polygons where text won't fit
// // //       final area = _polygonArea(points);
// // //       if (area < 1e-10) continue;

// // //       final center = _polygonCenter(points);
// // //       final ref = props['ref'].toString();

// // //       // Choose font size based on polygon area
// // //       final double fontSize = area > 5e-8 ? 10 : 8;
// // //       final icon = await _createTextBitmap(ref, fontSize: fontSize);

// // //       markers.add(
// // //         Marker(
// // //           markerId: MarkerId('room-label-${index++}-$ref'),
// // //           position: center,
// // //           icon: icon,
// // //           anchor: const Offset(0.5, 0.5),
// // //           flat: true,
// // //           zIndex: 30,
// // //           consumeTapEvents: false,
// // //           infoWindow: InfoWindow.noText,
// // //         ),
// // //       );
// // //     }

// // //     return markers;
// // //   }

// // //   static const String _indoorMapStyle = '''
// // //   [
// // //     {
// // //       "featureType": "poi",
// // //       "stylers": [
// // //         { "visibility": "off" }
// // //       ]
// // //     },
// // //     {
// // //       "featureType": "poi.school",
// // //       "stylers": [
// // //         { "visibility": "off" }
// // //       ]
// // //     },
// // //     {
// // //       "featureType": "poi.business",
// // //       "stylers": [
// // //         { "visibility": "off" }
// // //       ]
// // //     },
// // //     {
// // //       "featureType": "transit",
// // //       "stylers": [
// // //         { "visibility": "off" }
// // //       ]
// // //     }
// // //   ]
// // //   ''';

// // //   @override
// // //   void dispose() {
// // //     _posSub?.cancel();
// // //     _popupDebounce?.cancel();
// // //     _debounceTimer?.cancel();
// // //     _routeDebounceTimer?.cancel();
// // //     _mapController?.dispose();
// // //     _searchController.removeListener(_onSearchChanged);
// // //     _searchController.dispose();
// // //     _originRoomController.dispose();
// // //     _destinationRoomController.dispose();
// // //     super.dispose();
// // //   }
// // // }


// // // class _ShuttleScheduleSheet extends StatelessWidget {
// // //   final String nearestStop;

// // //   const _ShuttleScheduleSheet({required this.nearestStop});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     const burgundy = Color(0xFF76263D);
// // //     final today = DateTime.now();
// // //     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
// // //     final isWeekday =
// // //         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

// // //     return DraggableScrollableSheet(
// // //       initialChildSize: 0.62,
// // //       minChildSize: 0.35,
// // //       maxChildSize: 0.92,
// // //       builder: (context, scrollController) {
// // //         return Container(
// // //           decoration: const BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
// // //           ),
// // //           child: Column(
// // //             children: [
// // //               const SizedBox(height: 10),
// // //               Container(
// // //                 height: 4,
// // //                 width: 44,
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.black.withOpacity(0.12),
// // //                   borderRadius: BorderRadius.circular(10),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 10),

// // //               Padding(
// // //                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
// // //                 child: Row(
// // //                   children: [
// // //                     const Icon(Icons.directions_bus_filled, color: burgundy),
// // //                     const SizedBox(width: 8),
// // //                     Expanded(
// // //                       child: Column(
// // //                         crossAxisAlignment: CrossAxisAlignment.start,
// // //                         children: [
// // //                           const Text(
// // //                             'Concordia Shuttle Schedule',
// // //                             style: TextStyle(
// // //                               color: burgundy,
// // //                               fontWeight: FontWeight.w800,
// // //                               fontSize: 16,
// // //                             ),
// // //                           ),
// // //                           Text(
// // //                             isWeekday
// // //                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
// // //                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
// // //                             style: const TextStyle(
// // //                               color: Colors.black54,
// // //                               fontSize: 11,
// // //                             ),
// // //                           ),
// // //                         ],
// // //                       ),
// // //                     ),
// // //                     IconButton(
// // //                       onPressed: () => Navigator.of(context).maybePop(),
// // //                       icon: const Icon(Icons.close),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),

// // //               Padding(
// // //                 padding:
// // //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// // //                 child: Row(
// // //                   children: [
// // //                     _StopChip(
// // //                         label: 'SGW  (Hall Building)', color: burgundy),
// // //                     const Padding(
// // //                       padding: EdgeInsets.symmetric(horizontal: 8),
// // //                       child: Icon(Icons.sync_alt,
// // //                           size: 16, color: Colors.black45),
// // //                     ),
// // //                     _StopChip(label: 'Loyola', color: burgundy),
// // //                   ],
// // //                 ),
// // //               ),

// // //               const Divider(height: 1),

// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   controller: scrollController,
// // //                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
// // //                   itemCount: times.length,
// // //                   itemBuilder: (context, index) {
// // //                     final t = times[index];
// // //                     final now = DateTime.now();
// // //                     final isPast = t.isBefore(now);
// // //                     final isNext = !isPast &&
// // //                         (index == 0 || times[index - 1].isBefore(now));

// // //                     return Container(
// // //                       margin: const EdgeInsets.only(bottom: 6),
// // //                       padding: const EdgeInsets.symmetric(
// // //                           horizontal: 12, vertical: 8),
// // //                       decoration: BoxDecoration(
// // //                         color: isNext
// // //                             ? burgundy.withOpacity(0.08)
// // //                             : Colors.transparent,
// // //                         border: isNext
// // //                             ? Border.all(color: burgundy.withOpacity(0.3))
// // //                             : null,
// // //                         borderRadius: BorderRadius.circular(8),
// // //                       ),
// // //                       child: Row(
// // //                         children: [
// // //                           Icon(
// // //                             Icons.directions_bus_filled,
// // //                             size: 16,
// // //                             color: isPast
// // //                                 ? Colors.black26
// // //                                 : isNext
// // //                                     ? burgundy
// // //                                     : Colors.black54,
// // //                           ),
// // //                           const SizedBox(width: 10),
// // //                           Text(
// // //                             ConcordiaShuttleService.formatTime(t),
// // //                             style: TextStyle(
// // //                               fontSize: 14,
// // //                               fontWeight: isNext
// // //                                   ? FontWeight.w700
// // //                                   : FontWeight.w400,
// // //                               color: isPast
// // //                                   ? Colors.black26
// // //                                   : isNext
// // //                                       ? burgundy
// // //                                       : Colors.black87,
// // //                             ),
// // //                           ),
// // //                           if (isNext) ...[
// // //                             const SizedBox(width: 10),
// // //                             Container(
// // //                               padding: const EdgeInsets.symmetric(
// // //                                   horizontal: 8, vertical: 2),
// // //                               decoration: BoxDecoration(
// // //                                 color: burgundy,
// // //                                 borderRadius: BorderRadius.circular(10),
// // //                               ),
// // //                               child: const Text(
// // //                                 'Next bus',
// // //                                 style: TextStyle(
// // //                                   color: Colors.white,
// // //                                   fontSize: 10,
// // //                                   fontWeight: FontWeight.w700,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ],
// // //                         ],
// // //                       ),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // class _StopChip extends StatelessWidget {
// // //   final String label;
// // //   final Color color;

// // //   const _StopChip({required this.label, required this.color});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// // //       decoration: BoxDecoration(
// // //         color: color.withOpacity(0.1),
// // //         border: Border.all(color: color.withOpacity(0.4)),
// // //         borderRadius: BorderRadius.circular(12),
// // //       ),
// // //       child: Text(
// // //         label,
// // //         style: TextStyle(
// // //           color: color,
// // //           fontSize: 12,
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }


// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:pointer_interceptor/pointer_interceptor.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // import '../../shared/widgets/map_search_bar.dart';
// // import '../building_detection.dart';
// // import '../../data/building_polygons.dart';
// // import '../../data/search_result.dart';
// // import '../../data/search_suggestion.dart';
// // import '../building_search_service.dart';
// // import '../google_places_service.dart';
// // import '../google_directions_service.dart';
// // import '../../shared/widgets/campus_toggle.dart';
// // import '../../shared/widgets/building_info_popup.dart';
// // import '../../shared/widgets/route_preview_panel.dart';
// // import '../../features/indoor/data/building_info.dart';
// // import '../../services/navigation_steps.dart';
// // import '../indoor_maps/indoor_floor_config.dart';
// // import 'package:campus_app/utils/geo.dart' as geo;
// // import '../../shared/widgets/indoor_floor_dropdown.dart';
// // import '../indoor_maps/indoor_map_controller.dart';
// // import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// // import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// // import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// // import 'package:campus_app/models/campus.dart';
// // import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// // import '../indoor_maps/indoor_map_repository.dart';
// // import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// // import '../../services/concordia_shuttle_service.dart';

// // // concordia campus coordinates
// // const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// // const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// // const double campusRadius = 500; // meters
// // const String currentLocationTag = "Current location";

// // // when camera center is within this distance auto-switch toggle
// // const double campusAutoSwitchRadius = 500; // meters
// // // knowing which campus the user is in
// // Campus detectCampus(LatLng userLocation) {
// //   final sgwDistance = Geolocator.distanceBetween(
// //     userLocation.latitude,
// //     userLocation.longitude,
// //     concordiaSGW.latitude,
// //     concordiaSGW.longitude,
// //   );

// //   final loyolaDistance = Geolocator.distanceBetween(
// //     userLocation.latitude,
// //     userLocation.longitude,
// //     concordiaLoyola.latitude,
// //     concordiaLoyola.longitude,
// //   );

// //   if (sgwDistance <= campusRadius) return Campus.sgw;
// //   if (loyolaDistance <= campusRadius) return Campus.loyola;
// //   return Campus.none;
// // }

// // class OutdoorMapPage extends StatefulWidget {
// //   final Campus initialCampus;
// //   final bool isLoggedIn;

// //   @visibleForTesting
// //   final BuildingPolygon? debugSelectedBuilding;

// //   @visibleForTesting
// //   final Offset? debugAnchorOffset;

// //   @visibleForTesting
// //   final bool debugDisableMap;

// //   @visibleForTesting
// //   final bool debugDisableLocation;

// //   @visibleForTesting
// //   final String? debugLinkOverride;

// //   const OutdoorMapPage({
// //     super.key,
// //     required this.initialCampus,
// //     this.debugSelectedBuilding,
// //     this.debugAnchorOffset,
// //     this.debugDisableMap = false,
// //     this.debugDisableLocation = false,
// //     this.debugLinkOverride,
// //     required this.isLoggedIn,
// //   });

// //   @override
// //   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// // }

// // class _OutdoorMapPageState extends State<OutdoorMapPage> {
// //   final TextEditingController _searchController = TextEditingController();
// //   final TextEditingController _originRoomController = TextEditingController();
// //   final TextEditingController _destinationRoomController = TextEditingController();
// //   bool _cameraMoving = false;
// //   List<SearchSuggestion> _searchSuggestions = [];
// //   Timer? _debounceTimer;

// //   // Indoor overlay state
// //   Set<Polygon> _indoorPolygons = {};
// //   bool _showIndoor = false;
// //   List<IndoorFloorOption> _indoorFloors = const [];
// //   String? _selectedIndoorFloorAsset;
// //   final IndoorMapController _indoorController = IndoorMapController();

// //   // --- Indoor floors state ---
// //   GoogleMapController? _mapController;

// //   LatLng? _currentLocation;
// //   BitmapDescriptor? _blueDotIcon;
// //   BuildingPolygon? _currentBuildingPoly;
// //   BuildingPolygon? _selectedBuildingPoly;
// //   // ignore: unused_field
// //   SearchResult? _selectedSearchResult;
// //   // ignore: unused_field
// //   Map<String, dynamic>? _indoorGeoJson;
// //   Set<Marker> _roomLabelMarkers = {};

// //   Set<Polyline> _routePolylines = {};

// //   // Room location marker
// //   Marker? _destinationRoomMarker;
// //   String? _currentBuildingCode;

// //   // Route preview mode
// //   bool _showRoutePreview = false;
// //   LatLng? _routeOrigin;
// //   LatLng? _routeDestination;
// //   String _routeOriginText = currentLocationTag;
// //   String _routeDestinationText = '';
// //   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
// //   final Map<String, String?> _routeDurations = {};
// //   final Map<String, String?> _routeDistances = {};
// //   final Map<String, String?> _routeArrivalTimes = {};
// //   final Map<String, List<LatLng>> _routePointsByMode = {};
// //   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
// //   String? _routeOriginBuildingCode;
// //   String? _routeDestinationBuildingCode;

// //   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
// //   // --- Navigation camera follow state ---
// //   bool _navigationFollowUser = false;
// //   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// //   static const double _navZoom = 18.0;
// //   static const double _navTilt = 60.0;
// //   static const double _defaultZoom = 15.0;
// //   static const double _defaultTilt = 0.0;
// //   static const double _defaultBearing = 0.0;
// //   // ignore: unused_field
// //   static const double _navBearingThresholdDegrees = 10.0;
// //   // ignore: unused_field
// //   static const double _navDistanceThresholdMeters = 5.0;
// //   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
// //   bool _isNavigating = false;
// //   String? _navModeKey;
// //   int _navStepIndex = 0;
// //   bool _isLoadingRouteData = false;
// //   List<SearchSuggestion> _routeOriginSuggestions = [];
// //   List<SearchSuggestion> _routeDestinationSuggestions = [];
// //   Timer? _routeDebounceTimer;

// //   // Google Directions modes only — shuttle is handled separately
// //   static const List<RouteTravelMode> _supportedTravelModes = [
// //     RouteTravelMode.driving,
// //     RouteTravelMode.walking,
// //     RouteTravelMode.bicycling,
// //     RouteTravelMode.transit,
// //   ];

// //   // Shuttle state
// //   List<ShuttleDeparture> _shuttleNextBuses = [];
// //   int? _shuttleWalkingMinutes;
// //   String _shuttleNearestStop = 'SGW';
// //   BitmapDescriptor? _shuttleStopIcon;

// //   StreamSubscription<Position>? _posSub;

// //   Timer? _popupDebounce;

// //   static const double _popupW = 300;
// //   static const double _popupH = 260;

// //   LatLng? _selectedBuildingCenter;
// //   Offset? _anchorOffset;

// //   Campus _currentCampus = Campus.none;
// //   Campus _selectedCampus = Campus.none;

// //   LatLng? _lastCameraTarget;

// //   void _clearIndoorState() {
// //     _showIndoor = false;
// //     _indoorFloors = const [];
// //     _selectedIndoorFloorAsset = null;
// //     _indoorPolygons = {};
// //     _indoorGeoJson = null;
// //     _roomLabelMarkers = {};
// //   }

// //   Campus _campusFromPoint(LatLng p) {
// //     final dSgw = Geolocator.distanceBetween(
// //       p.latitude,
// //       p.longitude,
// //       concordiaSGW.latitude,
// //       concordiaSGW.longitude,
// //     );

// //     final dLoy = Geolocator.distanceBetween(
// //       p.latitude,
// //       p.longitude,
// //       concordiaLoyola.latitude,
// //       concordiaLoyola.longitude,
// //     );

// //     final minDist = dSgw < dLoy ? dSgw : dLoy;
// //     if (minDist > campusAutoSwitchRadius) return Campus.none;

// //     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
// //   }

// //   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
// //     print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
// //   }

// //   Future<void> _syncToggleWithCameraCenter() async {
// //     if (!mounted) return;

// //     LatLng? center = _lastCameraTarget;

// //     if (center == null) {
// //       final controller = _mapController;
// //       if (controller == null) return;

// //       try {
// //         final bounds = await controller.getVisibleRegion();
// //         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
// //         final lng =
// //             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
// //         center = LatLng(lat, lng);
// //       } catch (_) {
// //         return;
// //       }
// //     }

// //     final newCampus = _campusFromPoint(center);

// //     if (newCampus == _selectedCampus) return;

// //     setState(() {
// //       _selectedCampus = newCampus;
// //     });
// //   }

// //   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
// //     return geo.pointInPolygon(point, polygon);
// //   }

// //   Future<void> _loadIndoorFloor(String assetPath) async {
// //     try {
// //       final result = await _indoorController.loadFloor(assetPath);
// //       if (!mounted) return;
// //       setState(() {
// //         _showIndoor = true;
// //         _selectedIndoorFloorAsset = assetPath;
// //         _indoorPolygons = result.polygons;
// //         _indoorGeoJson = result.geoJson;
// //         _roomLabelMarkers = result.labels;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to load indoor floor: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _toggleIndoorMap() async {
// //     // turn OFF
// //     if (_showIndoor) {
// //       setState(() {
// //         _clearIndoorState();
// //       });
// //       return;
// //     }

// //     // turn ON (needs selected building)
// //     final b = _selectedBuildingPoly;
// //     if (b == null) return;

// //     final floors = IndoorFloorConfig.floorsForBuilding(b.code);
// //     if (floors.isEmpty) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No indoor maps available for this building')),
// //       );
// //       return;
// //     }

// //     setState(() {
// //       _indoorFloors = floors;
// //       _selectedIndoorFloorAsset = floors.first.assetPath;
// //     });

// //     await _loadIndoorFloor(floors.first.assetPath);
// //   }

// //   Future<void> _goToMyLocation() async {
// //     final controller = _mapController;
// //     if (controller == null) return;

// //     var loc = _currentLocation;

// //     if (loc == null) {
// //       try {
// //         final p = await Geolocator.getCurrentPosition();
// //         loc = LatLng(p.latitude, p.longitude);
// //         if (mounted) setState(() => _currentLocation = loc);
// //       } catch (_) {
// //         return;
// //       }
// //     }

// //     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
// //   }

// //   Future<void> _openLink(String url) async {
// //     if (url.trim().isEmpty) return;

// //     final uri = Uri.tryParse(url);
// //     if (uri == null) return;

// //     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
// //     if (!ok) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
// //     }
// //   }

// //   void _schedulePopupUpdate() {
// //     _popupDebounce?.cancel();
// //     _popupDebounce = Timer(
// //       const Duration(milliseconds: 16),
// //       _updatePopupOffset,
// //     );
// //   }

// //   Future<void> _updatePopupOffset() async {
// //     final controller = _mapController;
// //     final center = _selectedBuildingCenter;
// //     if (!mounted || controller == null || center == null) return;

// //     final sc = await controller.getScreenCoordinate(center);
// //     if (!mounted) return;

// //     double x = sc.x.toDouble();
// //     double y = sc.y.toDouble();

// //     final dpr = MediaQuery.of(context).devicePixelRatio;
// //     x = x / dpr;
// //     y = y / dpr;

// //     setState(() {
// //       _anchorOffset = Offset(x, y);
// //     });
// //   }

// //   // ignore: unused_element
// //   void _selectBuildingWithoutMap(BuildingPolygon b) {
// //     final center = geo.polygonCenter(b.points);
// //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// //     _searchController.value = TextEditingValue(
// //       text: name,
// //       selection: TextSelection.collapsed(offset: name.length),
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = b;
// //       _selectedBuildingCenter = center;
// //       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
// //       _cameraMoving = false;
// //     });
// //   }

// //   void _onBuildingTapped(BuildingPolygon b) {
// //     final center = geo.polygonCenter(b.points);
// //     final controller = _mapController;
// //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// //     _searchController.value = TextEditingValue(
// //       text: name,
// //       selection: TextSelection.collapsed(offset: name.length),
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = b;
// //       _selectedBuildingCenter = center;
// //       _anchorOffset = null;
// //       _cameraMoving = true;
// //       _clearIndoorState();
// //       _roomLabelMarkers = {};
// //     });

// //     if (controller == null) return;

// //     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
// //       _,
// //     ) async {
// //       if (!mounted) return;
// //       await _updatePopupOffset();
// //       if (!mounted) return;
// //       setState(() {
// //         _cameraMoving = false;
// //       });
// //     });
// //   }

// //   void _closePopup() {
// //     _clearSelectedBuilding(clearSearch: true);
// //   }

// //   void _clearSelectedBuilding({bool clearSearch = false}) {
// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _selectedSearchResult = null;
// //       _anchorOffset = null;
// //       _routePolylines = {};
// //       _showRoutePreview = false;
// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //       _routeDurations.clear();
// //       _routeDistances.clear();
// //       _routeArrivalTimes.clear();
// //       _routePointsByMode.clear();
// //       _routeSegmentsByMode.clear();
// //       _isLoadingRouteData = false;
// //       _selectedTravelMode = RouteTravelMode.driving;
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //       _destinationRoomMarker = null;
// //       if (clearSearch) {
// //         _searchController.clear();
// //       }
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _destinationRoomMarker = null;
// //       _routeOriginBuildingCode = null;
// //       _routeDestinationBuildingCode = null;
// //       _originRoomController.clear();
// //       _destinationRoomController.clear();
// //     });
// //   }

// //   Future<void> _getDirections() async {
// //     print('[DEBUG] Get directions button clicked');
// //     print('[DEBUG] Current location: $_currentLocation');
// //     print(
// //       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
// //     );

// //     final origin = _currentLocation;
// //     final destination = _selectedBuildingPoly?.center;

// //     if (origin == null) {
// //       print('[ERROR] Cannot get directions: Current location is null');
// //       print(
// //         '[ERROR] Make sure location services are enabled and location is set in emulator',
// //       );
// //       return;
// //     }

// //     if (destination == null) {
// //       print('[ERROR] Cannot get directions: Destination is null');
// //       return;
// //     }

// //     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

// //     // Enter route preview mode
// //     setState(() {
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _showRoutePreview = true;
// //       _routeOrigin = origin;
// //       _routeDestination = destination;
// //       _routeOriginText = currentLocationTag;
// //       _routeDestinationText =
// //           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
// //       _routeOriginBuildingCode = currentBuildingCode;
// //       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
// //       print(
// //         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
// //       );
// //     });

// //     await _fetchRoutesAndDurations();
// //   }

// //   Future<void> _fetchRoutesAndDurations() async {
// //     final origin = _routeOrigin;
// //     final destination = _routeDestination;

// //     if (origin == null || destination == null) {
// //       print('[ERROR] Cannot fetch route: origin or destination is null');
// //       return;
// //     }

// //     print(
// //       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
// //     );

// //     setState(() {
// //       _isLoadingRouteData = true;
// //     });

// //     try {
// //       final futures = _supportedTravelModes.map(
// //         (mode) => GoogleDirectionsService.instance.getRouteDetails(
// //           origin: origin,
// //           destination: destination,
// //           mode: mode.apiValue,
// //         ),
// //       );

// //       final results = await Future.wait(futures);
// //       final durations = <String, String?>{};
// //       final distances = <String, String?>{};
// //       final arrivalTimes = <String, String?>{};
// //       final pointsByMode = <String, List<LatLng>>{};
// //       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
// //       final stepsByMode = <String, List<NavigationStep>>{};

// //       for (var i = 0; i < _supportedTravelModes.length; i++) {
// //         final mode = _supportedTravelModes[i].apiValue;
// //         final route = results[i];
// //         durations[mode] = route?.durationText;
// //         distances[mode] = route?.distanceText;
// //         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
// //         stepsByMode[mode] = route?.steps ?? const [];
// //         if (route != null && route.points.isNotEmpty) {
// //           pointsByMode[mode] = route.points;
// //         }
// //         if (route != null && route.transitSegments.isNotEmpty) {
// //           segmentsByMode[mode] = route.transitSegments;
// //         }
// //       }

// //       if (!mounted) return;

// //       setState(() {
// //         _routeDurations
// //           ..clear()
// //           ..addAll(durations);
// //         _routeDistances
// //           ..clear()
// //           ..addAll(distances);
// //         _routeArrivalTimes
// //           ..clear()
// //           ..addAll(arrivalTimes);
// //         _routePointsByMode
// //           ..clear()
// //           ..addAll(pointsByMode);
// //         _routeSegmentsByMode
// //           ..clear()
// //           ..addAll(segmentsByMode);
// //         _routeStepsByMode
// //           ..clear()
// //           ..addAll(stepsByMode);

// //         _isLoadingRouteData = false;
// //       });

// //       _applySelectedModeRoute(animateCamera: true);

// //       _fetchShuttleInfo();
// //     } catch (e) {
// //       print('Error getting directions: $e');
// //       if (!mounted) return;
// //       setState(() {
// //         _isLoadingRouteData = false;
// //       });
// //     }
// //   }

// //   void _openStepsForSelectedMode() {
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// //       _showShuttleScheduleModal();
// //       return;
// //     }

// //     final key = _selectedTravelMode.apiValue;
// //     final steps = _routeStepsByMode[key] ?? const [];

// //     showNavigationStepsModal(
// //       context,
// //       title: _selectedTravelMode.label,
// //       steps: steps,
// //       totalDuration: _routeDurations[key],
// //       totalDistance: _routeDistances[key],
// //     );
// //   }

// //   void _applySelectedModeRoute({required bool animateCamera}) {
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

// //     final selectedModeKey = _selectedTravelMode.apiValue;
// //     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
// //     if (_selectedTravelMode == RouteTravelMode.transit &&
// //         selectedSegments != null &&
// //         selectedSegments.isNotEmpty) {
// //       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
// //       return;
// //     }

// //     final selectedPoints = _routePointsByMode[selectedModeKey];

// //     if (selectedPoints == null || selectedPoints.isEmpty) {
// //       setState(() {
// //         _routePolylines = {};
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routePolylines = {
// //         Polyline(
// //           polylineId: const PolylineId('route'),
// //           points: selectedPoints,
// //           color: const Color(0xFF76263D),
// //           width: 5,
// //           patterns: _selectedTravelMode == RouteTravelMode.driving
// //               ? const []
// //               : [PatternItem.dot, PatternItem.gap(10)],
// //         ),
// //       };
// //     });

// //     if (!animateCamera || _mapController == null) return;
// //     final bounds = geo.calculateBounds(selectedPoints);
// //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //   }

// //   void _applyTransitSegments(
// //     List<DirectionsRouteSegment> segments, {
// //     required bool animateCamera,
// //   }) {
// //     final polylines = <Polyline>{};
// //     final allPoints = <LatLng>[];

// //     for (var i = 0; i < segments.length; i++) {
// //       final segment = segments[i];
// //       if (segment.points.isEmpty) {
// //         continue;
// //       }

// //       allPoints.addAll(segment.points);

// //       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
// //       polylines.add(
// //         Polyline(
// //           polylineId: PolylineId('route_segment_$i'),
// //           points: segment.points,
// //           color: _resolveTransitSegmentColor(segment),
// //           width: 5,
// //           patterns: isWalking
// //               ? [PatternItem.dot, PatternItem.gap(10)]
// //               : const [],
// //         ),
// //       );
// //     }

// //     if (polylines.isEmpty) {
// //       setState(() {
// //         _routePolylines = {};
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routePolylines = polylines;
// //     });

// //     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
// //       return;
// //     }

// //     final bounds = geo.calculateBounds(allPoints);
// //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //   }

// //   void _startNavigation() {
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text(
// //             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
// //           ),
// //           duration: Duration(seconds: 3),
// //         ),
// //       );
// //       return;
// //     }

// //     final key = _selectedTravelMode.apiValue;
// //     final steps = _routeStepsByMode[key] ?? const [];

// //     if (steps.isEmpty) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No steps available for this route')),
// //         );
// //       }
// //       return;
// //     }

// //     setState(() {
// //       _isNavigating = true;
// //       _navModeKey = key;
// //       _navStepIndex = 0;

// //       _navigationFollowUser = true;
// //       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// //     });

// //     if (_currentLocation != null && _mapController != null) {
// //       try {
// //         final currentPos = _currentLocation!;
// //         final initialCam = CameraPosition(
// //           target: currentPos,
// //           zoom: _navZoom,
// //           tilt: _navTilt,
// //           bearing: 0.0,
// //         );
// //         _mapController!.animateCamera(
// //           CameraUpdate.newCameraPosition(initialCam),
// //         );
// //       } catch (e) {
// //         print('Error animating camera when starting navigation: $e');
// //       }
// //     }
// //   }

// //   void _stopNavigation() {
// //     setState(() {
// //       _isNavigating = false;
// //       _navModeKey = null;
// //       _navStepIndex = 0;
// //       _navigationFollowUser = false;
// //     });
// //     if (_mapController != null && _currentLocation != null) {
// //       try {
// //         final cam = CameraPosition(
// //           target: _currentLocation!,
// //           zoom: _defaultZoom,
// //           tilt: _defaultTilt,
// //           bearing: _defaultBearing,
// //         );

// //         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// //       } catch (e) {
// //         print('Error resetting camera after navigation: $e');
// //       }
// //     }

// //     _closeRoutePreview();
// //   }

// //   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
// //     if (_mapController == null) return;
// //     if (!_navigationFollowUser) return;

// //     final now = DateTime.now();

// //     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
// //       return;
// //     }

// //     double bearing = 0.0;
// //     if (heading != null && heading >= 0.0) {
// //       bearing = heading;
// //     }

// //     final cam = CameraPosition(
// //       target: userLatLng,
// //       zoom: _navZoom,
// //       tilt: _navTilt,
// //       bearing: bearing,
// //     );

// //     try {
// //       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// //     } catch (e) {
// //       print('Error animating navigation camera: $e');
// //     }
// //   }

// //   void _maybeAdvanceNavigationStep(LatLng user) {
// //     final key = _navModeKey;
// //     if (key == null) return;

// //     final steps = _routeStepsByMode[key] ?? const [];
// //     if (steps.isEmpty) return;

// //     if (_navStepIndex >= steps.length - 1) return;

// //     final current = steps[_navStepIndex];
// //     final end = current.endPoint;
// //     if (end == null) return;

// //     final d = Geolocator.distanceBetween(
// //       user.latitude,
// //       user.longitude,
// //       end.latitude,
// //       end.longitude,
// //     );

// //     if (d <= 20) {
// //       setState(() => _navStepIndex += 1);
// //     }
// //   }

// //   void _closeRoutePreview() {
// //     setState(() {
// //       _showRoutePreview = false;
// //       _routePolylines = {};
// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //       _routeDurations.clear();
// //       _routeDistances.clear();
// //       _routeArrivalTimes.clear();
// //       _routePointsByMode.clear();
// //       _routeSegmentsByMode.clear();
// //       _isLoadingRouteData = false;
// //       _selectedTravelMode = RouteTravelMode.driving;
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //       _searchController.clear();

// //       //reset indoor map and building selection state
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _destinationRoomMarker = null;
// //       _originRoomController.clear();
// //       _destinationRoomController.clear();
// //       _routeOriginBuildingCode = null;
// //       _routeDestinationBuildingCode = null;
// //     });
// //   }

// //   String? _formatArrivalTime(int? durationSeconds) {
// //     if (durationSeconds == null) {
// //       return null;
// //     }

// //     final now = DateTime.now();
// //     final arrival = now.add(Duration(seconds: durationSeconds));
// //     int hour = arrival.hour;
// //     final minute = arrival.minute.toString().padLeft(2, '0');
// //     final isPm = hour >= 12;
// //     final period = isPm ? 'pm' : 'am';
// //     hour = hour % 12;
// //     if (hour == 0) {
// //       hour = 12;
// //     }
// //     return '$hour:$minute $period';
// //   }

// //   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
// //     const defaultRed = Color(0xFF76263D);
// //     final mode = segment.travelMode.toUpperCase();
// //     if (mode == 'WALKING') {
// //       return defaultRed;
// //     }

// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     if (vehicleType == 'BUS') {
// //       return Colors.blue;
// //     }

// //     final lineColor = parseHexColor(segment.transitLineColorHex);
// //     if (lineColor != null) {
// //       return lineColor;
// //     }

// //     return defaultRed;
// //   }

// //   List<TransitDetailItem> _buildTransitDetailItems() {
// //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// //     final items = <TransitDetailItem>[];

// //     for (final segment in segments) {
// //       if (segment.points.isEmpty) {
// //         continue;
// //       }

// //       final travelMode = segment.travelMode.toUpperCase();
// //       if (travelMode == 'WALKING') {
// //         continue;
// //       }

// //       final vehicleType = segment.transitVehicleType?.toUpperCase();
// //       final lineLabel =
// //           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
// //       final color = _resolveTransitSegmentColor(segment);

// //       IconData icon = Icons.directions_transit;
// //       String title = 'Transit $lineLabel';

// //       if (vehicleType == 'BUS') {
// //         icon = Icons.directions_bus;
// //         title = 'Bus $lineLabel';
// //       } else if (vehicleType == 'SUBWAY' ||
// //           vehicleType == 'METRO_RAIL' ||
// //           vehicleType == 'HEAVY_RAIL' ||
// //           vehicleType == 'COMMUTER_TRAIN' ||
// //           vehicleType == 'RAIL' ||
// //           vehicleType == 'TRAM' ||
// //           vehicleType == 'LIGHT_RAIL' ||
// //           vehicleType == 'MONORAIL') {
// //         icon = Icons.directions_subway;
// //         title = 'Metro $lineLabel';
// //       }

// //       items.add(TransitDetailItem(icon: icon, color: color, title: title));
// //     }

// //     return items;
// //   }

// //   // ignore: unused_element
// //   List<DirectionsRouteSegment> _getTransitDetailSegments() {
// //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// //     return segments
// //         .where(
// //           (segment) =>
// //               segment.travelMode.toUpperCase() == 'TRANSIT' &&
// //               segment.points.isNotEmpty,
// //         )
// //         .toList();
// //   }

// //   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     final lineLabel =
// //         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

// //     if (vehicleType == 'BUS') {
// //       return 'Bus $lineLabel';
// //     }

// //     if (vehicleType == 'SUBWAY' ||
// //         vehicleType == 'METRO_RAIL' ||
// //         vehicleType == 'HEAVY_RAIL' ||
// //         vehicleType == 'COMMUTER_TRAIN' ||
// //         vehicleType == 'RAIL' ||
// //         vehicleType == 'TRAM' ||
// //         vehicleType == 'LIGHT_RAIL' ||
// //         vehicleType == 'MONORAIL') {
// //       return 'Metro $lineLabel';
// //     }

// //     return 'Transit $lineLabel';
// //   }

// //   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     if (vehicleType == 'BUS') {
// //       return Icons.directions_bus;
// //     }
// //     if (vehicleType == 'SUBWAY' ||
// //         vehicleType == 'METRO_RAIL' ||
// //         vehicleType == 'HEAVY_RAIL' ||
// //         vehicleType == 'COMMUTER_TRAIN' ||
// //         vehicleType == 'RAIL' ||
// //         vehicleType == 'TRAM' ||
// //         vehicleType == 'LIGHT_RAIL' ||
// //         vehicleType == 'MONORAIL') {
// //       return Icons.directions_subway;
// //     }
// //     return Icons.directions_transit;
// //   }

// //   // ignore: unused_element
// //   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
// //     const burgundy = Color(0xFF76263D);

// //     return Container(
// //       width: 340,
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.15),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Text(
// //             'Transit details',
// //             style: TextStyle(
// //               fontSize: 12,
// //               fontWeight: FontWeight.w600,
// //               color: burgundy,
// //             ),
// //           ),
// //           const SizedBox(height: 6),
// //           for (final segment in segments)
// //             Padding(
// //               padding: const EdgeInsets.only(bottom: 6),
// //               child: Row(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Icon(
// //                     _transitSegmentIcon(segment),
// //                     size: 16,
// //                     color: _resolveTransitSegmentColor(segment),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           _formatTransitSegmentTitle(segment),
// //                           style: const TextStyle(
// //                             fontSize: 12,
// //                             fontWeight: FontWeight.w600,
// //                             color: Colors.black87,
// //                           ),
// //                         ),
// //                         if (segment.transitHeadsign != null &&
// //                             segment.transitHeadsign!.trim().isNotEmpty)
// //                           Text(
// //                             segment.transitHeadsign!,
// //                             style: const TextStyle(
// //                               fontSize: 11,
// //                               color: Colors.black54,
// //                             ),
// //                           ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Color? parseHexColor(String? hex) {
// //     if (hex == null || hex.trim().isEmpty) {
// //       return null;
// //     }

// //     final normalized = hex.trim().replaceFirst('#', '');
// //     if (normalized.length != 6) {
// //       return null;
// //     }

// //     final value = int.tryParse(normalized, radix: 16);
// //     if (value == null) {
// //       return null;
// //     }

// //     return Color(0xFF000000 | value);
// //   }

// //   void _switchOriginDestination() {
// //     setState(() {
// //       final tempOrigin = _routeOriginText;
// //       final tempOriginLatLng = _routeOrigin;
// //       final tempDestination = _routeDestinationText;
// //       final tempDestinationLatLng = _routeDestination;

// //       _routeOriginText = tempDestination;
// //       _routeOrigin = tempDestinationLatLng;
// //       _routeDestinationText = tempOrigin;
// //       _routeDestination = tempOriginLatLng;

// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //     });

// //     _fetchRoutesAndDurations();
// //   }

// //   void _onTravelModeSelected(RouteTravelMode mode) {
// //     setState(() {
// //       _selectedTravelMode = mode;
// //     });

// //     if (mode == RouteTravelMode.shuttle) {
// //       _fetchShuttleInfo();
// //       return;
// //     }

// //     if (_routePointsByMode.containsKey(mode.apiValue)) {
// //       _applySelectedModeRoute(animateCamera: false);
// //       return;
// //     }

// //     _fetchRoutesAndDurations();
// //   }

// //   /// Shuttle stop marker icon
// //   Future<void> _createShuttleStopIcon() async {
// //     _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
// //       const ImageConfiguration(size: Size(600, 600)),
// //       'assets/images/shuttle_icon.png',
// //     );
// //   }

// //   /// Walking time + 4 next buses
// //   Future<void> _fetchShuttleInfo() async {
// //     final origin = _routeOrigin ?? _currentLocation;

// //     if (origin == null) {
// //       setState(() {
// //         _routeDurations['shuttle'] = '–';
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //     });

// //     try {
// //       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
// //       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

// //       int walkingSeconds = 0;
// //       List<LatLng> walkPoints = [];

// //       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
// //         origin: origin,
// //         destination: stopLatLng,
// //         mode: 'walking',
// //       );

// //       if (walkRoute != null) {
// //         walkingSeconds = walkRoute.durationSeconds ?? 0;
// //         walkPoints = walkRoute.points;
// //       }

// //       final walkingMinutes = (walkingSeconds / 60).ceil();

// //       final buses = ConcordiaShuttleService.getNextDepartures(
// //         fromStop: nearestStop,
// //         now: DateTime.now(),
// //         count: 4,
// //         walkingDuration: Duration(seconds: walkingSeconds),
// //       );

// //       String shuttleDurationLabel;
// //       if (!ConcordiaShuttleService.isInService()) {
// //         shuttleDurationLabel = 'No service';
// //       } else if (buses.isNotEmpty) {
// //         shuttleDurationLabel = buses.first.statusLabel;
// //       } else {
// //         shuttleDurationLabel = '–';
// //       }

// //       if (walkPoints.isNotEmpty) {
// //         setState(() {
// //           _routePolylines = {
// //             Polyline(
// //               polylineId: const PolylineId('shuttle_walk'),
// //               points: walkPoints,
// //               color: const Color(0xFF76263D),
// //               width: 5,
// //               patterns: [PatternItem.dot, PatternItem.gap(10)],
// //             ),
// //           };
// //         });

// //         if (_mapController != null) {
// //           final bounds = geo.calculateBounds([...walkPoints, stopLatLng]);
// //           _mapController!
// //               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //         }
// //       } else {
// //         setState(() {
// //           _routePolylines = {};
// //         });
// //       }

// //       if (!mounted) return;
// //       setState(() {
// //         _shuttleNearestStop = nearestStop;
// //         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
// //         _shuttleNextBuses = buses;
// //         _routeDurations['shuttle'] = shuttleDurationLabel;
// //       });
// //     } catch (e) {
// //       print('Error fetching shuttle info: $e');
// //       if (!mounted) return;
// //       setState(() {
// //         _routeDurations['shuttle'] = '–';
// //       });
// //     }
// //   }

// //   /// Open full day schedule
// //   void _showShuttleScheduleModal() {
// //     showModalBottomSheet<void>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) =>
// //           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
// //     );
// //   }

// //   Future<void> _onRouteOriginChanged(String query) async {
// //     if (query.trim().isEmpty) {
// //       setState(() {
// //         _routeOriginSuggestions = [];
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routeOriginSuggestions = [];
// //     });

// //     _routeDebounceTimer?.cancel();
// //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       try {
// //         print('[DEBUG] Searching for origin: $query');
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         print('[DEBUG] Found ${suggestions.length} origin suggestions');
// //         if (mounted) {
// //           setState(() {
// //             _routeOriginSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error getting origin suggestions: $e');
// //       }
// //     });
// //   }

// //   Future<void> _onRouteDestinationChanged(String query) async {
// //     if (query.trim().isEmpty) {
// //       setState(() {
// //         _routeDestinationSuggestions = [];
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routeDestinationSuggestions = [];
// //     });

// //     _routeDebounceTimer?.cancel();
// //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       try {
// //         print('[DEBUG] Searching for destination: $query');
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         print('[DEBUG] Found ${suggestions.length} destination suggestions');
// //         if (mounted) {
// //           setState(() {
// //             _routeDestinationSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error getting destination suggestions: $e');
// //       }
// //     });
// //   }

// //   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
// //     print(
// //       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
// //     );
// //     LatLng? newOrigin;
// //     String displayText = suggestion.name;
// //     String? buildingCode;

// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       print('[DEBUG] Handling Concordia building');
// //       final building = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       newOrigin = building?.center;
// //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// //       buildingCode = suggestion.buildingName!.code;
// //       print('[DEBUG] Concordia building origin: $newOrigin');
// //     } else if (suggestion.placeId != null) {
// //       print(
// //         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
// //       );
// //       try {
// //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //           suggestion.placeId!,
// //         );
// //         print('[DEBUG] Place details result: $placeDetails');
// //         if (placeDetails != null) {
// //           newOrigin = placeDetails.location;
// //           buildingCode = null;
// //           print('[DEBUG] Non-Concordia origin location: $newOrigin');
// //         } else {
// //           print(
// //             '[ERROR] Place details returned null for ${suggestion.placeId}',
// //           );
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error fetching place details: $e');
// //         return;
// //       }
// //     }

// //     if (newOrigin != null) {
// //       print('[DEBUG] Updating route origin state');
// //       print('[DEBUG] New origin building code: $buildingCode');
// //       setState(() {
// //         _routeOrigin = newOrigin;
// //         _routeOriginText = displayText;
// //         _routeOriginSuggestions = [];
// //         _routeOriginBuildingCode = buildingCode;
// //         _originRoomController.clear();
// //       });
// //       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
// //       await _fetchRoutesAndDurations();
// //     } else {
// //       print('[ERROR] Could not determine origin location');
// //     }
// //   }

// //   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
// //     LatLng? newDestination;
// //     String displayText = suggestion.name;
// //     String? buildingCode;

// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       final building = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       newDestination = building?.center;
// //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// //       buildingCode = suggestion.buildingName!.code;
// //     } else if (suggestion.placeId != null) {
// //       try {
// //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //           suggestion.placeId!,
// //         );
// //         if (placeDetails != null) {
// //           newDestination = placeDetails.location;
// //           buildingCode = null;
// //         }
// //       } catch (e) {
// //         print('Error fetching place details: $e');
// //         return;
// //       }
// //     }

// //     if (newDestination != null) {
// //       print('[DEBUG] Updating route destination state');
// //       print('[DEBUG] New destination building code: $buildingCode');
// //       setState(() {
// //         _routeDestination = newDestination;
// //         _routeDestinationText = displayText;
// //         _routeDestinationSuggestions = [];
// //         _routeDestinationBuildingCode = buildingCode;
// //         _destinationRoomController.clear();
// //       });
// //       await _fetchRoutesAndDurations();
// //     }
// //   }

// //   void _hideBuildingPopup() {
// //     if (_selectedBuildingPoly == null) return;

// //     _clearSelectedBuilding();
// //   }

// //   Future<void> _onSearchSubmitted(String query) async {
// //     if (query.trim().isEmpty) return;

// //     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

// //     if (concordiaBuilding != null) {
// //       _onBuildingTapped(concordiaBuilding);
// //       return;
// //     }

// //     final results = await BuildingSearchService.searchWithGooglePlaces(
// //       query,
// //       userLocation: _currentLocation,
// //     );

// //     if (results.isNotEmpty) {
// //       SearchResult? selectedResult;

// //       for (final result in results) {
// //         if (!result.isConcordiaBuilding) {
// //           selectedResult = result;
// //           break;
// //         }
// //       }

// //       if (selectedResult == null && results.isNotEmpty) {
// //         selectedResult = results.first;
// //       }

// //       if (selectedResult != null) {
// //         if (selectedResult.isConcordiaBuilding &&
// //             selectedResult.buildingPolygon != null) {
// //           _onBuildingTapped(selectedResult.buildingPolygon!);
// //         } else {
// //           _onPlaceSelected(selectedResult);
// //         }
// //       }
// //     } else {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('"$query" not found'),
// //           duration: const Duration(seconds: 2),
// //           backgroundColor: const Color(0xFF800020),
// //         ),
// //       );
// //       _searchController.clear();
// //     }
// //   }

// //   void _onPlaceSelected(SearchResult result) {
// //     final controller = _mapController;
// //     if (controller == null) return;

// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _selectedSearchResult = result;
// //     });

// //     _searchController.value = TextEditingValue(
// //       text: result.name,
// //       selection: TextSelection.collapsed(offset: result.name.length),
// //     );

// //     if (result.isConcordiaBuilding) {
// //       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('${result.name} is a Concordia building'),
// //           duration: const Duration(seconds: 3),
// //           backgroundColor: const Color(0xFF800020),
// //         ),
// //       );
// //     } else {
// //       if (_currentLocation == null) {
// //         controller.animateCamera(
// //           CameraUpdate.newLatLngZoom(result.location, 18),
// //         );
// //         if (!mounted) return;
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('${result.name} is not a Concordia building'),
// //             duration: const Duration(seconds: 2),
// //             backgroundColor: Colors.grey[700],
// //           ),
// //         );
// //       } else {
// //         _enterRoutePreviewForPlace(result);
// //       }
// //     }
// //   }

// //   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
// //     if (_currentLocation == null) return;

// //     print(
// //       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _showRoutePreview = true;
// //       _routeOrigin = _currentLocation;
// //       _routeDestination = place.location;
// //       _routeOriginText = currentLocationTag;
// //       _routeDestinationText = place.name;
// //       _selectedSearchResult = place;
// //     });

// //     print(
// //       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
// //     );

// //     await _fetchRoutesAndDurations();
// //   }

// //   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       final buildingPolygon = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       if (buildingPolygon == null) return;
// //       _onBuildingTapped(buildingPolygon);
// //     } else if (suggestion.placeId != null) {
// //       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //         suggestion.placeId!,
// //       );
// //       if (placeDetails != null) {
// //         final concordiaBuilding = BuildingSearchService.searchBuilding(
// //           suggestion.name,
// //         );

// //         if (concordiaBuilding != null) {
// //           _onBuildingTapped(concordiaBuilding);
// //         } else {
// //           final searchResult = SearchResult.fromGooglePlace(
// //             name: placeDetails.name,
// //             address: placeDetails.formattedAddress,
// //             location: placeDetails.location,
// //             isConcordiaBuilding: false,
// //             placeId: placeDetails.placeId,
// //           );
// //           _onPlaceSelected(searchResult);
// //         }
// //       }
// //     }
// //   }

// //   Set<Polygon> _createBuildingPolygons() {
// //     const burgundy = Color(0xFF800020);
// //     const selectedBlue = Color(0xFF7F83C3);

// //     final polys = <Polygon>{};

// //     for (final b in buildingPolygons) {
// //       final isCurrent = _currentBuildingPoly?.code == b.code;
// //       final isSelected = _selectedBuildingPoly?.code == b.code;

// //       final strokeColor = isSelected
// //           ? selectedBlue.withOpacity(0.95)
// //           : isCurrent
// //           ? Colors.blue.withOpacity(0.8)
// //           : burgundy.withOpacity(0.55);

// //       final fillColor = isSelected
// //           ? selectedBlue.withOpacity(0.25)
// //           : isCurrent
// //           ? Colors.blue.withOpacity(0.25)
// //           : burgundy.withOpacity(0.22);

// //       final strokeWidth = isSelected
// //           ? 3
// //           : isCurrent
// //           ? 3
// //           : 2;
// //       final zIndex = isSelected
// //           ? 3
// //           : isCurrent
// //           ? 2
// //           : 1;

// //       polys.add(
// //         Polygon(
// //           polygonId: PolygonId('poly_${b.code}'),
// //           points: b.points,
// //           strokeWidth: strokeWidth,
// //           strokeColor: strokeColor,
// //           fillColor: fillColor,
// //           zIndex: zIndex,
// //           consumeTapEvents: true,
// //           onTap: () => _onBuildingTapped(b),
// //         ),
// //       );
// //     }

// //     return polys;
// //   }

// //   List<Widget> _createBuildingGestureDetectors() {
// //     final detectors = <Widget>[];

// //     for (final building in buildingPolygons) {
// //       detectors.add(
// //         Positioned(
// //           left: 0,
// //           top: 0,
// //           child: GestureDetector(
// //             key: Key('building_detector_${building.code}'),
// //             onTap: () => _onBuildingTapped(building),
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               color: Colors.transparent,
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     return detectors;
// //   }

// //   @override
// //   void initState() {
// //     super.initState();

// //     _selectedCampus = widget.initialCampus;

// //     _lastCameraTarget = widget.initialCampus == Campus.loyola
// //         ? concordiaLoyola
// //         : concordiaSGW;

// //     _createBlueDotIcon();
// //     _createShuttleStopIcon();
// //     _determineUserLocationAndBuilding().then((_) {
// //       _startLocationUpdates();
// //     });

// //     _searchController.addListener(_onSearchChanged);
// //     // Clear destination room marker when room input changes
// //     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
// //     _determineUserLocationAndBuilding();
// //   }

// //   Future<void> _determineUserLocationAndBuilding() async {
// //     final position = await Geolocator.getCurrentPosition();
// //     _currentLocation = LatLng(position.latitude, position.longitude);

// //     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

// //     setState(() {
// //       _currentBuildingCode = buildingAtLocation?.code;
// //     });
// //   }

// //   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
// //     for (final building in buildingPolygons) {
// //       if (_isPointInPolygon(location, building.points)) {
// //         return building;
// //       }
// //     }
// //     return null;
// //   }

// //   void _onDestinationRoomTextChanged() {
// //     if (_destinationRoomMarker == null) return;

// //     setState(() {
// //       _destinationRoomMarker = null;
// //     });
// //   }

// //   void _onSearchChanged() {
// //     _debounceTimer?.cancel();

// //     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       final query = _searchController.text;
// //       try {
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         if (mounted) {
// //           setState(() {
// //             _searchSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('Error getting search suggestions: $e');
// //         if (mounted) {
// //           setState(() {
// //             _searchSuggestions = BuildingSearchService.getSuggestions(
// //               query,
// //             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
// //           });
// //         }
// //       }
// //     });
// //   }

// //   Future<void> _createBlueDotIcon() async {
// //     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
// //       BitmapDescriptor.hueAzure,
// //     );
// //   }

// //   Future<void> _startLocationUpdates() async {
// //     print('[DEBUG] Starting location updates...');

// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     print('[DEBUG] Location service enabled: $serviceEnabled');

// //     if (!serviceEnabled) {
// //       print('[ERROR] Location services are disabled');
// //       return;
// //     }

// //     LocationPermission permission = await Geolocator.checkPermission();
// //     print('[DEBUG] Initial permission status: $permission');

// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       print('[DEBUG] Permission after request: $permission');
// //       if (permission == LocationPermission.denied) {
// //         print('[ERROR] Location permission denied by user');
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       print('[ERROR] Location permission denied forever');
// //       return;
// //     }

// //     try {
// //       print('[DEBUG] Attempting to get current position...');
// //       final position = await Geolocator.getCurrentPosition(
// //         locationSettings: const LocationSettings(
// //           accuracy: LocationAccuracy.high,
// //           timeLimit: Duration(seconds: 10),
// //         ),
// //       );
// //       final newLatLng = LatLng(position.latitude, position.longitude);

// //       print(
// //         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
// //       );
// //       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

// //       if (!mounted) return;
// //       setState(() {
// //         _currentLocation = newLatLng;
// //         _currentCampus = detectCampus(newLatLng);
// //         _currentBuildingPoly = detectBuildingPoly(newLatLng);
// //       });

// //       print('[DEBUG] Current campus: $_currentCampus');
// //       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

// //       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
// //     } catch (e) {
// //       print('[ERROR] Failed to get current position: $e');
// //       print(
// //         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
// //       );
// //     }

// //     _posSub =
// //         Geolocator.getPositionStream(
// //           locationSettings: const LocationSettings(
// //             accuracy: LocationAccuracy.best,
// //             distanceFilter: 5,
// //           ),
// //         ).listen((position) {
// //           final newLatLng = LatLng(position.latitude, position.longitude);
// //           print(
// //             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
// //           );

// //           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

// //           if (!mounted) return;
// //           setState(() {
// //             _currentLocation = newLatLng;
// //             _currentCampus = detectCampus(newLatLng);
// //             _currentBuildingPoly = detectBuildingPoly(newLatLng);
// //             _currentBuildingCode = buildingAtLocation?.code;
// //           });

// //           if (_isNavigating) {
// //             _maybeAdvanceNavigationStep(newLatLng);
// //           }
// //           if (_navigationFollowUser) {
// //             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
// //           }
// //         });
// //   }

// //   Set<Marker> _createMarkers() {
// //     final markers = <Marker>{};
// //     // Add current location marker
// //     if (_currentLocation != null) {
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('current_location'),
// //           position: _currentLocation!,
// //           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
// //           anchor: const Offset(0.5, 0.5),
// //           flat: true,
// //           zIndex: 999,
// //         ),
// //       );
// //     }

// //     // Shuttle stop markers
// //     final shuttleIcon = _shuttleStopIcon;
// //     if (shuttleIcon != null) {
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('shuttle_stop_sgw'),
// //           position: shuttleStopSGW,
// //           icon: shuttleIcon,
// //           infoWindow: const InfoWindow(
// //             title: 'Concordia Shuttle — SGW',
// //             snippet: 'Hall Building stop',
// //           ),
// //           onTap: () {
// //             if (_showRoutePreview) {
// //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// //               _fetchShuttleInfo();
// //             }
// //           },
// //         ),
// //       );
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('shuttle_stop_loyola'),
// //           position: shuttleStopLoyola,
// //           icon: shuttleIcon,
// //           infoWindow: const InfoWindow(
// //             title: 'Concordia Shuttle — Loyola',
// //             snippet: 'Loyola campus stop',
// //           ),
// //           onTap: () {
// //             if (_showRoutePreview) {
// //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// //               _fetchShuttleInfo();
// //             }
// //           },
// //         ),
// //       );
// //     }

// //     // Add destination room marker only when indoor map is shown
// //     if (_destinationRoomMarker != null && _showIndoor) {
// //       markers.add(_destinationRoomMarker!);
// //     }

// //     if (_showRoutePreview) {
// //       if (_routeDestination != null) {
// //         markers.add(
// //           Marker(
// //             markerId: const MarkerId('route_destination'),
// //             position: _routeDestination!,
// //             infoWindow: InfoWindow(title: _routeDestinationText),
// //             icon: BitmapDescriptor.defaultMarkerWithHue(
// //               BitmapDescriptor.hueRed,
// //             ),
// //           ),
// //         );
// //       }
// //     }

// //     return markers;
// //   }

// //   Set<Circle> _createCircles() {
// //     final circles = <Circle>{};

// //     if (_currentLocation == null) return {};

// //     circles.add(
// //       Circle(
// //         circleId: const CircleId('current_location_accuracy'),
// //         center: _currentLocation!,
// //         radius: 20,
// //         fillColor: Colors.blue.withOpacity(0.1),
// //         strokeColor: Colors.blue.withOpacity(0.3),
// //         strokeWidth: 1,
// //       ),
// //     );

// //     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
// //       final segments = _routeSegmentsByMode['transit'] ?? const [];
// //       final seen = <String>{};

// //       for (final segment in segments) {
// //         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
// //           continue;
// //         }
// //         if (segment.points.isEmpty) {
// //           continue;
// //         }

// //         final endpoints = [segment.points.first, segment.points.last];
// //         for (final point in endpoints) {
// //           final key =
// //               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
// //           if (!seen.add(key)) {
// //             continue;
// //           }

// //           circles.add(
// //             Circle(
// //               circleId: CircleId('transit_stop_$key'),
// //               center: point,
// //               radius: 15,
// //               fillColor: Colors.white,
// //               strokeColor: const Color(0xFF76263D),
// //               strokeWidth: 2,
// //             ),
// //           );
// //         }
// //       }
// //     }

// //     return circles;
// //   }

// //   NavigationStep? _getCurrentNavStep() {
// //     final key = _navModeKey;
// //     if (key == null) return null;

// //     final steps = _routeStepsByMode[key] ?? const [];
// //     if (steps.isEmpty) return null;

// //     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
// //     return steps[_navStepIndex];
// //   }

// //   void _switchCampus(Campus newCampus) {
// //     LatLng targetLocation;

// //     switch (newCampus) {
// //       case Campus.sgw:
// //         targetLocation = concordiaSGW;
// //         break;
// //       case Campus.loyola:
// //         targetLocation = concordiaLoyola;
// //         break;
// //       case Campus.none:
// //         return;
// //     }

// //     _lastCameraTarget = targetLocation;
// //     _mapController?.animateCamera(
// //       CameraUpdate.newLatLngZoom(targetLocation, 16),
// //     );

// //     setState(() {
// //       _selectedCampus = newCampus;
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _cameraMoving = false;
// //       _searchController.clear();
// //     });
// //   }

// //   Offset? _computePopupPosition(BuildContext context) {
// //     final screen = MediaQuery.of(context).size;
// //     final topPad = MediaQuery.of(context).padding.top;

// //     final anchor = widget.debugAnchorOffset ?? _anchorOffset;
// //     if (anchor == null || _cameraMoving) return null;

// //     final ax = anchor.dx;
// //     final ay = anchor.dy;

// //     final inView =
// //         ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
// //     if (!inView) return null;

// //     double left = ax - (_popupW / 2);
// //     double top = ay - (_popupH / 2);

// //     const margin = 8.0;
// //     final minLeft = margin;
// //     final maxLeft = screen.width - _popupW - margin;
// //     final minTop = topPad + margin;
// //     final maxTop = screen.height - _popupH - margin;

// //     if (left < minLeft) left = minLeft;
// //     if (left > maxLeft) left = maxLeft;
// //     if (top < minTop) top = minTop;
// //     if (top > maxTop) top = maxTop;

// //     return Offset(left, top);
// //   }

// //   Future<void> _onDestinationRoomSubmitted(
// //     String buildingCode,
// //     String roomCode,
// //   ) async {
// //     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

// //     try {
// //       final repo = IndoorMapRepository();
// //       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

// //       if (roomLocation == null) {
// //         print('[ERROR] Could not find location for room $roomCode');
// //         return;
// //       }
// //       print('[DEBUG] Room location found: $roomLocation');
// //       final marker = Marker(
// //         markerId: const MarkerId('destination_room'),
// //         position: roomLocation,
// //         infoWindow: InfoWindow(title: 'Room $roomCode'),
// //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
// //       );

// //       if (!mounted) return;
// //       setState(() {
// //         _destinationRoomMarker = marker;
// //       });

// //       print('[DEBUG] Destination room marker placed at $roomLocation');
// //     } catch (e) {
// //       print('[ERROR] Error processing destination room: $e');
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Error: $e'),
// //           backgroundColor: const Color(0xFFE53935),
// //         ),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final LatLng initialTarget =
// //         widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

// //     final Campus labelCampus =
// //         _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

// //     final String campusLabel = labelCampus == Campus.sgw
// //         ? 'SGW'
// //         : labelCampus == Campus.loyola
// //             ? 'Loyola'
// //             : '';

// //     final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
// //     final popupPos = _computePopupPosition(context);

// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           if (widget.debugDisableMap)
// //             const SizedBox.expand()
// //           else
// //             OutdoorMapView(
// //               initialTarget: initialTarget,
// //               showIndoorStyle: _showIndoor,
// //               indoorMapStyle: _indoorMapStyle,
// //               onMapCreated: (c) => _mapController = c,
// //               onCameraMove: (pos) {
// //                 _lastCameraTarget = pos.target;
// //                 if (_selectedBuildingCenter != null) _schedulePopupUpdate();
// //               },
// //               onCameraMoveStarted: () {
// //                 if (_selectedBuildingCenter == null) return;
// //                 setState(() => _cameraMoving = true);
// //               },
// //               onCameraIdle: () {
// //                 _syncToggleWithCameraCenter();
// //                 if (_selectedBuildingCenter == null) return;
// //                 setState(() => _cameraMoving = false);
// //                 _updatePopupOffset();
// //               },
// //               markers: {
// //                 ..._createMarkers(),
// //                 ..._roomLabelMarkers,
// //               },
// //               circles: _createCircles(),
// //               polygons: {
// //                 ..._createBuildingPolygons(),
// //                 ..._indoorPolygons,
// //               },
// //               polylines: _routePolylines,
// //             ),

// //           if (_isNavigating)
// //             Positioned(
// //               top: 80,
// //               left: 0,
// //               right: 0,
// //               child: PointerInterceptor(
// //                 child: NavigationNextStepHeader(
// //                   modeLabel: _selectedTravelMode.label,
// //                   nextStep: _getCurrentNavStep(),
// //                   onStop: _stopNavigation,
// //                   onShowSteps: _openStepsForSelectedMode,
// //                 ),
// //               ),
// //             ),

// //           if (_showRoutePreview && !_isNavigating)
// //             Positioned(
// //               top: 80,
// //               left: 0,
// //               right: 0,
// //               child: RoutePreviewPanel(
// //                 originText: _routeOriginText,
// //                 destinationText: _routeDestinationText,
// //                 onClose: _closeRoutePreview,
// //                 onSwitch: _switchOriginDestination,
// //                 onOriginChanged: _onRouteOriginChanged,
// //                 onDestinationChanged: _onRouteDestinationChanged,
// //                 onOriginSelected: _onRouteOriginSelected,
// //                 onDestinationSelected: _onRouteDestinationSelected,
// //                 originSuggestions: _routeOriginSuggestions,
// //                 destinationSuggestions: _routeDestinationSuggestions,
// //                 originRoomController: _originRoomController,
// //                 destinationRoomController: _destinationRoomController,
// //                 onOriginRoomSubmitted: _onOriginRoomSubmitted,
// //                 onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
// //                 originBuildingCode: _routeOriginBuildingCode,
// //                 destinationBuildingCode: _routeDestinationBuildingCode,
// //                 isConcordiaBuilding: (buildingCode) {
// //                   return buildingPolygons.any(
// //                     (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
// //                   );
// //                 },
// //               ),
// //             ),

// //           if (_showRoutePreview)
// //             Positioned(
// //               bottom: 25,
// //               left: 0,
// //               right: 0,
// //               child: PointerInterceptor(
// //                 child: Center(
// //                   child: RouteTravelModeBar(
// //                     selectedTravelMode: _selectedTravelMode,
// //                     onTravelModeSelected: _onTravelModeSelected,
// //                     modeDurations: _routeDurations,
// //                     isLoadingDurations: _isLoadingRouteData,
// //                     onClose: _closeRoutePreview,
// //                     onStart: _startNavigation,
// //                     isNavigating: _isNavigating,
// //                     onShowSteps: _openStepsForSelectedMode,
// //                     transitDetails: _buildTransitDetailItems(),
// //                     modeDistances: _routeDistances,
// //                     modeArrivalTimes: _routeArrivalTimes,
// //                     shuttleNextBuses:
// //                         _shuttleNextBuses.map((b) => b.statusLabel).toList(),
// //                     shuttleWalkingMinutes: _shuttleWalkingMinutes,
// //                     shuttleNearestStop: _shuttleNearestStop,
// //                     onViewSchedule: _showShuttleScheduleModal,
// //                   ),
// //                 ),
// //               ),
// //             ),

// //           if (!_showRoutePreview && !_isNavigating)
// //             OutdoorTopSearch(
// //               campusLabel: campusLabel,
// //               controller: _searchController,
// //               onSubmitted: _onSearchSubmitted,
// //               suggestions: _searchSuggestions,
// //               onSuggestionSelected: _onSuggestionSelected,
// //               onFocus: _hideBuildingPopup,
// //               originRoomController: _originRoomController,
// //               destinationRoomController: _destinationRoomController,
// //               onOriginRoomSubmitted: _onOriginRoomSubmitted,
// //               onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
// //               selectedBuildingCode: _selectedBuildingPoly?.code,
// //               currentBuildingCode: _currentBuildingCode,
// //               userLocation: _currentLocation,
// //               isConcordiaBuilding: (buildingCode) {
// //                 return buildingPolygons.any(
// //                   (b) =>
// //                       (b.code ?? '').toUpperCase() ==
// //                       buildingCode.toUpperCase(),
// //                 );
// //               },
// //               showIndoor: _showIndoor,
// //               floors: _indoorFloors,
// //               selectedAssetPath: _selectedIndoorFloorAsset,
// //               onFloorChanged: _loadIndoorFloor,
// //             ),

// //           if (selectedBuilding != null && popupPos != null)
// //             OutdoorBuildingPopup(
// //               building: selectedBuilding,
// //               position: popupPos,
// //               buildingInfoByCode: buildingInfoByCode,
// //               debugLinkOverride: widget.debugLinkOverride,
// //               onClose: _closePopup,
// //               onIndoorMap: _toggleIndoorMap,
// //               onGetDirections: _getDirections,
// //               onOpenLink: _openLink,
// //               isLoggedIn: widget.isLoggedIn,
// //             ),

// //           OutdoorBottomControls(
// //             currentLocation: _currentLocation,
// //             currentCampus: _currentCampus,
// //             onGoToMyLocation: _goToMyLocation,
// //             onCenterOnUser: () {
// //               final loc = _currentLocation;
// //               if (loc == null) return;
// //               _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
// //             },
// //           ),

// //           OutdoorBottomBar(
// //             showRoutePreview: _showRoutePreview,
// //             isNavigating: _isNavigating,
// //             selectedCampus: _selectedCampus,
// //             onCampusChanged: _switchCampus,
// //             selectedTravelMode: _selectedTravelMode,
// //             onTravelModeSelected: _onTravelModeSelected,
// //             routeDurations: _routeDurations,
// //             routeDistances: _routeDistances,
// //             routeArrivalTimes: _routeArrivalTimes,
// //             isLoadingRouteData: _isLoadingRouteData,
// //             onCloseRoutePreview: _closeRoutePreview,
// //             onStartNavigation: _startNavigation,
// //             onShowSteps: _openStepsForSelectedMode,
// //             transitDetails: _buildTransitDetailItems(),
// //           ),

// //           ..._createBuildingGestureDetectors(),
// //         ],
// //       ),
// //     );
// //   }

// //   static const String _indoorMapStyle = '''
// //   [
// //     {
// //       "featureType": "poi",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "poi.school",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "poi.business",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "transit",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     }
// //   ]
// //   ''';

// //   @override
// //   void dispose() {
// //     _posSub?.cancel();
// //     _popupDebounce?.cancel();
// //     _debounceTimer?.cancel();
// //     _routeDebounceTimer?.cancel();
// //     _mapController?.dispose();
// //     _searchController.removeListener(_onSearchChanged);
// //     _searchController.dispose();
// //     _originRoomController.dispose();
// //     _destinationRoomController.dispose();
// //     super.dispose();
// //   }
// // }


// // class _ShuttleScheduleSheet extends StatelessWidget {
// //   final String nearestStop;

// //   const _ShuttleScheduleSheet({required this.nearestStop});

// //   @override
// //   Widget build(BuildContext context) {
// //     const burgundy = Color(0xFF76263D);
// //     final today = DateTime.now();
// //     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
// //     final isWeekday =
// //         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

// //     return DraggableScrollableSheet(
// //       initialChildSize: 0.62,
// //       minChildSize: 0.35,
// //       maxChildSize: 0.92,
// //       builder: (context, scrollController) {
// //         return Container(
// //           decoration: const BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
// //           ),
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 10),
// //               Container(
// //                 height: 4,
// //                 width: 44,
// //                 decoration: BoxDecoration(
// //                   color: Colors.black.withOpacity(0.12),
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //               ),
// //               const SizedBox(height: 10),

// //               Padding(
// //                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
// //                 child: Row(
// //                   children: [
// //                     const Icon(Icons.directions_bus_filled, color: burgundy),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           const Text(
// //                             'Concordia Shuttle Schedule',
// //                             style: TextStyle(
// //                               color: burgundy,
// //                               fontWeight: FontWeight.w800,
// //                               fontSize: 16,
// //                             ),
// //                           ),
// //                           Text(
// //                             isWeekday
// //                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
// //                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
// //                             style: const TextStyle(
// //                               color: Colors.black54,
// //                               fontSize: 11,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     IconButton(
// //                       onPressed: () => Navigator.of(context).maybePop(),
// //                       icon: const Icon(Icons.close),
// //                     ),
// //                   ],
// //                 ),
// //               ),

// //               Padding(
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //                 child: Row(
// //                   children: [
// //                     _StopChip(
// //                         label: 'SGW  (Hall Building)', color: burgundy),
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(horizontal: 8),
// //                       child: Icon(Icons.sync_alt,
// //                           size: 16, color: Colors.black45),
// //                     ),
// //                     _StopChip(label: 'Loyola', color: burgundy),
// //                   ],
// //                 ),
// //               ),

// //               const Divider(height: 1),

// //               Expanded(
// //                 child: ListView.builder(
// //                   controller: scrollController,
// //                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
// //                   itemCount: times.length,
// //                   itemBuilder: (context, index) {
// //                     final t = times[index];
// //                     final now = DateTime.now();
// //                     final isPast = t.isBefore(now);
// //                     final isNext = !isPast &&
// //                         (index == 0 || times[index - 1].isBefore(now));

// //                     return Container(
// //                       margin: const EdgeInsets.only(bottom: 6),
// //                       padding: const EdgeInsets.symmetric(
// //                           horizontal: 12, vertical: 8),
// //                       decoration: BoxDecoration(
// //                         color: isNext
// //                             ? burgundy.withOpacity(0.08)
// //                             : Colors.transparent,
// //                         border: isNext
// //                             ? Border.all(color: burgundy.withOpacity(0.3))
// //                             : null,
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(
// //                             Icons.directions_bus_filled,
// //                             size: 16,
// //                             color: isPast
// //                                 ? Colors.black26
// //                                 : isNext
// //                                     ? burgundy
// //                                     : Colors.black54,
// //                           ),
// //                           const SizedBox(width: 10),
// //                           Text(
// //                             ConcordiaShuttleService.formatTime(t),
// //                             style: TextStyle(
// //                               fontSize: 14,
// //                               fontWeight: isNext
// //                                   ? FontWeight.w700
// //                                   : FontWeight.w400,
// //                               color: isPast
// //                                   ? Colors.black26
// //                                   : isNext
// //                                       ? burgundy
// //                                       : Colors.black87,
// //                             ),
// //                           ),
// //                           if (isNext) ...[
// //                             const SizedBox(width: 10),
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                   horizontal: 8, vertical: 2),
// //                               decoration: BoxDecoration(
// //                                 color: burgundy,
// //                                 borderRadius: BorderRadius.circular(10),
// //                               ),
// //                               child: const Text(
// //                                 'Next bus',
// //                                 style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: 10,
// //                                   fontWeight: FontWeight.w700,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ],
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }

// // class _StopChip extends StatelessWidget {
// //   final String label;
// //   final Color color;

// //   const _StopChip({required this.label, required this.color});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.1),
// //         border: Border.all(color: color.withOpacity(0.4)),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Text(
// //         label,
// //         style: TextStyle(
// //           color: color,
// //           fontSize: 12,
// //           fontWeight: FontWeight.w600,
// //         ),
// //       ),
// //     );
// //   }
// // }


// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:pointer_interceptor/pointer_interceptor.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // import '../../shared/widgets/map_search_bar.dart';
// // import '../building_detection.dart';
// // import '../../data/building_polygons.dart';
// // import '../../data/search_result.dart';
// // import '../../data/search_suggestion.dart';
// // import '../building_search_service.dart';
// // import '../google_places_service.dart';
// // import '../google_directions_service.dart';
// // import '../../shared/widgets/campus_toggle.dart';
// // import '../../shared/widgets/building_info_popup.dart';
// // import '../../shared/widgets/route_preview_panel.dart';
// // import '../../features/indoor/data/building_info.dart';
// // import '../../services/navigation_steps.dart';
// // import '../indoor_maps/indoor_floor_config.dart';
// // import 'package:campus_app/utils/geo.dart' as geo;
// // import '../../shared/widgets/indoor_floor_dropdown.dart';
// // import '../indoor_maps/indoor_map_controller.dart';
// // import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// // import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// // import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// // import 'package:campus_app/models/campus.dart';
// // import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// // import '../indoor_maps/indoor_map_repository.dart';
// // import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// // import '../../services/concordia_shuttle_service.dart';

// // // concordia campus coordinates
// // const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// // const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// // const double campusRadius = 500; // meters
// // const String currentLocationTag = "Current location";

// // // when camera center is within this distance auto-switch toggle
// // const double campusAutoSwitchRadius = 500; // meters
// // // knowing which campus the user is in
// // Campus detectCampus(LatLng userLocation) {
// //   final sgwDistance = Geolocator.distanceBetween(
// //     userLocation.latitude,
// //     userLocation.longitude,
// //     concordiaSGW.latitude,
// //     concordiaSGW.longitude,
// //   );

// //   final loyolaDistance = Geolocator.distanceBetween(
// //     userLocation.latitude,
// //     userLocation.longitude,
// //     concordiaLoyola.latitude,
// //     concordiaLoyola.longitude,
// //   );

// //   if (sgwDistance <= campusRadius) return Campus.sgw;
// //   if (loyolaDistance <= campusRadius) return Campus.loyola;
// //   return Campus.none;
// // }

// // class OutdoorMapPage extends StatefulWidget {
// //   final Campus initialCampus;
// //   final bool isLoggedIn;

// //   @visibleForTesting
// //   final BuildingPolygon? debugSelectedBuilding;

// //   @visibleForTesting
// //   final Offset? debugAnchorOffset;

// //   @visibleForTesting
// //   final bool debugDisableMap;

// //   @visibleForTesting
// //   final bool debugDisableLocation;

// //   @visibleForTesting
// //   final String? debugLinkOverride;

// //   const OutdoorMapPage({
// //     super.key,
// //     required this.initialCampus,
// //     this.debugSelectedBuilding,
// //     this.debugAnchorOffset,
// //     this.debugDisableMap = false,
// //     this.debugDisableLocation = false,
// //     this.debugLinkOverride,
// //     required this.isLoggedIn,
// //   });

// //   @override
// //   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// // }

// // class _IndoorFloorOption {
// //   final String label;
// //   final String assetPath;

// //   const _IndoorFloorOption({
// //     required this.label,
// //     required this.assetPath,
// //   });
// // }

// // class _OutdoorMapPageState extends State<OutdoorMapPage> {
// //   final TextEditingController _searchController = TextEditingController();
// //   final TextEditingController _originRoomController = TextEditingController();
// //   final TextEditingController _destinationRoomController = TextEditingController();
// //   bool _cameraMoving = false;
// //   List<SearchSuggestion> _searchSuggestions = [];
// //   Timer? _debounceTimer;

// //   // Indoor overlay state
// //   Set<Polygon> _indoorPolygons = {};
// //   bool _showIndoor = false;
// //   List<IndoorFloorOption> _indoorFloors = const [];
// //   String? _selectedIndoorFloorAsset;
// //   final IndoorMapController _indoorController = IndoorMapController();

// //   // --- Indoor floors state ---
// //   String? _indoorBuildingCode; // building currently shown in indoor mode
// //   String? _selectedIndoorFloorAsset; // which floor file is loaded
// //   List<_IndoorFloorOption> _indoorFloors = []; // dropdown options

// //   GoogleMapController? _mapController;

// //   LatLng? _currentLocation;
// //   BitmapDescriptor? _blueDotIcon;
// //   BuildingPolygon? _currentBuildingPoly;
// //   BuildingPolygon? _selectedBuildingPoly;
// //   // ignore: unused_field
// //   SearchResult? _selectedSearchResult;
// //   // ignore: unused_field
// //   Map<String, dynamic>? _indoorGeoJson;
// //   Set<Marker> _roomLabelMarkers = {};

// //   Set<Polyline> _routePolylines = {};

// //   // Room location marker
// //   Marker? _destinationRoomMarker;
// //   String? _currentBuildingCode;

// //   // Route preview mode
// //   bool _showRoutePreview = false;
// //   LatLng? _routeOrigin;
// //   LatLng? _routeDestination;
// //   String _routeOriginText = currentLocationTag;
// //   String _routeDestinationText = '';
// //   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
// //   final Map<String, String?> _routeDurations = {};
// //   final Map<String, String?> _routeDistances = {};
// //   final Map<String, String?> _routeArrivalTimes = {};
// //   final Map<String, List<LatLng>> _routePointsByMode = {};
// //   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
// //   String? _routeOriginBuildingCode;
// //   String? _routeDestinationBuildingCode;

// //   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
// //   // --- Navigation camera follow state ---
// //   bool _navigationFollowUser = false;
// //   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// //   static const double _navZoom = 18.0;
// //   static const double _navTilt = 60.0;
// //   static const double _defaultZoom = 15.0;
// //   static const double _defaultTilt = 0.0;
// //   static const double _defaultBearing = 0.0;
// //   // ignore: unused_field
// //   static const double _navBearingThresholdDegrees = 10.0;
// //   // ignore: unused_field
// //   static const double _navDistanceThresholdMeters = 5.0;
// //   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
// //   bool _isNavigating = false;
// //   String? _navModeKey;
// //   int _navStepIndex = 0;
// //   bool _isLoadingRouteData = false;
// //   List<SearchSuggestion> _routeOriginSuggestions = [];
// //   List<SearchSuggestion> _routeDestinationSuggestions = [];
// //   Timer? _routeDebounceTimer;

// //   // Google Directions modes only — shuttle is handled separately
// //   static const List<RouteTravelMode> _supportedTravelModes = [
// //     RouteTravelMode.driving,
// //     RouteTravelMode.walking,
// //     RouteTravelMode.bicycling,
// //     RouteTravelMode.transit,
// //   ];

// //   List<ShuttleDeparture> _shuttleNextBuses = [];
// //   int? _shuttleWalkingMinutes;
// //   String _shuttleNearestStop = 'SGW';
// //   BitmapDescriptor? _shuttleStopIcon;

// //   StreamSubscription<Position>? _posSub;

// //   Timer? _popupDebounce;

// //   static const double _popupW = 300;
// //   static const double _popupH = 260;

// //   LatLng? _selectedBuildingCenter;
// //   Offset? _anchorOffset;

// //   Campus _currentCampus = Campus.none;
// //   Campus _selectedCampus = Campus.none;

// //   LatLng? _lastCameraTarget;

// //   List<_IndoorFloorOption> _floorsForBuilding(String code) {
// //     switch (code.toUpperCase()) {
// //       case 'HALL':
// //         return const [
// //           _IndoorFloorOption(
// //             label: '1',
// //             assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '2',
// //             assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '8',
// //             assetPath: 'assets/indoor_maps/geojson/Hall/h8.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '9',
// //             assetPath: 'assets/indoor_maps/geojson/Hall/h9.geojson.json',
// //           ),
// //         ];

// //       case 'MB':
// //         return const [
// //           _IndoorFloorOption(
// //             label: '1',
// //             assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '2',
// //             assetPath: 'assets/indoor_maps/geojson/MB/mb2.geojson.json',
// //           ),
// //         ];

// //       case 'VE':
// //         return const [
// //           _IndoorFloorOption(
// //             label: '1',
// //             assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '2',
// //             assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json',
// //           ),
// //         ];

// //       case 'VL':
// //         return const [
// //           _IndoorFloorOption(
// //             label: '1',
// //             assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
// //           ),
// //           _IndoorFloorOption(
// //             label: '2',
// //             assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json',
// //           ),
// //         ];

// //       case 'CC':
// //         return const [
// //           _IndoorFloorOption(
// //             label: '1',
// //             assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
// //           ),
// //         ];

// //       default:
// //         return const [];
// //     }
// //   }
// //   void _clearIndoorState() {
// //     _showIndoor = false;
// //     _indoorFloors = const [];
// //     _selectedIndoorFloorAsset = null;
// //     _indoorPolygons = {};
// //     _indoorGeoJson = null;
// //     _roomLabelMarkers = {};
// //   }

// //   Campus _campusFromPoint(LatLng p) {
// //     final dSgw = Geolocator.distanceBetween(
// //       p.latitude,
// //       p.longitude,
// //       concordiaSGW.latitude,
// //       concordiaSGW.longitude,
// //     );

// //     final dLoy = Geolocator.distanceBetween(
// //       p.latitude,
// //       p.longitude,
// //       concordiaLoyola.latitude,
// //       concordiaLoyola.longitude,
// //     );

// //     final minDist = dSgw < dLoy ? dSgw : dLoy;
// //     if (minDist > campusAutoSwitchRadius) return Campus.none;

// //     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
// //   }

// //   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
// //   print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
// // }

// //   Future<void> _syncToggleWithCameraCenter() async {
// //     if (!mounted) return;

// //     LatLng? center = _lastCameraTarget;

// //     if (center == null) {
// //       final controller = _mapController;
// //       if (controller == null) return;

// //       try {
// //         final bounds = await controller.getVisibleRegion();
// //         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
// //         final lng =
// //             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
// //         center = LatLng(lat, lng);
// //       } catch (_) {
// //         return;
// //       }
// //     }

// //     final newCampus = _campusFromPoint(center);

// //     if (newCampus == _selectedCampus) return;

// //     setState(() {
// //       _selectedCampus = newCampus;
// //     });
// //   }

// //   List<int> _getAvailableFloorsForBuilding(String code) {
// //     switch (code.toUpperCase()) {
// //       case 'HALL':
// //         return [1];
// //       case 'MB':
// //         return [1];
// //       case 'VE':
// //         return [1];
// //       case 'VL':
// //         return [1];
// //       case 'CC':
// //         return [1];
// //       default:
// //         return [];
// //     }
// //   }

// //   String? _getIndoorAssetPath(String buildingCode, int floor) {
// //     final code = buildingCode.toUpperCase();
// //     switch (code) {
// //       case 'HALL':
// //         return 'assets/indoor_maps/geojson/Hall/h$floor.geojson.json';
// //       case 'MB':
// //         return 'assets/indoor_maps/geojson/MB/mb$floor.geojson.json';
// //       case 'VE':
// //         return 'assets/indoor_maps/geojson/VE/ve$floor.geojson.json';
// //       case 'VL':
// //         return 'assets/indoor_maps/geojson/VL/vl$floor.geojson.json';
// //       case 'CC':
// //         return 'assets/indoor_maps/geojson/CC/cc$floor.geojson.json';
// //       default:
// //         return null;
// //     }
// //   }
// // bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
// //   return geo.pointInPolygon(point, polygon);
// // }

// //   Future<void> _loadIndoorFloor(String assetPath) async {
// //     try {
// //       final repo = IndoorMapRepository();
// //       final geo = await repo.loadGeoJsonAsset(assetPath);

// //       final polys = _geoJsonToPolygons(geo);
// //       final labels = await _createRoomLabels(geo);

// //       if (!mounted) return;
// //       setState(() {
// //         _showIndoor = true;
// //         _selectedIndoorFloorAsset = assetPath;
// //         _indoorPolygons = polys;
// //         _indoorGeoJson = geo;
// //         _roomLabelMarkers = labels;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to load indoor floor: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _loadIndoorMapForSelectedBuilding() async {
// //     final b = _selectedBuildingPoly;
// //     if (b == null) return;

// //     final floors = _getAvailableFloorsForBuilding(b.code);
// //     if (floors.isEmpty) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text(
// //               'Indoor map currently only available for Hall, MB, VE, VL, and CC'),
// //         ),
// //       );
// //       return;
// //     }

// //     if (!mounted) return;
// //     setState(() {
// //       _availableFloorsForSelectedBuilding = floors;

// //       if (!floors.contains(_selectedIndoorFloor)) {
// //         _selectedIndoorFloor = floors.first;
// //       }
// //     });

// //     final assetPath = _getIndoorAssetPath(b.code, _selectedIndoorFloor);
// //     if (assetPath == null) return;

// //     setState(() {
// //       _isLoadingRouteData = false;
// //     });

// //     try {
// //       final repo = IndoorMapRepository();
// //       final geo = await repo.loadGeoJsonAsset(assetPath);

// //       final polys = _geoJsonToPolygons(geo);
// //       final labels = await _createRoomLabels(geo);

// //       if (!mounted) return;
// //       setState(() {
// //         _showIndoor = true;
// //         _indoorPolygons = polys;
// //         _indoorGeoJson = geo;
// //         _roomLabelMarkers = labels;
// //       });
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Failed to load indoor map: $e')),
// //       );
// //     }
// //   }
// // Future<void> _loadIndoorFloor(String assetPath) async {
// //   try {
// //     final result = await _indoorController.loadFloor(assetPath);
// //     if (!mounted) return;
// //     setState(() {
// //       _showIndoor = true;
// //       _selectedIndoorFloorAsset = assetPath;
// //       _indoorPolygons = result.polygons;
// //       _indoorGeoJson = result.geoJson;
// //       _roomLabelMarkers = result.labels;
// //     });
// //   } catch (e) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Failed to load indoor floor: $e')),
// //     );
// //   }
// // }

// // Future<void> _toggleIndoorMap() async {
// //   // turn OFF
// //   if (_showIndoor) {
// //     setState(() {
// //       _clearIndoorState();
// //     });
// //     return;
// //   }
// //   Future<void> _toggleIndoorMap() async {
// //     if (_showIndoor) {
// //       setState(() {
// //         _showIndoor = false;
// //         _indoorBuildingCode = null;
// //         _selectedIndoorFloorAsset = null;
// //         _indoorFloors = [];
// //         _indoorPolygons = {};
// //         _indoorGeoJson = null;
// //         _roomLabelMarkers = {};
// //       });
// //       return;
// //     }

// //   // turn ON (needs selected building)
// //   final b = _selectedBuildingPoly;
// //   if (b == null) return;
// //     final b = _selectedBuildingPoly;
// //     if (b == null) return;

// //   final floors = IndoorFloorConfig.floorsForBuilding(b.code);
// //   if (floors.isEmpty) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(content: Text('No indoor maps available for this building')),
// //     );
// //     return;
// //   }
// //     final floors = _floorsForBuilding(b.code);
// //     if (floors.isEmpty) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Indoor map not available for this building'),
// //         ),
// //       );
// //       return;
// //     }

// //   setState(() {
// //     _indoorFloors = floors;
// //     _selectedIndoorFloorAsset = floors.first.assetPath;
// //   });
// //     setState(() {
// //       _indoorBuildingCode = b.code;
// //       _indoorFloors = floors;
// //     });

// //     await _loadIndoorFloor(floors.first.assetPath);
// //   }

// //   Future<void> _goToMyLocation() async {
// //     final controller = _mapController;
// //     if (controller == null) return;

// //     var loc = _currentLocation;

// //     if (loc == null) {
// //       try {
// //         final p = await Geolocator.getCurrentPosition();
// //         loc = LatLng(p.latitude, p.longitude);
// //         if (mounted) setState(() => _currentLocation = loc);
// //       } catch (_) {
// //         return;
// //       }
// //     }

// //     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
// //   }

// //   Future<void> _openLink(String url) async {
// //     if (url.trim().isEmpty) return;

// //     final uri = Uri.tryParse(url);
// //     if (uri == null) return;

// //     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
// //     if (!ok) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
// //     }
// //   }

// //   LatLng _polygonCenter(List<LatLng> pts) {
// //     if (pts.length < 3) return pts.first;

// //     double lat = 0;
// //     double lng = 0;
// //     for (final p in pts) {
// //       lat += p.latitude;
// //       lng += p.longitude;
// //     }
// //     final avg = LatLng(lat / pts.length, lng / pts.length);

// //     if (_isPointInPolygon(avg, pts)) return avg;

// //     double maxDist = 0;
// //     LatLng best = avg;
// //     for (int i = 0; i < pts.length; i++) {
// //       for (int j = i + 1; j < pts.length; j++) {
// //         final mid = LatLng(
// //           (pts[i].latitude + pts[j].latitude) / 2,
// //           (pts[i].longitude + pts[j].longitude) / 2,
// //         );
// //         final dist =
// //             (pts[i].latitude - pts[j].latitude) *
// //                 (pts[i].latitude - pts[j].latitude) +
// //             (pts[i].longitude - pts[j].longitude) *
// //                 (pts[i].longitude - pts[j].longitude);
// //         if (dist > maxDist && _isPointInPolygon(mid, pts)) {
// //           maxDist = dist;
// //           best = mid;
// //         }
// //       }
// //     }

// //     return best;
// //   }

// //   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
// //     bool inside = false;
// //     int j = polygon.length - 1;

// //     for (int i = 0; i < polygon.length; i++) {
// //       final xi = polygon[i].latitude;
// //       final yi = polygon[i].longitude;
// //       final xj = polygon[j].latitude;
// //       final yj = polygon[j].longitude;

// //       if (((yi > point.longitude) != (yj > point.longitude)) &&
// //           (point.latitude <
// //               (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
// //         inside = !inside;
// //       }
// //       j = i;
// //     }

// //     return inside;
// //   }

// //   double _polygonArea(List<LatLng> pts) {
// //     double area = 0;
// //     int j = pts.length - 1;
// //     for (int i = 0; i < pts.length; i++) {
// //       area +=
// //           (pts[j].longitude + pts[i].longitude) *
// //           (pts[j].latitude - pts[i].latitude);
// //       j = i;
// //     }
// //     return area.abs() / 2;
// //   }

// //   void _schedulePopupUpdate() {
// //     _popupDebounce?.cancel();
// //     _popupDebounce = Timer(
// //       const Duration(milliseconds: 16),
// //       _updatePopupOffset,
// //     );
// //   }

// //   Future<void> _updatePopupOffset() async {
// //     final controller = _mapController;
// //     final center = _selectedBuildingCenter;
// //     if (!mounted || controller == null || center == null) return;

// //     final sc = await controller.getScreenCoordinate(center);
// //     if (!mounted) return;

// //     double x = sc.x.toDouble();
// //     double y = sc.y.toDouble();

// //     final dpr = MediaQuery.of(context).devicePixelRatio;
// //     x = x / dpr;
// //     y = y / dpr;

// //     setState(() {
// //       _anchorOffset = Offset(x, y);
// //     });
// //   }

// //   // ignore: unused_element
// //   void _selectBuildingWithoutMap(BuildingPolygon b) {
// //     final center = geo.polygonCenter(b.points);
// //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// //     _searchController.value = TextEditingValue(
// //       text: name,
// //       selection: TextSelection.collapsed(offset: name.length),
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = b;
// //       _selectedBuildingCenter = center;
// //       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
// //       _cameraMoving = false;
// //     });
// //   }

// //   void _onBuildingTapped(BuildingPolygon b) {
// //     final center = geo.polygonCenter(b.points);
// //     final controller = _mapController;
// //     final name = buildingInfoByCode[b.code]?.name ?? b.name;

// //     _searchController.value = TextEditingValue(
// //       text: name,
// //       selection: TextSelection.collapsed(offset: name.length),
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = b;
// //       _selectedBuildingCenter = center;
// //       _anchorOffset = null;
// //       _cameraMoving = true;
// //       _clearIndoorState();
// //       _roomLabelMarkers = {};

// //       _availableFloorsForSelectedBuilding =
// //           _getAvailableFloorsForBuilding(b.code);
// //       _selectedIndoorFloor = _availableFloorsForSelectedBuilding.isNotEmpty
// //           ? _availableFloorsForSelectedBuilding.first
// //           : 1;
// //     });

// //     if (controller == null) return;

// //     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
// //       _,
// //     ) async {
// //       if (!mounted) return;
// //       await _updatePopupOffset();
// //       if (!mounted) return;
// //       setState(() {
// //         _cameraMoving = false;
// //       });
// //     });
// //   }

// //   void _closePopup() {
// //     _clearSelectedBuilding(clearSearch: true);
// //   }

// //   void _clearSelectedBuilding({bool clearSearch = false}) {
// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _selectedSearchResult = null;
// //       _anchorOffset = null;
// //       _routePolylines = {};
// //       _showRoutePreview = false;
// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //       _routeDurations.clear();
// //       _routeDistances.clear();
// //       _routeArrivalTimes.clear();
// //       _routePointsByMode.clear();
// //       _routeSegmentsByMode.clear();
// //       _isLoadingRouteData = false;
// //       _selectedTravelMode = RouteTravelMode.driving;
// //       _destinationRoomMarker = null;
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //       if (clearSearch) {
// //         _searchController.clear();
// //       }
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _destinationRoomMarker = null;
// //       _routeOriginBuildingCode = null;
// //       _routeDestinationBuildingCode = null;
// //       _originRoomController.clear();
// //       _destinationRoomController.clear();
// //     });
// //   }

// //   Future<void> _getDirections() async {
// //     print('[DEBUG] Get directions button clicked');
// //     print('[DEBUG] Current location: $_currentLocation');
// //     print(
// //       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
// //     );

// //     final origin = _currentLocation;
// //     final destination = _selectedBuildingPoly?.center;

// //     if (origin == null) {
// //       print('[ERROR] Cannot get directions: Current location is null');
// //       print(
// //         '[ERROR] Make sure location services are enabled and location is set in emulator',
// //       );
// //       return;
// //     }

// //     if (destination == null) {
// //       print('[ERROR] Cannot get directions: Destination is null');
// //       return;
// //     }

// //     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

// //     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

// //     setState(() {
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _showRoutePreview = true;
// //       _routeOrigin = origin;
// //       _routeDestination = destination;
// //       _routeOriginText = currentLocationTag;
// //       _routeDestinationText =
// //           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
// //       _routeOriginBuildingCode =
// //           currentBuildingCode; // current location has no building code
// //       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
// //       print(
// //         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
// //       );
// //     });

// //     await _fetchRoutesAndDurations();
// //   }

// //   Future<void> _fetchRoutesAndDurations() async {
// //     final origin = _routeOrigin;
// //     final destination = _routeDestination;

// //     if (origin == null || destination == null) {
// //       print('[ERROR] Cannot fetch route: origin or destination is null');
// //       return;
// //     }

// //     print(
// //       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
// //     );

// //     setState(() {
// //       _isLoadingRouteData = true;
// //     });

// //     try {
// //       final futures = _supportedTravelModes.map(
// //         (mode) => GoogleDirectionsService.instance.getRouteDetails(
// //           origin: origin,
// //           destination: destination,
// //           mode: mode.apiValue,
// //         ),
// //       );

// //       final results = await Future.wait(futures);
// //       final durations = <String, String?>{};
// //       final distances = <String, String?>{};
// //       final arrivalTimes = <String, String?>{};
// //       final pointsByMode = <String, List<LatLng>>{};
// //       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
// //       final stepsByMode = <String, List<NavigationStep>>{};

// //       for (var i = 0; i < _supportedTravelModes.length; i++) {
// //         final mode = _supportedTravelModes[i].apiValue;
// //         final route = results[i];
// //         durations[mode] = route?.durationText;
// //         distances[mode] = route?.distanceText;
// //         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
// //         stepsByMode[mode] = route?.steps ?? const [];
// //         if (route != null && route.points.isNotEmpty) {
// //           pointsByMode[mode] = route.points;
// //         }
// //         if (route != null && route.transitSegments.isNotEmpty) {
// //           segmentsByMode[mode] = route.transitSegments;
// //         }
// //       }

// //       if (!mounted) return;

// //       setState(() {
// //         _routeDurations
// //           ..clear()
// //           ..addAll(durations);
// //         _routeDistances
// //           ..clear()
// //           ..addAll(distances);
// //         _routeArrivalTimes
// //           ..clear()
// //           ..addAll(arrivalTimes);
// //         _routePointsByMode
// //           ..clear()
// //           ..addAll(pointsByMode);
// //         _routeSegmentsByMode
// //           ..clear()
// //           ..addAll(segmentsByMode);
// //         _routeStepsByMode
// //           ..clear()
// //           ..addAll(stepsByMode);

// //         _isLoadingRouteData = false;
// //       });

// //       _applySelectedModeRoute(animateCamera: true);

// //       _fetchShuttleInfo();
// //     } catch (e) {
// //       print('Error getting directions: $e');
// //       if (!mounted) return;
// //       setState(() {
// //         _isLoadingRouteData = false;
// //       });
// //     }
// //   }

// //   void _openStepsForSelectedMode() {
// //     // ── NEW: shuttle uses a schedule modal instead of steps ───────────────
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// //       _showShuttleScheduleModal();
// //       return;
// //     }

// //     final key = _selectedTravelMode.apiValue;
// //     final steps = _routeStepsByMode[key] ?? const [];

// //     showNavigationStepsModal(
// //       context,
// //       title: _selectedTravelMode.label,
// //       steps: steps,
// //       totalDuration: _routeDurations[key],
// //       totalDistance: _routeDistances[key],
// //     );
// //   }

// //   void _applySelectedModeRoute({required bool animateCamera}) {
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

// //     final selectedModeKey = _selectedTravelMode.apiValue;
// //     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
// //     if (_selectedTravelMode == RouteTravelMode.transit &&
// //         selectedSegments != null &&
// //         selectedSegments.isNotEmpty) {
// //       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
// //       return;
// //     }

// //     final selectedPoints = _routePointsByMode[selectedModeKey];

// //     if (selectedPoints == null || selectedPoints.isEmpty) {
// //       setState(() {
// //         _routePolylines = {};
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routePolylines = {
// //         Polyline(
// //           polylineId: const PolylineId('route'),
// //           points: selectedPoints,
// //           color: const Color(0xFF76263D),
// //           width: 5,
// //           patterns: _selectedTravelMode == RouteTravelMode.driving
// //               ? const []
// //               : [PatternItem.dot, PatternItem.gap(10)],
// //         ),
// //       };
// //     });

// //     if (!animateCamera || _mapController == null) return;
// //     final bounds = geo.calculateBounds(selectedPoints);
// //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //   }

// //   void _applyTransitSegments(
// //     List<DirectionsRouteSegment> segments, {
// //     required bool animateCamera,
// //   }) {
// //     final polylines = <Polyline>{};
// //     final allPoints = <LatLng>[];

// //     for (var i = 0; i < segments.length; i++) {
// //       final segment = segments[i];
// //       if (segment.points.isEmpty) {
// //         continue;
// //       }

// //       allPoints.addAll(segment.points);

// //       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
// //       polylines.add(
// //         Polyline(
// //           polylineId: PolylineId('route_segment_$i'),
// //           points: segment.points,
// //           color: _resolveTransitSegmentColor(segment),
// //           width: 5,
// //           patterns: isWalking
// //               ? [PatternItem.dot, PatternItem.gap(10)]
// //               : const [],
// //         ),
// //       );
// //     }

// //     if (polylines.isEmpty) {
// //       setState(() {
// //         _routePolylines = {};
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routePolylines = polylines;
// //     });

// //     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
// //       return;
// //     }

// //     final bounds = geo.calculateBounds(allPoints);
// //     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //   }

// //   void _startNavigation() {
// //     if (_selectedTravelMode == RouteTravelMode.shuttle) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text(
// //             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
// //           ),
// //           duration: Duration(seconds: 3),
// //         ),
// //       );
// //       return;
// //     }

// //     final key = _selectedTravelMode.apiValue;
// //     final steps = _routeStepsByMode[key] ?? const [];

// //     if (steps.isEmpty) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No steps available for this route')),
// //         );
// //       }
// //       return;
// //     }

// //     setState(() {
// //       _isNavigating = true;
// //       _navModeKey = key;
// //       _navStepIndex = 0;

// //       _navigationFollowUser = true;
// //       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
// //     });

// //     if (_currentLocation != null && _mapController != null) {
// //       try {
// //         final currentPos = _currentLocation!;
// //         final initialCam = CameraPosition(
// //           target: currentPos,
// //           zoom: _navZoom,
// //           tilt: _navTilt,
// //           bearing: 0.0,
// //         );
// //         _mapController!.animateCamera(
// //           CameraUpdate.newCameraPosition(initialCam),
// //         );
// //       } catch (e) {
// //         print('Error animating camera when starting navigation: $e');
// //       }
// //     }
// //   }

// //   void _stopNavigation() {
// //     setState(() {
// //       _isNavigating = false;
// //       _navModeKey = null;
// //       _navStepIndex = 0;
// //       _navigationFollowUser = false;
// //     });
// //     if (_mapController != null && _currentLocation != null) {
// //       try {
// //         final cam = CameraPosition(
// //           target: _currentLocation!,
// //           zoom: _defaultZoom,
// //           tilt: _defaultTilt,
// //           bearing: _defaultBearing,
// //         );

// //         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// //       } catch (e) {
// //         print('Error resetting camera after navigation: $e');
// //       }
// //     }

// //     _closeRoutePreview();
// //   }

// //   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
// //     if (_mapController == null) return;
// //     if (!_navigationFollowUser) return;

// //     final now = DateTime.now();

// //     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
// //       return;
// //     }

// //     double bearing = 0.0;
// //     if (heading != null && heading >= 0.0) {
// //       bearing = heading;
// //     }

// //     final cam = CameraPosition(
// //       target: userLatLng,
// //       zoom: _navZoom,
// //       tilt: _navTilt,
// //       bearing: bearing,
// //     );

// //     try {
// //       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
// //     } catch (e) {
// //       print('Error animating navigation camera: $e');
// //     }
// //   }

// //   void _maybeAdvanceNavigationStep(LatLng user) {
// //     final key = _navModeKey;
// //     if (key == null) return;

// //     final steps = _routeStepsByMode[key] ?? const [];
// //     if (steps.isEmpty) return;

// //     if (_navStepIndex >= steps.length - 1) return;

// //     final current = steps[_navStepIndex];
// //     final end = current.endPoint;
// //     if (end == null) return;

// //     final d = Geolocator.distanceBetween(
// //       user.latitude,
// //       user.longitude,
// //       end.latitude,
// //       end.longitude,
// //     );

// //     if (d <= 20) {
// //       setState(() => _navStepIndex += 1);
// //     }
// //   }

// //   void _closeRoutePreview() {
// //     setState(() {
// //       _showRoutePreview = false;
// //       _routePolylines = {};
// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //       _routeDurations.clear();
// //       _routeDistances.clear();
// //       _routeArrivalTimes.clear();
// //       _routePointsByMode.clear();
// //       _routeSegmentsByMode.clear();
// //       _isLoadingRouteData = false;
// //       _selectedTravelMode = RouteTravelMode.driving;
// //       _searchController.clear();

// //       //reset indoor map and building selection state
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _destinationRoomMarker = null;
// //       _originRoomController.clear();
// //       _destinationRoomController.clear();
// //       _routeOriginBuildingCode = null;
// //       _routeDestinationBuildingCode = null;
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //     });
// //   }

// //   String? _formatArrivalTime(int? durationSeconds) {
// //     if (durationSeconds == null) {
// //       return null;
// //     }

// //     final now = DateTime.now();
// //     final arrival = now.add(Duration(seconds: durationSeconds));
// //     int hour = arrival.hour;
// //     final minute = arrival.minute.toString().padLeft(2, '0');
// //     final isPm = hour >= 12;
// //     final period = isPm ? 'pm' : 'am';
// //     hour = hour % 12;
// //     if (hour == 0) {
// //       hour = 12;
// //     }
// //     return '$hour:$minute $period';
// //   }

// //   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
// //     const defaultRed = Color(0xFF76263D);
// //     final mode = segment.travelMode.toUpperCase();
// //     if (mode == 'WALKING') {
// //       return defaultRed;
// //     }

// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     if (vehicleType == 'BUS') {
// //       return Colors.blue;
// //     }

// //     final lineColor = parseHexColor(segment.transitLineColorHex);
// //     if (lineColor != null) {
// //       return lineColor;
// //     }

// //     return defaultRed;
// //   }

// //   List<TransitDetailItem> _buildTransitDetailItems() {
// //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// //     final items = <TransitDetailItem>[];

// //     for (final segment in segments) {
// //       if (segment.points.isEmpty) {
// //         continue;
// //       }

// //       final travelMode = segment.travelMode.toUpperCase();
// //       if (travelMode == 'WALKING') {
// //         continue;
// //       }

// //       final vehicleType = segment.transitVehicleType?.toUpperCase();
// //       final lineLabel =
// //           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
// //       final color = _resolveTransitSegmentColor(segment);

// //       IconData icon = Icons.directions_transit;
// //       String title = 'Transit $lineLabel';

// //       if (vehicleType == 'BUS') {
// //         icon = Icons.directions_bus;
// //         title = 'Bus $lineLabel';
// //       } else if (vehicleType == 'SUBWAY' ||
// //           vehicleType == 'METRO_RAIL' ||
// //           vehicleType == 'HEAVY_RAIL' ||
// //           vehicleType == 'COMMUTER_TRAIN' ||
// //           vehicleType == 'RAIL' ||
// //           vehicleType == 'TRAM' ||
// //           vehicleType == 'LIGHT_RAIL' ||
// //           vehicleType == 'MONORAIL') {
// //         icon = Icons.directions_subway;
// //         title = 'Metro $lineLabel';
// //       }

// //       items.add(TransitDetailItem(icon: icon, color: color, title: title));
// //     }

// //     return items;
// //   }

// //   // ignore: unused_element
// //   List<DirectionsRouteSegment> _getTransitDetailSegments() {
// //     final segments = _routeSegmentsByMode['transit'] ?? const [];
// //     return segments
// //         .where(
// //           (segment) =>
// //               segment.travelMode.toUpperCase() == 'TRANSIT' &&
// //               segment.points.isNotEmpty,
// //         )
// //         .toList();
// //   }

// //   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     final lineLabel =
// //         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

// //     if (vehicleType == 'BUS') {
// //       return 'Bus $lineLabel';
// //     }

// //     if (vehicleType == 'SUBWAY' ||
// //         vehicleType == 'METRO_RAIL' ||
// //         vehicleType == 'HEAVY_RAIL' ||
// //         vehicleType == 'COMMUTER_TRAIN' ||
// //         vehicleType == 'RAIL' ||
// //         vehicleType == 'TRAM' ||
// //         vehicleType == 'LIGHT_RAIL' ||
// //         vehicleType == 'MONORAIL') {
// //       return 'Metro $lineLabel';
// //     }

// //     return 'Transit $lineLabel';
// //   }

// //   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
// //     final vehicleType = segment.transitVehicleType?.toUpperCase();
// //     if (vehicleType == 'BUS') {
// //       return Icons.directions_bus;
// //     }
// //     if (vehicleType == 'SUBWAY' ||
// //         vehicleType == 'METRO_RAIL' ||
// //         vehicleType == 'HEAVY_RAIL' ||
// //         vehicleType == 'COMMUTER_TRAIN' ||
// //         vehicleType == 'RAIL' ||
// //         vehicleType == 'TRAM' ||
// //         vehicleType == 'LIGHT_RAIL' ||
// //         vehicleType == 'MONORAIL') {
// //       return Icons.directions_subway;
// //     }
// //     return Icons.directions_transit;
// //   }

// //   // ignore: unused_element
// //   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
// //     const burgundy = Color(0xFF76263D);

// //     return Container(
// //       width: 340,
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.15),
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Text(
// //             'Transit details',
// //             style: TextStyle(
// //               fontSize: 12,
// //               fontWeight: FontWeight.w600,
// //               color: burgundy,
// //             ),
// //           ),
// //           const SizedBox(height: 6),
// //           for (final segment in segments)
// //             Padding(
// //               padding: const EdgeInsets.only(bottom: 6),
// //               child: Row(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Icon(
// //                     _transitSegmentIcon(segment),
// //                     size: 16,
// //                     color: _resolveTransitSegmentColor(segment),
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           _formatTransitSegmentTitle(segment),
// //                           style: const TextStyle(
// //                             fontSize: 12,
// //                             fontWeight: FontWeight.w600,
// //                             color: Colors.black87,
// //                           ),
// //                         ),
// //                         if (segment.transitHeadsign != null &&
// //                             segment.transitHeadsign!.trim().isNotEmpty)
// //                           Text(
// //                             segment.transitHeadsign!,
// //                             style: const TextStyle(
// //                               fontSize: 11,
// //                               color: Colors.black54,
// //                             ),
// //                           ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Color? parseHexColor(String? hex) {
// //     if (hex == null || hex.trim().isEmpty) {
// //       return null;
// //     }

// //     final normalized = hex.trim().replaceFirst('#', '');
// //     if (normalized.length != 6) {
// //       return null;
// //     }

// //     final value = int.tryParse(normalized, radix: 16);
// //     if (value == null) {
// //       return null;
// //     }

// //     return Color(0xFF000000 | value);
// //   }

// //   void _switchOriginDestination() {
// //     setState(() {
// //       final tempOrigin = _routeOriginText;
// //       final tempOriginLatLng = _routeOrigin;
// //       final tempDestination = _routeDestinationText;
// //       final tempDestinationLatLng = _routeDestination;

// //       _routeOriginText = tempDestination;
// //       _routeOrigin = tempDestinationLatLng;
// //       _routeDestinationText = tempOrigin;
// //       _routeDestination = tempOriginLatLng;

// //       _routeOriginSuggestions = [];
// //       _routeDestinationSuggestions = [];
// //     });

// //     _fetchRoutesAndDurations();
// //   }

// //   void _onTravelModeSelected(RouteTravelMode mode) {
// //     setState(() {
// //       _selectedTravelMode = mode;
// //     });

// //     if (mode == RouteTravelMode.shuttle) {
// //       _fetchShuttleInfo();
// //       return;
// //     }

// //     if (_routePointsByMode.containsKey(mode.apiValue)) {
// //       _applySelectedModeRoute(animateCamera: false);
// //       return;
// //     }

// //     _fetchRoutesAndDurations();
// //   }


// //   ///shuttle stop marker icon
// //   Future<void> _createShuttleStopIcon() async {
// //   _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
// //     const ImageConfiguration(size: Size(600, 600)),
// //     'assets/images/shuttle_icon.png',
// //   );
// // }

// //   ///walking time + 4 next buses 
// //   Future<void> _fetchShuttleInfo() async {
// //     final origin = _routeOrigin ?? _currentLocation;

// //     if (origin == null) {
// //       setState(() {
// //         _routeDurations['shuttle'] = '–';
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _shuttleNextBuses = [];
// //       _shuttleWalkingMinutes = null;
// //     });

// //     try {
// //       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
// //       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

// //       int walkingSeconds = 0;
// //       List<LatLng> walkPoints = [];

// //       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
// //         origin: origin,
// //         destination: stopLatLng,
// //         mode: 'walking',
// //       );

// //       if (walkRoute != null) {
// //         walkingSeconds = walkRoute.durationSeconds ?? 0;
// //         walkPoints = walkRoute.points;
// //       }

// //       final walkingMinutes = (walkingSeconds / 60).ceil();

// //       final buses = ConcordiaShuttleService.getNextDepartures(
// //         fromStop: nearestStop,
// //         now: DateTime.now(),
// //         count: 4,
// //         walkingDuration: Duration(seconds: walkingSeconds),
// //       );

// //       String shuttleDurationLabel;
// //       if (!ConcordiaShuttleService.isInService()) {
// //         shuttleDurationLabel = 'No service';
// //       } else if (buses.isNotEmpty) {
// //         shuttleDurationLabel = buses.first.statusLabel;
// //       } else {
// //         shuttleDurationLabel = '–';
// //       }

// //       if (walkPoints.isNotEmpty) {
// //         setState(() {
// //           _routePolylines = {
// //             Polyline(
// //               polylineId: const PolylineId('shuttle_walk'),
// //               points: walkPoints,
// //               color: const Color(0xFF76263D),
// //               width: 5,
// //               patterns: [PatternItem.dot, PatternItem.gap(10)],
// //             ),
// //           };
// //         });

// //         if (_mapController != null) {
// //           final bounds = _calculateBounds([...walkPoints, stopLatLng]);
// //           _mapController!
// //               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
// //         }
// //       } else {
// //         setState(() {
// //           _routePolylines = {};
// //         });
// //       }

// //       if (!mounted) return;
// //       setState(() {
// //         _shuttleNearestStop = nearestStop;
// //         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
// //         _shuttleNextBuses = buses;
// //         _routeDurations['shuttle'] = shuttleDurationLabel;
// //       });
// //     } catch (e) {
// //       print('Error fetching shuttle info: $e');
// //       if (!mounted) return;
// //       setState(() {
// //         _routeDurations['shuttle'] = '–';
// //       });
// //     }
// //   }

// //   //open full day schedule 
// //   void _showShuttleScheduleModal() {
// //     showModalBottomSheet<void>(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (_) =>
// //           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
// //     );
// //   }


// //   Future<void> _onRouteOriginChanged(String query) async {
// //     if (query.trim().isEmpty) {
// //       setState(() {
// //         _routeOriginSuggestions = [];
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routeOriginSuggestions = [];
// //     });

// //     _routeDebounceTimer?.cancel();
// //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       try {
// //         print('[DEBUG] Searching for origin: $query');
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         print('[DEBUG] Found ${suggestions.length} origin suggestions');
// //         if (mounted) {
// //           setState(() {
// //             _routeOriginSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error getting origin suggestions: $e');
// //       }
// //     });
// //   }

// //   Future<void> _onRouteDestinationChanged(String query) async {
// //     if (query.trim().isEmpty) {
// //       setState(() {
// //         _routeDestinationSuggestions = [];
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _routeDestinationSuggestions = [];
// //     });

// //     _routeDebounceTimer?.cancel();
// //     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       try {
// //         print('[DEBUG] Searching for destination: $query');
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         print('[DEBUG] Found ${suggestions.length} destination suggestions');
// //         if (mounted) {
// //           setState(() {
// //             _routeDestinationSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error getting destination suggestions: $e');
// //       }
// //     });
// //   }

// //   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
// //     print(
// //       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
// //     );
// //     LatLng? newOrigin;
// //     String displayText = suggestion.name;
// //     String? buildingCode;

// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       print('[DEBUG] Handling Concordia building');
// //       final building = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       newOrigin = building?.center;
// //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// //       buildingCode = suggestion.buildingName!.code;
// //       print('[DEBUG] Concordia building origin: $newOrigin');
// //     } else if (suggestion.placeId != null) {
// //       print(
// //         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
// //       );
// //       try {
// //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //           suggestion.placeId!,
// //         );
// //         print('[DEBUG] Place details result: $placeDetails');
// //         if (placeDetails != null) {
// //           newOrigin = placeDetails.location;
// //           buildingCode = null;
// //           print('[DEBUG] Non-Concordia origin location: $newOrigin');
// //         } else {
// //           print(
// //             '[ERROR] Place details returned null for ${suggestion.placeId}',
// //           );
// //         }
// //       } catch (e) {
// //         print('[ERROR] Error fetching place details: $e');
// //         return;
// //       }
// //     }

// //     if (newOrigin != null) {
// //       print('[DEBUG] Updating route origin state');
// //       print('[DEBUG] New origin building code: $buildingCode');
// //       setState(() {
// //         _routeOrigin = newOrigin;
// //         _routeOriginText = displayText;
// //         _routeOriginSuggestions = [];
// //         _routeOriginBuildingCode = buildingCode;
// //         _originRoomController.clear();
// //       });
// //       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
// //       await _fetchRoutesAndDurations();
// //     } else {
// //       print('[ERROR] Could not determine origin location');
// //     }
// //   }

// //   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
// //     LatLng? newDestination;
// //     String displayText = suggestion.name;
// //     String? buildingCode;

// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       final building = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       newDestination = building?.center;
// //       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
// //       buildingCode = suggestion.buildingName!.code;
// //     } else if (suggestion.placeId != null) {
// //       try {
// //         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //           suggestion.placeId!,
// //         );
// //         if (placeDetails != null) {
// //           newDestination = placeDetails.location;
// //           buildingCode = null;
// //         }
// //       } catch (e) {
// //         print('Error fetching place details: $e');
// //         return;
// //       }
// //     }

// //     if (newDestination != null) {
// //       print('[DEBUG] Updating route destination state');
// //       print('[DEBUG] New destination building code: $buildingCode');
// //       setState(() {
// //         _routeDestination = newDestination;
// //         _routeDestinationText = displayText;
// //         _routeDestinationSuggestions = [];
// //         _routeDestinationBuildingCode = buildingCode;
// //         _destinationRoomController.clear();
// //       });
// //       await _fetchRoutesAndDurations();
// //     }
// //   }

// //   void _hideBuildingPopup() {
// //     if (_selectedBuildingPoly == null) return;

// //     _clearSelectedBuilding();
// //   }

// //   Future<void> _onSearchSubmitted(String query) async {
// //     if (query.trim().isEmpty) return;

// //     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

// //     if (concordiaBuilding != null) {
// //       _onBuildingTapped(concordiaBuilding);
// //       return;
// //     }

// //     final results = await BuildingSearchService.searchWithGooglePlaces(
// //       query,
// //       userLocation: _currentLocation,
// //     );

// //     if (results.isNotEmpty) {
// //       SearchResult? selectedResult;

// //       for (final result in results) {
// //         if (!result.isConcordiaBuilding) {
// //           selectedResult = result;
// //           break;
// //         }
// //       }

// //       if (selectedResult == null && results.isNotEmpty) {
// //         selectedResult = results.first;
// //       }

// //       if (selectedResult != null) {
// //         if (selectedResult.isConcordiaBuilding &&
// //             selectedResult.buildingPolygon != null) {
// //           _onBuildingTapped(selectedResult.buildingPolygon!);
// //         } else {
// //           _onPlaceSelected(selectedResult);
// //         }
// //       }
// //     } else {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('"$query" not found'),
// //           duration: const Duration(seconds: 2),
// //           backgroundColor: const Color(0xFF800020),
// //         ),
// //       );
// //       _searchController.clear();
// //     }
// //   }

// //   void _onPlaceSelected(SearchResult result) {
// //     final controller = _mapController;
// //     if (controller == null) return;

// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _selectedSearchResult = result;
// //     });

// //     _searchController.value = TextEditingValue(
// //       text: result.name,
// //       selection: TextSelection.collapsed(offset: result.name.length),
// //     );

// //     if (result.isConcordiaBuilding) {
// //       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('${result.name} is a Concordia building'),
// //           duration: const Duration(seconds: 3),
// //           backgroundColor: const Color(0xFF800020),
// //         ),
// //       );
// //     } else {
// //       if (_currentLocation == null) {
// //         controller.animateCamera(
// //           CameraUpdate.newLatLngZoom(result.location, 18),
// //         );
// //         if (!mounted) return;
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('${result.name} is not a Concordia building'),
// //             duration: const Duration(seconds: 2),
// //             backgroundColor: Colors.grey[700],
// //           ),
// //         );
// //       } else {
// //         _enterRoutePreviewForPlace(result);
// //       }
// //     }
// //   }

// //   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
// //     if (_currentLocation == null) return;

// //     print(
// //       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
// //     );

// //     setState(() {
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _showRoutePreview = true;
// //       _routeOrigin = _currentLocation;
// //       _routeDestination = place.location;
// //       _routeOriginText = currentLocationTag;
// //       _routeDestinationText = place.name;
// //       _selectedSearchResult = place;
// //     });

// //     print(
// //       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
// //     );

// //     await _fetchRoutesAndDurations();
// //   }

// //   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
// //     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
// //       final buildingPolygon = BuildingSearchService.searchBuilding(
// //         suggestion.buildingName!.code,
// //       );
// //       if (buildingPolygon == null) return;
// //       _onBuildingTapped(buildingPolygon);
// //     } else if (suggestion.placeId != null) {
// //       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
// //         suggestion.placeId!,
// //       );
// //       if (placeDetails != null) {
// //         final concordiaBuilding = BuildingSearchService.searchBuilding(
// //           suggestion.name,
// //         );

// //         if (concordiaBuilding != null) {
// //           _onBuildingTapped(concordiaBuilding);
// //         } else {
// //           final searchResult = SearchResult.fromGooglePlace(
// //             name: placeDetails.name,
// //             address: placeDetails.formattedAddress,
// //             location: placeDetails.location,
// //             isConcordiaBuilding: false,
// //             placeId: placeDetails.placeId,
// //           );
// //           _onPlaceSelected(searchResult);
// //         }
// //       }
// //     }
// //   }

// //   Set<Polygon> _createBuildingPolygons() {
// //     const burgundy = Color(0xFF800020);
// //     const selectedBlue = Color(0xFF7F83C3);

// //     final polys = <Polygon>{};

// //     for (final b in buildingPolygons) {
// //       final isCurrent = _currentBuildingPoly?.code == b.code;
// //       final isSelected = _selectedBuildingPoly?.code == b.code;

// //       final strokeColor = isSelected
// //           ? selectedBlue.withOpacity(0.95)
// //           : isCurrent
// //           ? Colors.blue.withOpacity(0.8)
// //           : burgundy.withOpacity(0.55);

// //       final fillColor = isSelected
// //           ? selectedBlue.withOpacity(0.25)
// //           : isCurrent
// //           ? Colors.blue.withOpacity(0.25)
// //           : burgundy.withOpacity(0.22);

// //       final strokeWidth = isSelected
// //           ? 3
// //           : isCurrent
// //           ? 3
// //           : 2;
// //       final zIndex = isSelected
// //           ? 3
// //           : isCurrent
// //           ? 2
// //           : 1;

// //       polys.add(
// //         Polygon(
// //           polygonId: PolygonId('poly_${b.code}'),
// //           points: b.points,
// //           strokeWidth: strokeWidth,
// //           strokeColor: strokeColor,
// //           fillColor: fillColor,
// //           zIndex: zIndex,
// //           consumeTapEvents: true,
// //           onTap: () => _onBuildingTapped(b),
// //         ),
// //       );
// //     }

// //     return polys;
// //   }

// //   List<Widget> _createBuildingGestureDetectors() {
// //     final detectors = <Widget>[];

// //     for (final building in buildingPolygons) {
// //       detectors.add(
// //         Positioned(
// //           left: 0,
// //           top: 0,
// //           child: GestureDetector(
// //             key: Key('building_detector_${building.code}'),
// //             onTap: () => _onBuildingTapped(building),
// //             child: Container(
// //               width: 100,
// //               height: 100,
// //               color: Colors.transparent,
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     return detectors;
// //   }

// //   @override
// //   void initState() {
// //     super.initState();

// //     _selectedCampus = widget.initialCampus;

// //     _lastCameraTarget = widget.initialCampus == Campus.loyola
// //         ? concordiaLoyola
// //         : concordiaSGW;

// //     _createBlueDotIcon();
// //     _createShuttleStopIcon(); // NEW
// //     _startLocationUpdates();
// //     _determineUserLocationAndBuilding().then((_) {
// //       _startLocationUpdates();
// //     });

// //     _searchController.addListener(_onSearchChanged);
// //     // Clear destination room marker when room input changes
// //     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
// //     _determineUserLocationAndBuilding();
// //   }

// //   Future<void> _determineUserLocationAndBuilding() async {
// //     // Get user's current location
// //     final position = await Geolocator.getCurrentPosition();
// //     _currentLocation = LatLng(position.latitude, position.longitude);

// //     // Check which building polygon contains the user
// //     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

// //     setState(() {
// //       _currentBuildingCode = buildingAtLocation?.code;
// //     });
// //   }

// //   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
// //     for (final building in buildingPolygons) {
// //       if (_isPointInPolygon(location, building.points)) {
// //         return building;
// //       }
// //     }
// //     return null;
// //   }

// //   void _onDestinationRoomTextChanged() {
// //     if (_destinationRoomMarker == null) return;

// //     setState(() {
// //       _destinationRoomMarker = null;
// //     });
// //   }

// //   void _onSearchChanged() {
// //     _debounceTimer?.cancel();

// //     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
// //       final query = _searchController.text;
// //       try {
// //         final suggestions = await BuildingSearchService.getCombinedSuggestions(
// //           query,
// //           userLocation: _currentLocation,
// //         );
// //         if (mounted) {
// //           setState(() {
// //             _searchSuggestions = suggestions;
// //           });
// //         }
// //       } catch (e) {
// //         print('Error getting search suggestions: $e');
// //         if (mounted) {
// //           setState(() {
// //             _searchSuggestions = BuildingSearchService.getSuggestions(
// //               query,
// //             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
// //           });
// //         }
// //       }
// //     });
// //   }

// //   Future<void> _createBlueDotIcon() async {
// //     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
// //       BitmapDescriptor.hueAzure,
// //     );
// //   }

// //   Future<void> _startLocationUpdates() async {
// //     print('[DEBUG] Starting location updates...');

// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     print('[DEBUG] Location service enabled: $serviceEnabled');

// //     if (!serviceEnabled) {
// //       print('[ERROR] Location services are disabled');
// //       return;
// //     }

// //     LocationPermission permission = await Geolocator.checkPermission();
// //     print('[DEBUG] Initial permission status: $permission');

// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       print('[DEBUG] Permission after request: $permission');
// //       if (permission == LocationPermission.denied) {
// //         print('[ERROR] Location permission denied by user');
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       print('[ERROR] Location permission denied forever');
// //       return;
// //     }

// //     try {
// //       print('[DEBUG] Attempting to get current position...');
// //       final position = await Geolocator.getCurrentPosition(
// //         locationSettings: const LocationSettings(
// //           accuracy: LocationAccuracy.high,
// //           timeLimit: Duration(seconds: 10),
// //         ),
// //       );
// //       final newLatLng = LatLng(position.latitude, position.longitude);

// //       print(
// //         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
// //       );
// //       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

// //       if (!mounted) return;
// //       setState(() {
// //         _currentLocation = newLatLng;
// //         _currentCampus = detectCampus(newLatLng);
// //         _currentBuildingPoly = detectBuildingPoly(newLatLng);
// //       });

// //       print('[DEBUG] Current campus: $_currentCampus');
// //       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

// //       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
// //     } catch (e) {
// //       print('[ERROR] Failed to get current position: $e');
// //       print(
// //         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
// //       );
// //     }

// //     _posSub =
// //         Geolocator.getPositionStream(
// //           locationSettings: const LocationSettings(
// //             accuracy: LocationAccuracy.best,
// //             distanceFilter: 5,
// //           ),
// //         ).listen((position) {
// //           final newLatLng = LatLng(position.latitude, position.longitude);
// //           print(
// //             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
// //           );

// //           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

// //           if (!mounted) return;
// //           setState(() {
// //             _currentLocation = newLatLng;
// //             _currentCampus = detectCampus(newLatLng);
// //             _currentBuildingPoly = detectBuildingPoly(newLatLng);
// //             _currentBuildingCode = buildingAtLocation?.code;
// //           });

// //           if (_isNavigating) {
// //             _maybeAdvanceNavigationStep(newLatLng);
// //           }
// //           if (_navigationFollowUser) {
// //             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
// //           }
// //         });
// //   }

// //   Set<Marker> _createMarkers() {
// //     final markers = <Marker>{};
// //     // Add current location marker
// //     if (_currentLocation != null) {
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('current_location'),
// //           position: _currentLocation!,
// //           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
// //           anchor: const Offset(0.5, 0.5),
// //           flat: true,
// //           zIndex: 999,
// //         ),
// //       );
// //     }

// //     // Add destination room marker only when indoor map is shown
// //     if (_destinationRoomMarker != null && _showIndoor) {
// //       markers.add(_destinationRoomMarker!);
// //     }
// //     final shuttleIcon = _shuttleStopIcon;
// //     if (shuttleIcon != null) {
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('shuttle_stop_sgw'),
// //           position: shuttleStopSGW,
// //           icon: shuttleIcon,
// //           infoWindow: const InfoWindow(
// //             title: 'Concordia Shuttle — SGW',
// //             snippet: 'Hall Building stop',
// //           ),
// //           onTap: () {
// //             if (_showRoutePreview) {
// //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// //               _fetchShuttleInfo();
// //             }
// //           },
// //         ),
// //       );
// //       markers.add(
// //         Marker(
// //           markerId: const MarkerId('shuttle_stop_loyola'),
// //           position: shuttleStopLoyola,
// //           icon: shuttleIcon,
// //           infoWindow: const InfoWindow(
// //             title: 'Concordia Shuttle — Loyola',
// //             snippet: 'Loyola campus stop',
// //           ),
// //           onTap: () {
// //             if (_showRoutePreview) {
// //               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
// //               _fetchShuttleInfo();
// //             }
// //           },
// //         ),
// //       );
// //     }

// //     if (_showRoutePreview) {
// //       if (_routeDestination != null) {
// //         markers.add(
// //           Marker(
// //             markerId: const MarkerId('route_destination'),
// //             position: _routeDestination!,
// //             infoWindow: InfoWindow(title: _routeDestinationText),
// //             icon: BitmapDescriptor.defaultMarkerWithHue(
// //               BitmapDescriptor.hueRed,
// //             ),
// //           ),
// //         );
// //       }
// //     }

// //     return markers;
// //   }

// //   Set<Circle> _createCircles() {
// //     final circles = <Circle>{};

// //     if (_currentLocation == null) return {};

// //     circles.add(
// //       Circle(
// //         circleId: const CircleId('current_location_accuracy'),
// //         center: _currentLocation!,
// //         radius: 20,
// //         fillColor: Colors.blue.withOpacity(0.1),
// //         strokeColor: Colors.blue.withOpacity(0.3),
// //         strokeWidth: 1,
// //       ),
// //     );

// //     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
// //       final segments = _routeSegmentsByMode['transit'] ?? const [];
// //       final seen = <String>{};

// //       for (final segment in segments) {
// //         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
// //           continue;
// //         }
// //         if (segment.points.isEmpty) {
// //           continue;
// //         }

// //         final endpoints = [segment.points.first, segment.points.last];
// //         for (final point in endpoints) {
// //           final key =
// //               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
// //           if (!seen.add(key)) {
// //             continue;
// //           }

// //           circles.add(
// //             Circle(
// //               circleId: CircleId('transit_stop_$key'),
// //               center: point,
// //               radius: 15,
// //               fillColor: Colors.white,
// //               strokeColor: const Color(0xFF76263D),
// //               strokeWidth: 2,
// //             ),
// //           );
// //         }
// //       }
// //     }

// //     return circles;
// //   }

// //   NavigationStep? _getCurrentNavStep() {
// //     final key = _navModeKey;
// //     if (key == null) return null;

// //     final steps = _routeStepsByMode[key] ?? const [];
// //     if (steps.isEmpty) return null;

// //     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
// //     return steps[_navStepIndex];
// //   }

// //   void _switchCampus(Campus newCampus) {
// //     LatLng targetLocation;

// //     switch (newCampus) {
// //       case Campus.sgw:
// //         targetLocation = concordiaSGW;
// //         break;
// //       case Campus.loyola:
// //         targetLocation = concordiaLoyola;
// //         break;
// //       case Campus.none:
// //         return;
// //     }

// //     _lastCameraTarget = targetLocation;
// //     _mapController?.animateCamera(
// //       CameraUpdate.newLatLngZoom(targetLocation, 16),
// //     );

// //     setState(() {
// //       _selectedCampus = newCampus;
// //       _selectedBuildingPoly = null;
// //       _selectedBuildingCenter = null;
// //       _anchorOffset = null;
// //       _cameraMoving = false;
// //       _searchController.clear();
// //     });
// //   }

// //   Offset? _computePopupPosition(BuildContext context) {
// //   final screen = MediaQuery.of(context).size;
// //   final topPad = MediaQuery.of(context).padding.top;

// //   final anchor = widget.debugAnchorOffset ?? _anchorOffset;
// //   if (anchor == null || _cameraMoving) return null;

// //   final ax = anchor.dx;
// //   final ay = anchor.dy;

// //   final inView =
// //       ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
// //   if (!inView) return null;

// //   double left = ax - (_popupW / 2);
// //   double top = ay - (_popupH / 2);

// //   const margin = 8.0;
// //   final minLeft = margin;
// //   final maxLeft = screen.width - _popupW - margin;
// //   final minTop = topPad + margin;
// //   final maxTop = screen.height - _popupH - margin;

// //   if (left < minLeft) left = minLeft;
// //   if (left > maxLeft) left = maxLeft;
// //   if (top < minTop) top = minTop;
// //   if (top > maxTop) top = maxTop;

// //   return Offset(left, top);
// // }

// //   Future<void> _onDestinationRoomSubmitted(
// //     String buildingCode,
// //     String roomCode,
// //   ) async {
// //     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

// //     try {
// //       final repo = IndoorMapRepository();
// //       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

// //       if (roomLocation == null) {
// //         print('[ERROR] Could not find location for room $roomCode');
// //         return;
// //       }
// //       print('[DEBUG] Room location found: $roomLocation');
// //       // Create marker at room location
// //       final marker = Marker(
// //         markerId: const MarkerId('destination_room'),
// //         position: roomLocation,
// //         infoWindow: InfoWindow(title: 'Room $roomCode'),
// //         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
// //       );

// //       // Update state with the new marker
// //       if (!mounted) return;
// //       setState(() {
// //         _destinationRoomMarker = marker;
// //       });

// //       print('[DEBUG] Destination room marker placed at $roomLocation');
// //     } catch (e) {
// //       print('[ERROR] Error processing destination room: $e');
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('Error: $e'),
// //           backgroundColor: const Color(0xFFE53935),
// //         ),
// //       );
// //     }
// //   }

// //   @override
// // Widget build(BuildContext context) {
// //   final LatLng initialTarget =
// //       widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

// //   final Campus labelCampus =
// //       _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

// //   final String campusLabel = labelCampus == Campus.sgw
// //       ? 'SGW'
// //       : labelCampus == Campus.loyola
// //           ? 'Loyola'
// //           : '';

// //   final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
// //   final popupPos = _computePopupPosition(context);

// //   return Scaffold(
// //     body: Stack(
// //       children: [
// //         if (widget.debugDisableMap)
// //           const SizedBox.expand()
// //         else
// //           OutdoorMapView(
// //             initialTarget: initialTarget,
// //             showIndoorStyle: _showIndoor,
// //             indoorMapStyle: _indoorMapStyle,
// //             onMapCreated: (c) => _mapController = c,
// //             onCameraMove: (pos) {
// //               _lastCameraTarget = pos.target;
// //               if (_selectedBuildingCenter != null) _schedulePopupUpdate();
// //             },
// //             onCameraMoveStarted: () {
// //               if (_selectedBuildingCenter == null) return;
// //               setState(() => _cameraMoving = true);
// //             },
// //             onCameraIdle: () {
// //               _syncToggleWithCameraCenter();
// //               if (_selectedBuildingCenter == null) return;
// //               setState(() => _cameraMoving = false);
// //               _updatePopupOffset();
// //             },
// //             markers: {
// //               ..._createMarkers(),
// //               ..._roomLabelMarkers,
// //             },
// //             circles: _createCircles(),
// //             polygons: {
// //               ..._createBuildingPolygons(),
// //               ..._indoorPolygons,
// //             },
// //             polylines: _routePolylines,
// //           ),

// //           if (_isNavigating)
// //             Positioned(
// //               top: 80,
// //               left: 0,
// //               right: 0,
// //               child: PointerInterceptor(
// //                 child: NavigationNextStepHeader(
// //                   modeLabel: _selectedTravelMode.label,
// //                   nextStep: _getCurrentNavStep(),
// //                   onStop: _stopNavigation,
// //                   onShowSteps: _openStepsForSelectedMode,
// //                 ),
// //               ),
// //             ),
// //           if (!_showRoutePreview && !_isNavigating)
// //             Positioned(
// //               top: 65,
// //               left: 20,
// //               right: 20,
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   MapSearchBar(
// //                     key: const Key('destination_search_bar'),
// //                     campusLabel: campusLabel,
// //                     controller: _searchController,
// //                     onSubmitted: _onSearchSubmitted,
// //                     suggestions: _searchSuggestions,
// //                     onSuggestionSelected: _onSuggestionSelected,
// //                     onFocus: _hideBuildingPopup,
// //                   ),
// //                   if (_showIndoor && _indoorFloors.isNotEmpty) ...[
// //                     const SizedBox(height: 10),
// //                     Align(
// //                       alignment: Alignment.centerRight,
// //                       child: PointerInterceptor(
// //                         child: IntrinsicWidth(
// //                           child: Container(
// //                             height: 40,
// //                             padding:
// //                                 const EdgeInsets.symmetric(horizontal: 12),
// //                             decoration: BoxDecoration(
// //                               color: const Color(0xFF8B1D3B),
// //                               borderRadius: BorderRadius.circular(20),
// //                               boxShadow: [
// //                                 BoxShadow(
// //                                   color: Colors.black.withOpacity(0.25),
// //                                   blurRadius: 8,
// //                                   offset: const Offset(0, 3),
// //                                 ),
// //                               ],
// //                             ),
// //                             child: Center(
// //                               child: DropdownButtonHideUnderline(
// //                                 child: DropdownButton<String>(
// //                                   value: _selectedIndoorFloorAsset ??
// //                                       _indoorFloors.first.assetPath,
// //                                   isDense: true,
// //                                   dropdownColor: const Color(0xFF8B1D3B),
// //                                   icon: const Icon(
// //                                     Icons.keyboard_arrow_down,
// //                                     color: Colors.white,
// //                                   ),
// //                                   style: const TextStyle(
// //                                     color: Colors.white,
// //                                     fontSize: 15,
// //                                     fontWeight: FontWeight.w600,
// //                                   ),
// //                                   items: _indoorFloors
// //                                       .map(
// //                                         (f) => DropdownMenuItem<String>(
// //                                           value: f.assetPath,
// //                                           child: Text(
// //                                             f.label,
// //                                             style: const TextStyle(
// //                                                 color: Colors.white),
// //                                           ),
// //                                         ),
// //                                       )
// //                                       .toList(),
// //                                   onChanged: (asset) async {
// //                                     if (asset == null) return;
// //                                     await _loadIndoorFloor(asset);
// //                                   },
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //           if ((widget.debugSelectedBuilding ?? _selectedBuildingPoly) != null &&
// //               popupLeft != null &&
// //               popupTop != null)
// //             Positioned(
// //               left: popupLeft,
// //               top: popupTop,
// //               child: PointerInterceptor(
// //                 child: BuildingInfoPopup(
// //                   title:
// //                       '${buildingInfoByCode[(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code]?.name ?? (widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.name} - ${(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code}',
// //                   description:
// //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// //                                   _selectedBuildingPoly)!
// //                               .code]
// //                           ?.description ??
// //                       'No description available.',
// //                   accessibility:
// //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// //                                   _selectedBuildingPoly)!
// //                               .code]
// //                           ?.accessibility ??
// //                       false,
// //                   facilities:
// //                       buildingInfoByCode[(widget.debugSelectedBuilding ??
// //                                   _selectedBuildingPoly)!
// //                               .code]
// //                           ?.facilities ??
// //                       const [],
// //                   onMore: () {
// //                     final link =
// //                         widget.debugLinkOverride ??
// //                         (buildingInfoByCode[(widget.debugSelectedBuilding ??
// //                                         _selectedBuildingPoly)!
// //                                     .code]
// //                                 ?.link ??
// //                             '');
// //                     _openLink(link);
// //                   },
// //                   onClose: _closePopup,
// //                   isLoggedIn: widget.isLoggedIn,
// //                   onIndoorMap: _toggleIndoorMap,
// //                   onGetDirections: _getDirections,
// //                 ),
// //               ),
// //             ),

// //         if (_showRoutePreview && !_isNavigating)
// //   Positioned(
// //     top: 80,
// //     left: 0,
// //     right: 0,
// //     child: RoutePreviewPanel(
// //       originText: _routeOriginText,
// //       destinationText: _routeDestinationText,
// //       onClose: _closeRoutePreview,
// //       onSwitch: _switchOriginDestination,
// //       onOriginChanged: _onRouteOriginChanged,
// //       onDestinationChanged: _onRouteDestinationChanged,
// //       onOriginSelected: _onRouteOriginSelected,
// //       onDestinationSelected: _onRouteDestinationSelected,
// //       originSuggestions: _routeOriginSuggestions,
// //       destinationSuggestions: _routeDestinationSuggestions,

// //       originRoomController: _originRoomController,
// //       destinationRoomController: _destinationRoomController,
// //       onOriginRoomSubmitted: _onOriginRoomSubmitted,
// //       onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
// //       originBuildingCode: _routeOriginBuildingCode,
// //       destinationBuildingCode: _routeDestinationBuildingCode,
// //       isConcordiaBuilding: (buildingCode) {
// //         return buildingPolygons.any(
// //           (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
// //         );
// //       },
// //     ),
// //   ),

// //           if (_showRoutePreview)
// //             Positioned(
// //               bottom: 25,
// //               left: 0,
// //               right: 0,
// //               child: PointerInterceptor(
// //                 child: Center(
// //                   child: RouteTravelModeBar(
// //                     selectedTravelMode: _selectedTravelMode,
// //                     onTravelModeSelected: _onTravelModeSelected,
// //                     modeDurations: _routeDurations,
// //                     isLoadingDurations: _isLoadingRouteData,
// //                     onClose: _closeRoutePreview,
// //                     onStart: _startNavigation,
// //                     isNavigating: _isNavigating,
// //                     onShowSteps: _openStepsForSelectedMode,
// //                     transitDetails: _buildTransitDetailItems(),
// //                     modeDistances: _routeDistances,
// //                     modeArrivalTimes: _routeArrivalTimes,
// //                   ),
// //                 ),
// //               ),
// //             ),

// //         OutdoorBottomBar(
// //           showRoutePreview: _showRoutePreview,
// //           isNavigating: _isNavigating,
// //           selectedCampus: _selectedCampus,
// //           onCampusChanged: _switchCampus,
// //           selectedTravelMode: _selectedTravelMode,
// //           onTravelModeSelected: _onTravelModeSelected,
// //           routeDurations: _routeDurations,
// //           routeDistances: _routeDistances,
// //           routeArrivalTimes: _routeArrivalTimes,
// //           isLoadingRouteData: _isLoadingRouteData,
// //           onCloseRoutePreview: _closeRoutePreview,
// //           onStartNavigation: _startNavigation,
// //           onShowSteps: _openStepsForSelectedMode,
// //           transitDetails: _buildTransitDetailItems(),
// //         ),

// //           // Invisible gesture detectors for building polygons (for testing)
// //           ..._createBuildingGestureDetectors(),
// //         ],
// //       ),
// //     );
// //   }

// //   Set<Polygon> _geoJsonToPolygons(Map<String, dynamic> geojson) {
// //     final features = (geojson['features'] as List).cast<dynamic>();

// //     final polygons = <Polygon>{};

// //     for (final f in features) {
// //       final feature = f as Map<String, dynamic>;
// //       final geometry = feature['geometry'] as Map<String, dynamic>;
// //       if (geometry['type'] != 'Polygon') continue;

// //       final rings = geometry['coordinates'] as List;
// //       if (rings.isEmpty) continue;

// //       final outer = rings[0] as List;

// //       final points = outer.map<LatLng>((p) {
// //         final coords = p as List;
// //         final lng = (coords[0] as num).toDouble();
// //         final lat = (coords[1] as num).toDouble();
// //         return LatLng(lat, lng); // GeoJSON is [lng,lat]
// //       }).toList();

// //       if (points.length < 3) continue;

// //       final props =
// //           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
// //       final id = (props['ref'] ?? polygons.length).toString();

// //       // Determine fill color based on feature type
// //       Color fillColor;
// //       if (props['escalators'] == 'yes') {
// //         fillColor = Colors.green; // Escalator = green
// //       } else if (props['highway'] == 'elevator') {
// //         fillColor = Colors.orange; // Elevator = orange
// //       } else if (props['highway'] == 'steps') {
// //         fillColor = Colors.pink; // Steps = pink
// //       } else if (props['amenity'] == 'toilets') {
// //         fillColor = Colors.blue; // Toilets = blue
// //       } else if (props['indoor'] == 'corridor') {
// //         fillColor = const Color.fromARGB(
// //           255,
// //           232,
// //           122,
// //           149,
// //         ); // Corridor = lighter red
// //       } else {
// //         fillColor = const Color(0xFF800020); // Default room = dark red
// //       }

// //       polygons.add(
// //         Polygon(
// //           polygonId: PolygonId('indoor-$id'),
// //           points: points,
// //           strokeWidth: 2,
// //           strokeColor: Colors.black,
// //           fillColor: fillColor.withOpacity(1.0),
// //           zIndex: 20,
// //         ),
// //       );
// //     }

// //     return polygons;
// //   }

// //   Future<BitmapDescriptor> _createTextBitmap(
// //     String text, {
// //     double fontSize = 10,
// //   }) async {
// //     final painter = TextPainter(
// //       text: TextSpan(
// //         text: text,
// //         style: TextStyle(
// //           color: Colors.white,
// //           fontSize: fontSize,
// //           fontWeight: FontWeight.bold,
// //         ),
// //       ),
// //       textDirection: ui.TextDirection.ltr,
// //     );
// //     painter.layout();

// //     final width = painter.width.ceil();
// //     final height = painter.height.ceil();

// //     final recorder = ui.PictureRecorder();
// //     final canvas = Canvas(
// //       recorder,
// //       Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
// //     );

// //     painter.paint(canvas, Offset.zero);

// //     final picture = recorder.endRecording();
// //     ui.Image? img;
// //     ByteData? byteData;
// //     try {
// //       img = await picture.toImage(width, height);
// //       byteData = await img.toByteData(format: ui.ImageByteFormat.png);
// //     } finally {
// //       img?.dispose();
// //       picture.dispose();
// //     }
// //     final Uint8List bytes = byteData!.buffer.asUint8List();

// //     return BitmapDescriptor.bytes(bytes);
// //   }

// //   /// Creates text labels at the center of each room polygon
// //   Future<Set<Marker>> _createRoomLabels(Map<String, dynamic> geojson) async {
// //     final features = (geojson['features'] as List).cast<dynamic>();
// //     final markers = <Marker>{};
// //     int index = 0;

// //     for (final f in features) {
// //       final feature = f as Map<String, dynamic>;
// //       final geometry = feature['geometry'] as Map<String, dynamic>;
// //       final props =
// //           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

// //       if (geometry['type'] != 'Polygon') continue;
// //       if (props['ref'] == null) continue;

// //       final rings = geometry['coordinates'] as List;
// //       if (rings.isEmpty) continue;
// //       final outer = rings[0] as List;

// //       final points = outer.map<LatLng>((p) {
// //         final coords = p as List;
// //         final lng = (coords[0] as num).toDouble();
// //         final lat = (coords[1] as num).toDouble();
// //         return LatLng(lat, lng);
// //       }).toList();

// //       if (points.length < 3) continue;

// //       // Skip very small polygons where text won't fit
// //       final area = _polygonArea(points);
// //       if (area < 1e-10) continue;

// //       final center = _polygonCenter(points);
// //       final ref = props['ref'].toString();

// //       // Choose font size based on polygon area
// //       final double fontSize = area > 5e-8 ? 10 : 8;
// //       final icon = await _createTextBitmap(ref, fontSize: fontSize);

// //       markers.add(
// //         Marker(
// //           markerId: MarkerId('room-label-${index++}-$ref'),
// //           position: center,
// //           icon: icon,
// //           anchor: const Offset(0.5, 0.5),
// //           flat: true,
// //           zIndex: 30,
// //           consumeTapEvents: false,
// //           infoWindow: InfoWindow.noText,
// //         ),
// //       );
// //     }

// //     return markers;
// //   }

// //   static const String _indoorMapStyle = '''
// //   [
// //     {
// //       "featureType": "poi",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "poi.school",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "poi.business",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     },
// //     {
// //       "featureType": "transit",
// //       "stylers": [
// //         { "visibility": "off" }
// //       ]
// //     }
// //   ]
// //   ''';

// //   @override
// //   void dispose() {
// //     _posSub?.cancel();
// //     _popupDebounce?.cancel();
// //     _debounceTimer?.cancel();
// //     _routeDebounceTimer?.cancel();
// //     _mapController?.dispose();
// //     _searchController.removeListener(_onSearchChanged);
// //     _searchController.dispose();
// //     _originRoomController.dispose();
// //     _destinationRoomController.dispose();
// //     super.dispose();
// //   }
// // }


// // class _ShuttleScheduleSheet extends StatelessWidget {
// //   final String nearestStop;

// //   const _ShuttleScheduleSheet({required this.nearestStop});

// //   @override
// //   Widget build(BuildContext context) {
// //     const burgundy = Color(0xFF76263D);
// //     final today = DateTime.now();
// //     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
// //     final isWeekday =
// //         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

// //     return DraggableScrollableSheet(
// //       initialChildSize: 0.62,
// //       minChildSize: 0.35,
// //       maxChildSize: 0.92,
// //       builder: (context, scrollController) {
// //         return Container(
// //           decoration: const BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
// //           ),
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 10),
// //               Container(
// //                 height: 4,
// //                 width: 44,
// //                 decoration: BoxDecoration(
// //                   color: Colors.black.withOpacity(0.12),
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //               ),
// //               const SizedBox(height: 10),

// //               Padding(
// //                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
// //                 child: Row(
// //                   children: [
// //                     const Icon(Icons.directions_bus_filled, color: burgundy),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           const Text(
// //                             'Concordia Shuttle Schedule',
// //                             style: TextStyle(
// //                               color: burgundy,
// //                               fontWeight: FontWeight.w800,
// //                               fontSize: 16,
// //                             ),
// //                           ),
// //                           Text(
// //                             isWeekday
// //                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
// //                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
// //                             style: const TextStyle(
// //                               color: Colors.black54,
// //                               fontSize: 11,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     IconButton(
// //                       onPressed: () => Navigator.of(context).maybePop(),
// //                       icon: const Icon(Icons.close),
// //                     ),
// //                   ],
// //                 ),
// //               ),

// //               Padding(
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
// //                 child: Row(
// //                   children: [
// //                     _StopChip(
// //                         label: 'SGW  (Hall Building)', color: burgundy),
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(horizontal: 8),
// //                       child: Icon(Icons.sync_alt,
// //                           size: 16, color: Colors.black45),
// //                     ),
// //                     _StopChip(label: 'Loyola', color: burgundy),
// //                   ],
// //                 ),
// //               ),

// //               const Divider(height: 1),

// //               Expanded(
// //                 child: ListView.builder(
// //                   controller: scrollController,
// //                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
// //                   itemCount: times.length,
// //                   itemBuilder: (context, index) {
// //                     final t = times[index];
// //                     final now = DateTime.now();
// //                     final isPast = t.isBefore(now);
// //                     final isNext = !isPast &&
// //                         (index == 0 || times[index - 1].isBefore(now));

// //                     return Container(
// //                       margin: const EdgeInsets.only(bottom: 6),
// //                       padding: const EdgeInsets.symmetric(
// //                           horizontal: 12, vertical: 8),
// //                       decoration: BoxDecoration(
// //                         color: isNext
// //                             ? burgundy.withOpacity(0.08)
// //                             : Colors.transparent,
// //                         border: isNext
// //                             ? Border.all(color: burgundy.withOpacity(0.3))
// //                             : null,
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(
// //                             Icons.directions_bus_filled,
// //                             size: 16,
// //                             color: isPast
// //                                 ? Colors.black26
// //                                 : isNext
// //                                     ? burgundy
// //                                     : Colors.black54,
// //                           ),
// //                           const SizedBox(width: 10),
// //                           Text(
// //                             ConcordiaShuttleService.formatTime(t),
// //                             style: TextStyle(
// //                               fontSize: 14,
// //                               fontWeight: isNext
// //                                   ? FontWeight.w700
// //                                   : FontWeight.w400,
// //                               color: isPast
// //                                   ? Colors.black26
// //                                   : isNext
// //                                       ? burgundy
// //                                       : Colors.black87,
// //                             ),
// //                           ),
// //                           if (isNext) ...[
// //                             const SizedBox(width: 10),
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(
// //                                   horizontal: 8, vertical: 2),
// //                               decoration: BoxDecoration(
// //                                 color: burgundy,
// //                                 borderRadius: BorderRadius.circular(10),
// //                               ),
// //                               child: const Text(
// //                                 'Next bus',
// //                                 style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: 10,
// //                                   fontWeight: FontWeight.w700,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ],
// //                       ),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }

// // class _StopChip extends StatelessWidget {
// //   final String label;
// //   final Color color;

// //   const _StopChip({required this.label, required this.color});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
// //       decoration: BoxDecoration(
// //         color: color.withOpacity(0.1),
// //         border: Border.all(color: color.withOpacity(0.4)),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Text(
// //         label,
// //         style: TextStyle(
// //           color: color,
// //           fontSize: 12,
// //           fontWeight: FontWeight.w600,
// //         ),
// //       ),
// //     );
// //   }
// // }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../shared/widgets/map_search_bar.dart';
// import '../building_detection.dart';
// import '../../data/building_polygons.dart';
// import '../../data/search_result.dart';
// import '../../data/search_suggestion.dart';
// import '../building_search_service.dart';
// import '../google_places_service.dart';
// import '../google_directions_service.dart';
// import '../../shared/widgets/campus_toggle.dart';
// import '../../shared/widgets/building_info_popup.dart';
// import '../../shared/widgets/route_preview_panel.dart';
// import '../../features/indoor/data/building_info.dart';
// import '../../services/navigation_steps.dart';
// import '../indoor_maps/indoor_floor_config.dart';
// import 'package:campus_app/utils/geo.dart' as geo;
// import '../../shared/widgets/indoor_floor_dropdown.dart';
// import '../indoor_maps/indoor_map_controller.dart';
// import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// import 'package:campus_app/models/campus.dart';
// import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// import '../indoor_maps/indoor_map_repository.dart';
// import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// import '../../services/concordia_shuttle_service.dart';

// // concordia campus coordinates
// const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// const double campusRadius = 500; // meters
// const String currentLocationTag = "Current location";

// // when camera center is within this distance auto-switch toggle
// const double campusAutoSwitchRadius = 500; // meters
// // knowing which campus the user is in
// Campus detectCampus(LatLng userLocation) {
//   final sgwDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaSGW.latitude,
//     concordiaSGW.longitude,
//   );

//   final loyolaDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaLoyola.latitude,
//     concordiaLoyola.longitude,
//   );

//   if (sgwDistance <= campusRadius) return Campus.sgw;
//   if (loyolaDistance <= campusRadius) return Campus.loyola;
//   return Campus.none;
// }

// class OutdoorMapPage extends StatefulWidget {
//   final Campus initialCampus;
//   final bool isLoggedIn;

//   @visibleForTesting
//   final BuildingPolygon? debugSelectedBuilding;

//   @visibleForTesting
//   final Offset? debugAnchorOffset;

//   @visibleForTesting
//   final bool debugDisableMap;

//   @visibleForTesting
//   final bool debugDisableLocation;

//   @visibleForTesting
//   final String? debugLinkOverride;

//   const OutdoorMapPage({
//     super.key,
//     required this.initialCampus,
//     this.debugSelectedBuilding,
//     this.debugAnchorOffset,
//     this.debugDisableMap = false,
//     this.debugDisableLocation = false,
//     this.debugLinkOverride,
//     required this.isLoggedIn,
//   });

//   @override
//   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// }

// class _OutdoorMapPageState extends State<OutdoorMapPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _originRoomController = TextEditingController();
//   final TextEditingController _destinationRoomController = TextEditingController();
//   bool _cameraMoving = false;
//   List<SearchSuggestion> _searchSuggestions = [];
//   Timer? _debounceTimer;

//   // Indoor overlay state
//   Set<Polygon> _indoorPolygons = {};
//   bool _showIndoor = false;
//   List<IndoorFloorOption> _indoorFloors = const [];
//   String? _selectedIndoorFloorAsset;
//   final IndoorMapController _indoorController = IndoorMapController();

//   // --- Indoor floors state ---
//   GoogleMapController? _mapController;

//   LatLng? _currentLocation;
//   BitmapDescriptor? _blueDotIcon;
//   BuildingPolygon? _currentBuildingPoly;
//   BuildingPolygon? _selectedBuildingPoly;
//   // ignore: unused_field
//   SearchResult? _selectedSearchResult;
//   // ignore: unused_field
//   Map<String, dynamic>? _indoorGeoJson;
//   Set<Marker> _roomLabelMarkers = {};

//   Set<Polyline> _routePolylines = {};

//   // Room location marker
//   Marker? _destinationRoomMarker;
//   String? _currentBuildingCode;

//   // Route preview mode
//   bool _showRoutePreview = false;
//   LatLng? _routeOrigin;
//   LatLng? _routeDestination;
//   String _routeOriginText = currentLocationTag;
//   String _routeDestinationText = '';
//   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
//   final Map<String, String?> _routeDurations = {};
//   final Map<String, String?> _routeDistances = {};
//   final Map<String, String?> _routeArrivalTimes = {};
//   final Map<String, List<LatLng>> _routePointsByMode = {};
//   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
//   String? _routeOriginBuildingCode;
//   String? _routeDestinationBuildingCode;

//   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
//   // --- Navigation camera follow state ---
//   bool _navigationFollowUser = false;
//   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//   static const double _navZoom = 18.0;
//   static const double _navTilt = 60.0;
//   static const double _defaultZoom = 15.0;
//   static const double _defaultTilt = 0.0;
//   static const double _defaultBearing = 0.0;
//   // ignore: unused_field
//   static const double _navBearingThresholdDegrees = 10.0;
//   // ignore: unused_field
//   static const double _navDistanceThresholdMeters = 5.0;
//   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
//   bool _isNavigating = false;
//   String? _navModeKey;
//   int _navStepIndex = 0;
//   bool _isLoadingRouteData = false;
//   List<SearchSuggestion> _routeOriginSuggestions = [];
//   List<SearchSuggestion> _routeDestinationSuggestions = [];
//   Timer? _routeDebounceTimer;

//   // Google Directions modes only — shuttle is handled separately
//   static const List<RouteTravelMode> _supportedTravelModes = [
//     RouteTravelMode.driving,
//     RouteTravelMode.walking,
//     RouteTravelMode.bicycling,
//     RouteTravelMode.transit,
//   ];

//   // Shuttle state
//   List<ShuttleDeparture> _shuttleNextBuses = [];
//   int? _shuttleWalkingMinutes;
//   String _shuttleNearestStop = 'SGW';
//   BitmapDescriptor? _shuttleStopIcon;

//   StreamSubscription<Position>? _posSub;

//   Timer? _popupDebounce;

//   static const double _popupW = 300;
//   static const double _popupH = 260;

//   LatLng? _selectedBuildingCenter;
//   Offset? _anchorOffset;

//   Campus _currentCampus = Campus.none;
//   Campus _selectedCampus = Campus.none;

//   LatLng? _lastCameraTarget;

//   void _clearIndoorState() {
//     _showIndoor = false;
//     _indoorFloors = const [];
//     _selectedIndoorFloorAsset = null;
//     _indoorPolygons = {};
//     _indoorGeoJson = null;
//     _roomLabelMarkers = {};
//   }

//   Campus _campusFromPoint(LatLng p) {
//     final dSgw = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaSGW.latitude,
//       concordiaSGW.longitude,
//     );

//     final dLoy = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaLoyola.latitude,
//       concordiaLoyola.longitude,
//     );

//     final minDist = dSgw < dLoy ? dSgw : dLoy;
//     if (minDist > campusAutoSwitchRadius) return Campus.none;

//     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
//   }

//   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
//     print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
//   }

//   Future<void> _syncToggleWithCameraCenter() async {
//     if (!mounted) return;

//     LatLng? center = _lastCameraTarget;

//     if (center == null) {
//       final controller = _mapController;
//       if (controller == null) return;

//       try {
//         final bounds = await controller.getVisibleRegion();
//         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
//         final lng =
//             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
//         center = LatLng(lat, lng);
//       } catch (_) {
//         return;
//       }
//     }

//     final newCampus = _campusFromPoint(center);

//     if (newCampus == _selectedCampus) return;

//     setState(() {
//       _selectedCampus = newCampus;
//     });
//   }

//   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//     return geo.pointInPolygon(point, polygon);
//   }

//   Future<void> _loadIndoorFloor(String assetPath) async {
//     try {
//       final result = await _indoorController.loadFloor(assetPath);
//       if (!mounted) return;
//       setState(() {
//         _showIndoor = true;
//         _selectedIndoorFloorAsset = assetPath;
//         _indoorPolygons = result.polygons;
//         _indoorGeoJson = result.geoJson;
//         _roomLabelMarkers = result.labels;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load indoor floor: $e')),
//       );
//     }
//   }

//   Future<void> _toggleIndoorMap() async {
//     // turn OFF
//     if (_showIndoor) {
//       setState(() {
//         _clearIndoorState();
//       });
//       return;
//     }

//     // turn ON (needs selected building)
//     final b = _selectedBuildingPoly;
//     if (b == null) return;

//     final floors = IndoorFloorConfig.floorsForBuilding(b.code);
//     if (floors.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No indoor maps available for this building')),
//       );
//       return;
//     }

//     setState(() {
//       _indoorFloors = floors;
//       _selectedIndoorFloorAsset = floors.first.assetPath;
//     });

//     await _loadIndoorFloor(floors.first.assetPath);
//   }

//   Future<void> _goToMyLocation() async {
//     final controller = _mapController;
//     if (controller == null) return;

//     var loc = _currentLocation;

//     if (loc == null) {
//       try {
//         final p = await Geolocator.getCurrentPosition();
//         loc = LatLng(p.latitude, p.longitude);
//         if (mounted) setState(() => _currentLocation = loc);
//       } catch (_) {
//         return;
//       }
//     }

//     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
//   }

//   Future<void> _openLink(String url) async {
//     if (url.trim().isEmpty) return;

//     final uri = Uri.tryParse(url);
//     if (uri == null) return;

//     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     if (!ok) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
//     }
//   }

//   void _schedulePopupUpdate() {
//     _popupDebounce?.cancel();
//     _popupDebounce = Timer(
//       const Duration(milliseconds: 16),
//       _updatePopupOffset,
//     );
//   }

//   Future<void> _updatePopupOffset() async {
//     final controller = _mapController;
//     final center = _selectedBuildingCenter;
//     if (!mounted || controller == null || center == null) return;

//     final sc = await controller.getScreenCoordinate(center);
//     if (!mounted) return;

//     double x = sc.x.toDouble();
//     double y = sc.y.toDouble();

//     final dpr = MediaQuery.of(context).devicePixelRatio;
//     x = x / dpr;
//     y = y / dpr;

//     setState(() {
//       _anchorOffset = Offset(x, y);
//     });
//   }

//   // ignore: unused_element
//   void _selectBuildingWithoutMap(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
//       _cameraMoving = false;
//     });
//   }

//   void _onBuildingTapped(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final controller = _mapController;
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = null;
//       _cameraMoving = true;
//       _clearIndoorState();
//       _roomLabelMarkers = {};
//     });

//     if (controller == null) return;

//     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
//       _,
//     ) async {
//       if (!mounted) return;
//       await _updatePopupOffset();
//       if (!mounted) return;
//       setState(() {
//         _cameraMoving = false;
//       });
//     });
//   }

//   void _closePopup() {
//     _clearSelectedBuilding(clearSearch: true);
//   }

//   void _clearSelectedBuilding({bool clearSearch = false}) {
//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = null;
//       _anchorOffset = null;
//       _routePolylines = {};
//       _showRoutePreview = false;
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//       _destinationRoomMarker = null;
//       if (clearSearch) {
//         _searchController.clear();
//       }
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//     });
//   }

//   Future<void> _getDirections() async {
//     print('[DEBUG] Get directions button clicked');
//     print('[DEBUG] Current location: $_currentLocation');
//     print(
//       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
//     );

//     final origin = _currentLocation;
//     final destination = _selectedBuildingPoly?.center;

//     if (origin == null) {
//       print('[ERROR] Cannot get directions: Current location is null');
//       print(
//         '[ERROR] Make sure location services are enabled and location is set in emulator',
//       );
//       return;
//     }

//     if (destination == null) {
//       print('[ERROR] Cannot get directions: Destination is null');
//       return;
//     }

//     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

//     // Enter route preview mode
//     setState(() {
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = origin;
//       _routeDestination = destination;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText =
//           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
//       _routeOriginBuildingCode = currentBuildingCode;
//       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
//       print(
//         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
//       );
//     });

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _fetchRoutesAndDurations() async {
//     final origin = _routeOrigin;
//     final destination = _routeDestination;

//     if (origin == null || destination == null) {
//       print('[ERROR] Cannot fetch route: origin or destination is null');
//       return;
//     }

//     print(
//       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
//     );

//     setState(() {
//       _isLoadingRouteData = true;
//     });

//     try {
//       final futures = _supportedTravelModes.map(
//         (mode) => GoogleDirectionsService.instance.getRouteDetails(
//           origin: origin,
//           destination: destination,
//           mode: mode.apiValue,
//         ),
//       );

//       final results = await Future.wait(futures);
//       final durations = <String, String?>{};
//       final distances = <String, String?>{};
//       final arrivalTimes = <String, String?>{};
//       final pointsByMode = <String, List<LatLng>>{};
//       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
//       final stepsByMode = <String, List<NavigationStep>>{};

//       for (var i = 0; i < _supportedTravelModes.length; i++) {
//         final mode = _supportedTravelModes[i].apiValue;
//         final route = results[i];
//         durations[mode] = route?.durationText;
//         distances[mode] = route?.distanceText;
//         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
//         stepsByMode[mode] = route?.steps ?? const [];
//         if (route != null && route.points.isNotEmpty) {
//           pointsByMode[mode] = route.points;
//         }
//         if (route != null && route.transitSegments.isNotEmpty) {
//           segmentsByMode[mode] = route.transitSegments;
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         _routeDurations
//           ..clear()
//           ..addAll(durations);
//         _routeDistances
//           ..clear()
//           ..addAll(distances);
//         _routeArrivalTimes
//           ..clear()
//           ..addAll(arrivalTimes);
//         _routePointsByMode
//           ..clear()
//           ..addAll(pointsByMode);
//         _routeSegmentsByMode
//           ..clear()
//           ..addAll(segmentsByMode);
//         _routeStepsByMode
//           ..clear()
//           ..addAll(stepsByMode);

//         _isLoadingRouteData = false;
//       });

//       _applySelectedModeRoute(animateCamera: true);

//       _fetchShuttleInfo();
//     } catch (e) {
//       print('Error getting directions: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoadingRouteData = false;
//       });
//     }
//   }

//   void _openStepsForSelectedMode() {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       _showShuttleScheduleModal();
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     showNavigationStepsModal(
//       context,
//       title: _selectedTravelMode.label,
//       steps: steps,
//       totalDuration: _routeDurations[key],
//       totalDistance: _routeDistances[key],
//     );
//   }

//   void _applySelectedModeRoute({required bool animateCamera}) {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

//     final selectedModeKey = _selectedTravelMode.apiValue;
//     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
//     if (_selectedTravelMode == RouteTravelMode.transit &&
//         selectedSegments != null &&
//         selectedSegments.isNotEmpty) {
//       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
//       return;
//     }

//     final selectedPoints = _routePointsByMode[selectedModeKey];

//     if (selectedPoints == null || selectedPoints.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = {
//         Polyline(
//           polylineId: const PolylineId('route'),
//           points: selectedPoints,
//           color: const Color(0xFF76263D),
//           width: 5,
//           patterns: _selectedTravelMode == RouteTravelMode.driving
//               ? const []
//               : [PatternItem.dot, PatternItem.gap(10)],
//         ),
//       };
//     });

//     if (!animateCamera || _mapController == null) return;
//     final bounds = geo.calculateBounds(selectedPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _applyTransitSegments(
//     List<DirectionsRouteSegment> segments, {
//     required bool animateCamera,
//   }) {
//     final polylines = <Polyline>{};
//     final allPoints = <LatLng>[];

//     for (var i = 0; i < segments.length; i++) {
//       final segment = segments[i];
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       allPoints.addAll(segment.points);

//       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
//       polylines.add(
//         Polyline(
//           polylineId: PolylineId('route_segment_$i'),
//           points: segment.points,
//           color: _resolveTransitSegmentColor(segment),
//           width: 5,
//           patterns: isWalking
//               ? [PatternItem.dot, PatternItem.gap(10)]
//               : const [],
//         ),
//       );
//     }

//     if (polylines.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = polylines;
//     });

//     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
//       return;
//     }

//     final bounds = geo.calculateBounds(allPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _startNavigation() {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
//           ),
//           duration: Duration(seconds: 3),
//         ),
//       );
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     if (steps.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No steps available for this route')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isNavigating = true;
//       _navModeKey = key;
//       _navStepIndex = 0;

//       _navigationFollowUser = true;
//       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//     });

//     if (_currentLocation != null && _mapController != null) {
//       try {
//         final currentPos = _currentLocation!;
//         final initialCam = CameraPosition(
//           target: currentPos,
//           zoom: _navZoom,
//           tilt: _navTilt,
//           bearing: 0.0,
//         );
//         _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(initialCam),
//         );
//       } catch (e) {
//         print('Error animating camera when starting navigation: $e');
//       }
//     }
//   }

//   void _stopNavigation() {
//     setState(() {
//       _isNavigating = false;
//       _navModeKey = null;
//       _navStepIndex = 0;
//       _navigationFollowUser = false;
//     });
//     if (_mapController != null && _currentLocation != null) {
//       try {
//         final cam = CameraPosition(
//           target: _currentLocation!,
//           zoom: _defaultZoom,
//           tilt: _defaultTilt,
//           bearing: _defaultBearing,
//         );

//         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//       } catch (e) {
//         print('Error resetting camera after navigation: $e');
//       }
//     }

//     _closeRoutePreview();
//   }

//   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
//     if (_mapController == null) return;
//     if (!_navigationFollowUser) return;

//     final now = DateTime.now();

//     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
//       return;
//     }

//     double bearing = 0.0;
//     if (heading != null && heading >= 0.0) {
//       bearing = heading;
//     }

//     final cam = CameraPosition(
//       target: userLatLng,
//       zoom: _navZoom,
//       tilt: _navTilt,
//       bearing: bearing,
//     );

//     try {
//       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//     } catch (e) {
//       print('Error animating navigation camera: $e');
//     }
//   }

//   void _maybeAdvanceNavigationStep(LatLng user) {
//     final key = _navModeKey;
//     if (key == null) return;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return;

//     if (_navStepIndex >= steps.length - 1) return;

//     final current = steps[_navStepIndex];
//     final end = current.endPoint;
//     if (end == null) return;

//     final d = Geolocator.distanceBetween(
//       user.latitude,
//       user.longitude,
//       end.latitude,
//       end.longitude,
//     );

//     if (d <= 20) {
//       setState(() => _navStepIndex += 1);
//     }
//   }

//   void _closeRoutePreview() {
//     setState(() {
//       _showRoutePreview = false;
//       _routePolylines = {};
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//       _searchController.clear();

//       //reset indoor map and building selection state
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//     });
//   }

//   String? _formatArrivalTime(int? durationSeconds) {
//     if (durationSeconds == null) {
//       return null;
//     }

//     final now = DateTime.now();
//     final arrival = now.add(Duration(seconds: durationSeconds));
//     int hour = arrival.hour;
//     final minute = arrival.minute.toString().padLeft(2, '0');
//     final isPm = hour >= 12;
//     final period = isPm ? 'pm' : 'am';
//     hour = hour % 12;
//     if (hour == 0) {
//       hour = 12;
//     }
//     return '$hour:$minute $period';
//   }

//   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
//     const defaultRed = Color(0xFF76263D);
//     final mode = segment.travelMode.toUpperCase();
//     if (mode == 'WALKING') {
//       return defaultRed;
//     }

//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Colors.blue;
//     }

//     final lineColor = parseHexColor(segment.transitLineColorHex);
//     if (lineColor != null) {
//       return lineColor;
//     }

//     return defaultRed;
//   }

//   List<TransitDetailItem> _buildTransitDetailItems() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     final items = <TransitDetailItem>[];

//     for (final segment in segments) {
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       final travelMode = segment.travelMode.toUpperCase();
//       if (travelMode == 'WALKING') {
//         continue;
//       }

//       final vehicleType = segment.transitVehicleType?.toUpperCase();
//       final lineLabel =
//           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
//       final color = _resolveTransitSegmentColor(segment);

//       IconData icon = Icons.directions_transit;
//       String title = 'Transit $lineLabel';

//       if (vehicleType == 'BUS') {
//         icon = Icons.directions_bus;
//         title = 'Bus $lineLabel';
//       } else if (vehicleType == 'SUBWAY' ||
//           vehicleType == 'METRO_RAIL' ||
//           vehicleType == 'HEAVY_RAIL' ||
//           vehicleType == 'COMMUTER_TRAIN' ||
//           vehicleType == 'RAIL' ||
//           vehicleType == 'TRAM' ||
//           vehicleType == 'LIGHT_RAIL' ||
//           vehicleType == 'MONORAIL') {
//         icon = Icons.directions_subway;
//         title = 'Metro $lineLabel';
//       }

//       items.add(TransitDetailItem(icon: icon, color: color, title: title));
//     }

//     return items;
//   }

//   // ignore: unused_element
//   List<DirectionsRouteSegment> _getTransitDetailSegments() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     return segments
//         .where(
//           (segment) =>
//               segment.travelMode.toUpperCase() == 'TRANSIT' &&
//               segment.points.isNotEmpty,
//         )
//         .toList();
//   }

//   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     final lineLabel =
//         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

//     if (vehicleType == 'BUS') {
//       return 'Bus $lineLabel';
//     }

//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return 'Metro $lineLabel';
//     }

//     return 'Transit $lineLabel';
//   }

//   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Icons.directions_bus;
//     }
//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return Icons.directions_subway;
//     }
//     return Icons.directions_transit;
//   }

//   // ignore: unused_element
//   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
//     const burgundy = Color(0xFF76263D);

//     return Container(
//       width: 340,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.15),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Transit details',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: burgundy,
//             ),
//           ),
//           const SizedBox(height: 6),
//           for (final segment in segments)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 6),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     _transitSegmentIcon(segment),
//                     size: 16,
//                     color: _resolveTransitSegmentColor(segment),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _formatTransitSegmentTitle(segment),
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         if (segment.transitHeadsign != null &&
//                             segment.transitHeadsign!.trim().isNotEmpty)
//                           Text(
//                             segment.transitHeadsign!,
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Colors.black54,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Color? parseHexColor(String? hex) {
//     if (hex == null || hex.trim().isEmpty) {
//       return null;
//     }

//     final normalized = hex.trim().replaceFirst('#', '');
//     if (normalized.length != 6) {
//       return null;
//     }

//     final value = int.tryParse(normalized, radix: 16);
//     if (value == null) {
//       return null;
//     }

//     return Color(0xFF000000 | value);
//   }

//   void _switchOriginDestination() {
//     setState(() {
//       final tempOrigin = _routeOriginText;
//       final tempOriginLatLng = _routeOrigin;
//       final tempDestination = _routeDestinationText;
//       final tempDestinationLatLng = _routeDestination;

//       _routeOriginText = tempDestination;
//       _routeOrigin = tempDestinationLatLng;
//       _routeDestinationText = tempOrigin;
//       _routeDestination = tempOriginLatLng;

//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//     });

//     _fetchRoutesAndDurations();
//   }

//   void _onTravelModeSelected(RouteTravelMode mode) {
//     setState(() {
//       _selectedTravelMode = mode;
//     });

//     if (mode == RouteTravelMode.shuttle) {
//       _fetchShuttleInfo();
//       return;
//     }

//     if (_routePointsByMode.containsKey(mode.apiValue)) {
//       _applySelectedModeRoute(animateCamera: false);
//       return;
//     }

//     _fetchRoutesAndDurations();
//   }

//   /// Shuttle stop marker icon
//   Future<void> _createShuttleStopIcon() async {
//     _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
//       const ImageConfiguration(size: Size(600, 600)),
//       'assets/images/shuttle_icon.png',
//     );
//   }

//   /// Walking time + 4 next buses
//   Future<void> _fetchShuttleInfo() async {
//     final origin = _routeOrigin ?? _currentLocation;

//     if (origin == null) {
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//       return;
//     }

//     setState(() {
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//     });

//     try {
//       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
//       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

//       int walkingSeconds = 0;
//       List<LatLng> walkPoints = [];

//       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
//         origin: origin,
//         destination: stopLatLng,
//         mode: 'walking',
//       );

//       if (walkRoute != null) {
//         walkingSeconds = walkRoute.durationSeconds ?? 0;
//         walkPoints = walkRoute.points;
//       }

//       final walkingMinutes = (walkingSeconds / 60).ceil();

//       final buses = ConcordiaShuttleService.getNextDepartures(
//         fromStop: nearestStop,
//         now: DateTime.now(),
//         count: 4,
//         walkingDuration: Duration(seconds: walkingSeconds),
//       );

//       String shuttleDurationLabel;
//       if (!ConcordiaShuttleService.isInService()) {
//         shuttleDurationLabel = 'No service';
//       } else if (buses.isNotEmpty) {
//         shuttleDurationLabel = buses.first.statusLabel;
//       } else {
//         shuttleDurationLabel = '–';
//       }

//       if (walkPoints.isNotEmpty) {
//         setState(() {
//           _routePolylines = {
//             Polyline(
//               polylineId: const PolylineId('shuttle_walk'),
//               points: walkPoints,
//               color: const Color(0xFF76263D),
//               width: 5,
//               patterns: [PatternItem.dot, PatternItem.gap(10)],
//             ),
//           };
//         });

//         if (_mapController != null) {
//           final bounds = geo.calculateBounds([...walkPoints, stopLatLng]);
//           _mapController!
//               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//         }
//       } else {
//         setState(() {
//           _routePolylines = {};
//         });
//       }

//       if (!mounted) return;
//       setState(() {
//         _shuttleNearestStop = nearestStop;
//         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
//         _shuttleNextBuses = buses;
//         _routeDurations['shuttle'] = shuttleDurationLabel;
//       });
//     } catch (e) {
//       print('Error fetching shuttle info: $e');
//       if (!mounted) return;
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//     }
//   }

//   /// Open full day schedule
//   void _showShuttleScheduleModal() {
//     showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) =>
//           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
//     );
//   }

//   Future<void> _onRouteOriginChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeOriginSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeOriginSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for origin: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} origin suggestions');
//         if (mounted) {
//           setState(() {
//             _routeOriginSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting origin suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteDestinationChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeDestinationSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeDestinationSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for destination: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} destination suggestions');
//         if (mounted) {
//           setState(() {
//             _routeDestinationSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting destination suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
//     print(
//       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
//     );
//     LatLng? newOrigin;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       print('[DEBUG] Handling Concordia building');
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newOrigin = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//       print('[DEBUG] Concordia building origin: $newOrigin');
//     } else if (suggestion.placeId != null) {
//       print(
//         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
//       );
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         print('[DEBUG] Place details result: $placeDetails');
//         if (placeDetails != null) {
//           newOrigin = placeDetails.location;
//           buildingCode = null;
//           print('[DEBUG] Non-Concordia origin location: $newOrigin');
//         } else {
//           print(
//             '[ERROR] Place details returned null for ${suggestion.placeId}',
//           );
//         }
//       } catch (e) {
//         print('[ERROR] Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newOrigin != null) {
//       print('[DEBUG] Updating route origin state');
//       print('[DEBUG] New origin building code: $buildingCode');
//       setState(() {
//         _routeOrigin = newOrigin;
//         _routeOriginText = displayText;
//         _routeOriginSuggestions = [];
//         _routeOriginBuildingCode = buildingCode;
//         _originRoomController.clear();
//       });
//       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
//       await _fetchRoutesAndDurations();
//     } else {
//       print('[ERROR] Could not determine origin location');
//     }
//   }

//   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
//     LatLng? newDestination;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newDestination = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//     } else if (suggestion.placeId != null) {
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         if (placeDetails != null) {
//           newDestination = placeDetails.location;
//           buildingCode = null;
//         }
//       } catch (e) {
//         print('Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newDestination != null) {
//       print('[DEBUG] Updating route destination state');
//       print('[DEBUG] New destination building code: $buildingCode');
//       setState(() {
//         _routeDestination = newDestination;
//         _routeDestinationText = displayText;
//         _routeDestinationSuggestions = [];
//         _routeDestinationBuildingCode = buildingCode;
//         _destinationRoomController.clear();
//       });
//       await _fetchRoutesAndDurations();
//     }
//   }

//   void _hideBuildingPopup() {
//     if (_selectedBuildingPoly == null) return;

//     _clearSelectedBuilding();
//   }

//   Future<void> _onSearchSubmitted(String query) async {
//     if (query.trim().isEmpty) return;

//     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

//     if (concordiaBuilding != null) {
//       _onBuildingTapped(concordiaBuilding);
//       return;
//     }

//     final results = await BuildingSearchService.searchWithGooglePlaces(
//       query,
//       userLocation: _currentLocation,
//     );

//     if (results.isNotEmpty) {
//       SearchResult? selectedResult;

//       for (final result in results) {
//         if (!result.isConcordiaBuilding) {
//           selectedResult = result;
//           break;
//         }
//       }

//       if (selectedResult == null && results.isNotEmpty) {
//         selectedResult = results.first;
//       }

//       if (selectedResult != null) {
//         if (selectedResult.isConcordiaBuilding &&
//             selectedResult.buildingPolygon != null) {
//           _onBuildingTapped(selectedResult.buildingPolygon!);
//         } else {
//           _onPlaceSelected(selectedResult);
//         }
//       }
//     } else {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('"$query" not found'),
//           duration: const Duration(seconds: 2),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//       _searchController.clear();
//     }
//   }

//   void _onPlaceSelected(SearchResult result) {
//     final controller = _mapController;
//     if (controller == null) return;

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = result;
//     });

//     _searchController.value = TextEditingValue(
//       text: result.name,
//       selection: TextSelection.collapsed(offset: result.name.length),
//     );

//     if (result.isConcordiaBuilding) {
//       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${result.name} is a Concordia building'),
//           duration: const Duration(seconds: 3),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//     } else {
//       if (_currentLocation == null) {
//         controller.animateCamera(
//           CameraUpdate.newLatLngZoom(result.location, 18),
//         );
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${result.name} is not a Concordia building'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.grey[700],
//           ),
//         );
//       } else {
//         _enterRoutePreviewForPlace(result);
//       }
//     }
//   }

//   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
//     if (_currentLocation == null) return;

//     print(
//       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
//     );

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = _currentLocation;
//       _routeDestination = place.location;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText = place.name;
//       _selectedSearchResult = place;
//     });

//     print(
//       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
//     );

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final buildingPolygon = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       if (buildingPolygon == null) return;
//       _onBuildingTapped(buildingPolygon);
//     } else if (suggestion.placeId != null) {
//       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//         suggestion.placeId!,
//       );
//       if (placeDetails != null) {
//         final concordiaBuilding = BuildingSearchService.searchBuilding(
//           suggestion.name,
//         );

//         if (concordiaBuilding != null) {
//           _onBuildingTapped(concordiaBuilding);
//         } else {
//           final searchResult = SearchResult.fromGooglePlace(
//             name: placeDetails.name,
//             address: placeDetails.formattedAddress,
//             location: placeDetails.location,
//             isConcordiaBuilding: false,
//             placeId: placeDetails.placeId,
//           );
//           _onPlaceSelected(searchResult);
//         }
//       }
//     }
//   }

//   Set<Polygon> _createBuildingPolygons() {
//     const burgundy = Color(0xFF800020);
//     const selectedBlue = Color(0xFF7F83C3);

//     final polys = <Polygon>{};

//     for (final b in buildingPolygons) {
//       final isCurrent = _currentBuildingPoly?.code == b.code;
//       final isSelected = _selectedBuildingPoly?.code == b.code;

//       final strokeColor = isSelected
//           ? selectedBlue.withOpacity(0.95)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.8)
//           : burgundy.withOpacity(0.55);

//       final fillColor = isSelected
//           ? selectedBlue.withOpacity(0.25)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.25)
//           : burgundy.withOpacity(0.22);

//       final strokeWidth = isSelected
//           ? 3
//           : isCurrent
//           ? 3
//           : 2;
//       final zIndex = isSelected
//           ? 3
//           : isCurrent
//           ? 2
//           : 1;

//       polys.add(
//         Polygon(
//           polygonId: PolygonId('poly_${b.code}'),
//           points: b.points,
//           strokeWidth: strokeWidth,
//           strokeColor: strokeColor,
//           fillColor: fillColor,
//           zIndex: zIndex,
//           consumeTapEvents: true,
//           onTap: () => _onBuildingTapped(b),
//         ),
//       );
//     }

//     return polys;
//   }

//   List<Widget> _createBuildingGestureDetectors() {
//     final detectors = <Widget>[];

//     for (final building in buildingPolygons) {
//       detectors.add(
//         Positioned(
//           left: 0,
//           top: 0,
//           child: GestureDetector(
//             key: Key('building_detector_${building.code}'),
//             onTap: () => _onBuildingTapped(building),
//             child: Container(
//               width: 100,
//               height: 100,
//               color: Colors.transparent,
//             ),
//           ),
//         ),
//       );
//     }

//     return detectors;
//   }

//   @override
//   void initState() {
//     super.initState();

//     _selectedCampus = widget.initialCampus;

//     _lastCameraTarget = widget.initialCampus == Campus.loyola
//         ? concordiaLoyola
//         : concordiaSGW;

//     _createBlueDotIcon();
//     _createShuttleStopIcon();
//     _determineUserLocationAndBuilding().then((_) {
//       _startLocationUpdates();
//     });

//     _searchController.addListener(_onSearchChanged);
//     // Clear destination room marker when room input changes
//     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
//     _determineUserLocationAndBuilding();
//   }

//   Future<void> _determineUserLocationAndBuilding() async {
//     final position = await Geolocator.getCurrentPosition();
//     _currentLocation = LatLng(position.latitude, position.longitude);

//     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

//     setState(() {
//       _currentBuildingCode = buildingAtLocation?.code;
//     });
//   }

//   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
//     for (final building in buildingPolygons) {
//       if (_isPointInPolygon(location, building.points)) {
//         return building;
//       }
//     }
//     return null;
//   }

//   void _onDestinationRoomTextChanged() {
//     if (_destinationRoomMarker == null) return;

//     setState(() {
//       _destinationRoomMarker = null;
//     });
//   }

//   void _onSearchChanged() {
//     _debounceTimer?.cancel();

//     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       final query = _searchController.text;
//       try {
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('Error getting search suggestions: $e');
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = BuildingSearchService.getSuggestions(
//               query,
//             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
//           });
//         }
//       }
//     });
//   }

//   Future<void> _createBlueDotIcon() async {
//     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
//       BitmapDescriptor.hueAzure,
//     );
//   }

//   Future<void> _startLocationUpdates() async {
//     print('[DEBUG] Starting location updates...');

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     print('[DEBUG] Location service enabled: $serviceEnabled');

//     if (!serviceEnabled) {
//       print('[ERROR] Location services are disabled');
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     print('[DEBUG] Initial permission status: $permission');

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       print('[DEBUG] Permission after request: $permission');
//       if (permission == LocationPermission.denied) {
//         print('[ERROR] Location permission denied by user');
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       print('[ERROR] Location permission denied forever');
//       return;
//     }

//     try {
//       print('[DEBUG] Attempting to get current position...');
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           timeLimit: Duration(seconds: 10),
//         ),
//       );
//       final newLatLng = LatLng(position.latitude, position.longitude);

//       print(
//         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
//       );
//       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

//       if (!mounted) return;
//       setState(() {
//         _currentLocation = newLatLng;
//         _currentCampus = detectCampus(newLatLng);
//         _currentBuildingPoly = detectBuildingPoly(newLatLng);
//       });

//       print('[DEBUG] Current campus: $_currentCampus');
//       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

//       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
//     } catch (e) {
//       print('[ERROR] Failed to get current position: $e');
//       print(
//         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
//       );
//     }

//     _posSub =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.best,
//             distanceFilter: 5,
//           ),
//         ).listen((position) {
//           final newLatLng = LatLng(position.latitude, position.longitude);
//           print(
//             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
//           );

//           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

//           if (!mounted) return;
//           setState(() {
//             _currentLocation = newLatLng;
//             _currentCampus = detectCampus(newLatLng);
//             _currentBuildingPoly = detectBuildingPoly(newLatLng);
//             _currentBuildingCode = buildingAtLocation?.code;
//           });

//           if (_isNavigating) {
//             _maybeAdvanceNavigationStep(newLatLng);
//           }
//           if (_navigationFollowUser) {
//             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
//           }
//         });
//   }

//   Set<Marker> _createMarkers() {
//     final markers = <Marker>{};
//     // Add current location marker
//     if (_currentLocation != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLocation!,
//           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           zIndex: 999,
//         ),
//       );
//     }

//     // Shuttle stop markers
//     final shuttleIcon = _shuttleStopIcon;
//     if (shuttleIcon != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_sgw'),
//           position: shuttleStopSGW,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — SGW',
//             snippet: 'Hall Building stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_loyola'),
//           position: shuttleStopLoyola,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — Loyola',
//             snippet: 'Loyola campus stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//     }

//     // Add destination room marker only when indoor map is shown
//     if (_destinationRoomMarker != null && _showIndoor) {
//       markers.add(_destinationRoomMarker!);
//     }

//     if (_showRoutePreview) {
//       if (_routeDestination != null) {
//         markers.add(
//           Marker(
//             markerId: const MarkerId('route_destination'),
//             position: _routeDestination!,
//             infoWindow: InfoWindow(title: _routeDestinationText),
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueRed,
//             ),
//           ),
//         );
//       }
//     }

//     return markers;
//   }

//   Set<Circle> _createCircles() {
//     final circles = <Circle>{};

//     if (_currentLocation == null) return {};

//     circles.add(
//       Circle(
//         circleId: const CircleId('current_location_accuracy'),
//         center: _currentLocation!,
//         radius: 20,
//         fillColor: Colors.blue.withOpacity(0.1),
//         strokeColor: Colors.blue.withOpacity(0.3),
//         strokeWidth: 1,
//       ),
//     );

//     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
//       final segments = _routeSegmentsByMode['transit'] ?? const [];
//       final seen = <String>{};

//       for (final segment in segments) {
//         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
//           continue;
//         }
//         if (segment.points.isEmpty) {
//           continue;
//         }

//         final endpoints = [segment.points.first, segment.points.last];
//         for (final point in endpoints) {
//           final key =
//               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
//           if (!seen.add(key)) {
//             continue;
//           }

//           circles.add(
//             Circle(
//               circleId: CircleId('transit_stop_$key'),
//               center: point,
//               radius: 15,
//               fillColor: Colors.white,
//               strokeColor: const Color(0xFF76263D),
//               strokeWidth: 2,
//             ),
//           );
//         }
//       }
//     }

//     return circles;
//   }

//   NavigationStep? _getCurrentNavStep() {
//     final key = _navModeKey;
//     if (key == null) return null;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return null;

//     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
//     return steps[_navStepIndex];
//   }

//   void _switchCampus(Campus newCampus) {
//     LatLng targetLocation;

//     switch (newCampus) {
//       case Campus.sgw:
//         targetLocation = concordiaSGW;
//         break;
//       case Campus.loyola:
//         targetLocation = concordiaLoyola;
//         break;
//       case Campus.none:
//         return;
//     }

//     _lastCameraTarget = targetLocation;
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(targetLocation, 16),
//     );

//     setState(() {
//       _selectedCampus = newCampus;
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _cameraMoving = false;
//       _searchController.clear();
//     });
//   }

//   Offset? _computePopupPosition(BuildContext context) {
//     final screen = MediaQuery.of(context).size;
//     final topPad = MediaQuery.of(context).padding.top;

//     final anchor = widget.debugAnchorOffset ?? _anchorOffset;
//     if (anchor == null || _cameraMoving) return null;

//     final ax = anchor.dx;
//     final ay = anchor.dy;

//     final inView =
//         ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
//     if (!inView) return null;

//     double left = ax - (_popupW / 2);
//     double top = ay - (_popupH / 2);

//     const margin = 8.0;
//     final minLeft = margin;
//     final maxLeft = screen.width - _popupW - margin;
//     final minTop = topPad + margin;
//     final maxTop = screen.height - _popupH - margin;

//     if (left < minLeft) left = minLeft;
//     if (left > maxLeft) left = maxLeft;
//     if (top < minTop) top = minTop;
//     if (top > maxTop) top = maxTop;

//     return Offset(left, top);
//   }

//   Future<void> _onDestinationRoomSubmitted(
//     String buildingCode,
//     String roomCode,
//   ) async {
//     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

//     try {
//       final repo = IndoorMapRepository();
//       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

//       if (roomLocation == null) {
//         print('[ERROR] Could not find location for room $roomCode');
//         return;
//       }
//       print('[DEBUG] Room location found: $roomLocation');
//       final marker = Marker(
//         markerId: const MarkerId('destination_room'),
//         position: roomLocation,
//         infoWindow: InfoWindow(title: 'Room $roomCode'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       );

//       if (!mounted) return;
//       setState(() {
//         _destinationRoomMarker = marker;
//       });

//       print('[DEBUG] Destination room marker placed at $roomLocation');
//     } catch (e) {
//       print('[ERROR] Error processing destination room: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: const Color(0xFFE53935),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final LatLng initialTarget =
//         widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

//     final Campus labelCampus =
//         _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

//     final String campusLabel = labelCampus == Campus.sgw
//         ? 'SGW'
//         : labelCampus == Campus.loyola
//             ? 'Loyola'
//             : '';

//     final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
//     final popupPos = _computePopupPosition(context);

//     return Scaffold(
//       body: Stack(
//         children: [
//           if (widget.debugDisableMap)
//             const SizedBox.expand()
//           else
//             OutdoorMapView(
//               initialTarget: initialTarget,
//               showIndoorStyle: _showIndoor,
//               indoorMapStyle: _indoorMapStyle,
//               onMapCreated: (c) => _mapController = c,
//               onCameraMove: (pos) {
//                 _lastCameraTarget = pos.target;
//                 if (_selectedBuildingCenter != null) _schedulePopupUpdate();
//               },
//               onCameraMoveStarted: () {
//                 if (_selectedBuildingCenter == null) return;
//                 setState(() => _cameraMoving = true);
//               },
//               onCameraIdle: () {
//                 _syncToggleWithCameraCenter();
//                 if (_selectedBuildingCenter == null) return;
//                 setState(() => _cameraMoving = false);
//                 _updatePopupOffset();
//               },
//               markers: {
//                 ..._createMarkers(),
//                 ..._roomLabelMarkers,
//               },
//               circles: _createCircles(),
//               polygons: {
//                 ..._createBuildingPolygons(),
//                 ..._indoorPolygons,
//               },
//               polylines: _routePolylines,
//             ),

//           if (_isNavigating)
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: NavigationNextStepHeader(
//                   modeLabel: _selectedTravelMode.label,
//                   nextStep: _getCurrentNavStep(),
//                   onStop: _stopNavigation,
//                   onShowSteps: _openStepsForSelectedMode,
//                 ),
//               ),
//             ),

//           if (_showRoutePreview && !_isNavigating)
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: RoutePreviewPanel(
//                 originText: _routeOriginText,
//                 destinationText: _routeDestinationText,
//                 onClose: _closeRoutePreview,
//                 onSwitch: _switchOriginDestination,
//                 onOriginChanged: _onRouteOriginChanged,
//                 onDestinationChanged: _onRouteDestinationChanged,
//                 onOriginSelected: _onRouteOriginSelected,
//                 onDestinationSelected: _onRouteDestinationSelected,
//                 originSuggestions: _routeOriginSuggestions,
//                 destinationSuggestions: _routeDestinationSuggestions,
//                 originRoomController: _originRoomController,
//                 destinationRoomController: _destinationRoomController,
//                 onOriginRoomSubmitted: _onOriginRoomSubmitted,
//                 onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
//                 originBuildingCode: _routeOriginBuildingCode,
//                 destinationBuildingCode: _routeDestinationBuildingCode,
//                 isConcordiaBuilding: (buildingCode) {
//                   return buildingPolygons.any(
//                     (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
//                   );
//                 },
//               ),
//             ),

//           if (_showRoutePreview)
//             Positioned(
//               bottom: 25,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: Center(
//                   child: RouteTravelModeBar(
//                     selectedTravelMode: _selectedTravelMode,
//                     onTravelModeSelected: _onTravelModeSelected,
//                     modeDurations: _routeDurations,
//                     isLoadingDurations: _isLoadingRouteData,
//                     onClose: _closeRoutePreview,
//                     onStart: _startNavigation,
//                     isNavigating: _isNavigating,
//                     onShowSteps: _openStepsForSelectedMode,
//                     transitDetails: _buildTransitDetailItems(),
//                     modeDistances: _routeDistances,
//                     modeArrivalTimes: _routeArrivalTimes,
//                     shuttleNextBuses:
//                         _shuttleNextBuses.map((b) => b.statusLabel).toList(),
//                     shuttleWalkingMinutes: _shuttleWalkingMinutes,
//                     shuttleNearestStop: _shuttleNearestStop,
//                     onViewSchedule: _showShuttleScheduleModal,
//                   ),
//                 ),
//               ),
//             ),

//           if (!_showRoutePreview && !_isNavigating)
//             OutdoorTopSearch(
//               campusLabel: campusLabel,
//               controller: _searchController,
//               onSubmitted: _onSearchSubmitted,
//               suggestions: _searchSuggestions,
//               onSuggestionSelected: _onSuggestionSelected,
//               onFocus: _hideBuildingPopup,
//               originRoomController: _originRoomController,
//               destinationRoomController: _destinationRoomController,
//               onOriginRoomSubmitted: _onOriginRoomSubmitted,
//               onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
//               selectedBuildingCode: _selectedBuildingPoly?.code,
//               currentBuildingCode: _currentBuildingCode,
//               userLocation: _currentLocation,
//               isConcordiaBuilding: (buildingCode) {
//                 return buildingPolygons.any(
//                   (b) =>
//                       (b.code ?? '').toUpperCase() ==
//                       buildingCode.toUpperCase(),
//                 );
//               },
//               showIndoor: _showIndoor,
//               floors: _indoorFloors,
//               selectedAssetPath: _selectedIndoorFloorAsset,
//               onFloorChanged: _loadIndoorFloor,
//             ),

//           if (selectedBuilding != null && popupPos != null)
//             OutdoorBuildingPopup(
//               building: selectedBuilding,
//               position: popupPos,
//               buildingInfoByCode: buildingInfoByCode,
//               debugLinkOverride: widget.debugLinkOverride,
//               onClose: _closePopup,
//               onIndoorMap: _toggleIndoorMap,
//               onGetDirections: _getDirections,
//               onOpenLink: _openLink,
//               isLoggedIn: widget.isLoggedIn,
//             ),

//           OutdoorBottomControls(
//             currentLocation: _currentLocation,
//             currentCampus: _currentCampus,
//             onGoToMyLocation: _goToMyLocation,
//             onCenterOnUser: () {
//               final loc = _currentLocation;
//               if (loc == null) return;
//               _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
//             },
//           ),

//           if (!_showRoutePreview)
//             OutdoorBottomBar(
//               showRoutePreview: _showRoutePreview,
//               isNavigating: _isNavigating,
//               selectedCampus: _selectedCampus,
//               onCampusChanged: _switchCampus,
//               selectedTravelMode: _selectedTravelMode,
//               onTravelModeSelected: _onTravelModeSelected,
//               routeDurations: _routeDurations,
//               routeDistances: _routeDistances,
//               routeArrivalTimes: _routeArrivalTimes,
//               isLoadingRouteData: _isLoadingRouteData,
//               onCloseRoutePreview: _closeRoutePreview,
//               onStartNavigation: _startNavigation,
//               onShowSteps: _openStepsForSelectedMode,
//               transitDetails: _buildTransitDetailItems(),
//             ),

//           ..._createBuildingGestureDetectors(),
//         ],
//       ),
//     );
//   }

//   static const String _indoorMapStyle = '''
//   [
//     {
//       "featureType": "poi",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.school",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.business",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "transit",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     }
//   ]
//   ''';

//   @override
//   void dispose() {
//     _posSub?.cancel();
//     _popupDebounce?.cancel();
//     _debounceTimer?.cancel();
//     _routeDebounceTimer?.cancel();
//     _mapController?.dispose();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _originRoomController.dispose();
//     _destinationRoomController.dispose();
//     super.dispose();
//   }
// }


// class _ShuttleScheduleSheet extends StatelessWidget {
//   final String nearestStop;

//   const _ShuttleScheduleSheet({required this.nearestStop});

//   @override
//   Widget build(BuildContext context) {
//     const burgundy = Color(0xFF76263D);
//     final today = DateTime.now();
//     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
//     final isWeekday =
//         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

//     return DraggableScrollableSheet(
//       initialChildSize: 0.62,
//       minChildSize: 0.35,
//       maxChildSize: 0.92,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//           ),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 height: 4,
//                 width: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.directions_bus_filled, color: burgundy),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Concordia Shuttle Schedule',
//                             style: TextStyle(
//                               color: burgundy,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             isWeekday
//                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
//                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.of(context).maybePop(),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//               ),

//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Row(
//                   children: [
//                     _StopChip(
//                         label: 'SGW  (Hall Building)', color: burgundy),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Icon(Icons.sync_alt,
//                           size: 16, color: Colors.black45),
//                     ),
//                     _StopChip(label: 'Loyola', color: burgundy),
//                   ],
//                 ),
//               ),

//               const Divider(height: 1),

//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                   itemCount: times.length,
//                   itemBuilder: (context, index) {
//                     final t = times[index];
//                     final now = DateTime.now();
//                     final isPast = t.isBefore(now);
//                     final isNext = !isPast &&
//                         (index == 0 || times[index - 1].isBefore(now));

//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 6),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isNext
//                             ? burgundy.withOpacity(0.08)
//                             : Colors.transparent,
//                         border: isNext
//                             ? Border.all(color: burgundy.withOpacity(0.3))
//                             : null,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.directions_bus_filled,
//                             size: 16,
//                             color: isPast
//                                 ? Colors.black26
//                                 : isNext
//                                     ? burgundy
//                                     : Colors.black54,
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             ConcordiaShuttleService.formatTime(t),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: isNext
//                                   ? FontWeight.w700
//                                   : FontWeight.w400,
//                               color: isPast
//                                   ? Colors.black26
//                                   : isNext
//                                       ? burgundy
//                                       : Colors.black87,
//                             ),
//                           ),
//                           if (isNext) ...[
//                             const SizedBox(width: 10),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: burgundy,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Text(
//                                 'Next bus',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _StopChip extends StatelessWidget {
//   final String label;
//   final Color color;

//   const _StopChip({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         border: Border.all(color: color.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:pointer_interceptor/pointer_interceptor.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../shared/widgets/map_search_bar.dart';
// import '../building_detection.dart';
// import '../../data/building_polygons.dart';
// import '../../data/search_result.dart';
// import '../../data/search_suggestion.dart';
// import '../building_search_service.dart';
// import '../google_places_service.dart';
// import '../google_directions_service.dart';
// import '../../shared/widgets/campus_toggle.dart';
// import '../../shared/widgets/building_info_popup.dart';
// import '../../shared/widgets/route_preview_panel.dart';
// import '../../features/indoor/data/building_info.dart';
// import '../../services/navigation_steps.dart';
// import '../indoor_maps/indoor_floor_config.dart';
// import 'package:campus_app/utils/geo.dart' as geo;
// import '../../shared/widgets/indoor_floor_dropdown.dart';
// import '../indoor_maps/indoor_map_controller.dart';
// import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
// import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
// import 'package:campus_app/models/campus.dart';
// import '../../shared/widgets/outdoor/outdoor_map_view.dart';
// import '../indoor_maps/indoor_map_repository.dart';
// import '../../shared/widgets/outdoor/outdoor_top_search.dart';
// import '../../services/concordia_shuttle_service.dart';

// // concordia campus coordinates
// const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
// const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
// const double campusRadius = 500; // meters
// const String currentLocationTag = "Current location";

// // when camera center is within this distance auto-switch toggle
// const double campusAutoSwitchRadius = 500; // meters
// // knowing which campus the user is in
// Campus detectCampus(LatLng userLocation) {
//   final sgwDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaSGW.latitude,
//     concordiaSGW.longitude,
//   );

//   final loyolaDistance = Geolocator.distanceBetween(
//     userLocation.latitude,
//     userLocation.longitude,
//     concordiaLoyola.latitude,
//     concordiaLoyola.longitude,
//   );

//   if (sgwDistance <= campusRadius) return Campus.sgw;
//   if (loyolaDistance <= campusRadius) return Campus.loyola;
//   return Campus.none;
// }

// class OutdoorMapPage extends StatefulWidget {
//   final Campus initialCampus;
//   final bool isLoggedIn;

//   @visibleForTesting
//   final BuildingPolygon? debugSelectedBuilding;

//   @visibleForTesting
//   final Offset? debugAnchorOffset;

//   @visibleForTesting
//   final bool debugDisableMap;

//   @visibleForTesting
//   final bool debugDisableLocation;

//   @visibleForTesting
//   final String? debugLinkOverride;

//   const OutdoorMapPage({
//     super.key,
//     required this.initialCampus,
//     this.debugSelectedBuilding,
//     this.debugAnchorOffset,
//     this.debugDisableMap = false,
//     this.debugDisableLocation = false,
//     this.debugLinkOverride,
//     required this.isLoggedIn,
//   });

//   @override
//   State<OutdoorMapPage> createState() => _OutdoorMapPageState();
// }

// class _IndoorFloorOption {
//   final String label;
//   final String assetPath;

//   const _IndoorFloorOption({
//     required this.label,
//     required this.assetPath,
//   });
// }

// class _OutdoorMapPageState extends State<OutdoorMapPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _originRoomController = TextEditingController();
//   final TextEditingController _destinationRoomController = TextEditingController();
//   bool _cameraMoving = false;
//   List<SearchSuggestion> _searchSuggestions = [];
//   Timer? _debounceTimer;

//   // Indoor overlay state
//   Set<Polygon> _indoorPolygons = {};
//   bool _showIndoor = false;
//   List<IndoorFloorOption> _indoorFloors = const [];
//   String? _selectedIndoorFloorAsset;
//   final IndoorMapController _indoorController = IndoorMapController();

//   // --- Indoor floors state ---
//   String? _indoorBuildingCode; // building currently shown in indoor mode
//   String? _selectedIndoorFloorAsset; // which floor file is loaded
//   List<_IndoorFloorOption> _indoorFloors = []; // dropdown options

//   GoogleMapController? _mapController;

//   LatLng? _currentLocation;
//   BitmapDescriptor? _blueDotIcon;
//   BuildingPolygon? _currentBuildingPoly;
//   BuildingPolygon? _selectedBuildingPoly;
//   // ignore: unused_field
//   SearchResult? _selectedSearchResult;
//   // ignore: unused_field
//   Map<String, dynamic>? _indoorGeoJson;
//   Set<Marker> _roomLabelMarkers = {};

//   Set<Polyline> _routePolylines = {};

//   // Room location marker
//   Marker? _destinationRoomMarker;
//   String? _currentBuildingCode;

//   // Route preview mode
//   bool _showRoutePreview = false;
//   LatLng? _routeOrigin;
//   LatLng? _routeDestination;
//   String _routeOriginText = currentLocationTag;
//   String _routeDestinationText = '';
//   RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
//   final Map<String, String?> _routeDurations = {};
//   final Map<String, String?> _routeDistances = {};
//   final Map<String, String?> _routeArrivalTimes = {};
//   final Map<String, List<LatLng>> _routePointsByMode = {};
//   final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
//   String? _routeOriginBuildingCode;
//   String? _routeDestinationBuildingCode;

//   final Map<String, List<NavigationStep>> _routeStepsByMode = {};
//   // --- Navigation camera follow state ---
//   bool _navigationFollowUser = false;
//   DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//   static const double _navZoom = 18.0;
//   static const double _navTilt = 60.0;
//   static const double _defaultZoom = 15.0;
//   static const double _defaultTilt = 0.0;
//   static const double _defaultBearing = 0.0;
//   // ignore: unused_field
//   static const double _navBearingThresholdDegrees = 10.0;
//   // ignore: unused_field
//   static const double _navDistanceThresholdMeters = 5.0;
//   static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
//   bool _isNavigating = false;
//   String? _navModeKey;
//   int _navStepIndex = 0;
//   bool _isLoadingRouteData = false;
//   List<SearchSuggestion> _routeOriginSuggestions = [];
//   List<SearchSuggestion> _routeDestinationSuggestions = [];
//   Timer? _routeDebounceTimer;

//   // Google Directions modes only — shuttle is handled separately
//   static const List<RouteTravelMode> _supportedTravelModes = [
//     RouteTravelMode.driving,
//     RouteTravelMode.walking,
//     RouteTravelMode.bicycling,
//     RouteTravelMode.transit,
//   ];

//   List<ShuttleDeparture> _shuttleNextBuses = [];
//   int? _shuttleWalkingMinutes;
//   String _shuttleNearestStop = 'SGW';
//   BitmapDescriptor? _shuttleStopIcon;

//   StreamSubscription<Position>? _posSub;

//   Timer? _popupDebounce;

//   static const double _popupW = 300;
//   static const double _popupH = 260;

//   LatLng? _selectedBuildingCenter;
//   Offset? _anchorOffset;

//   Campus _currentCampus = Campus.none;
//   Campus _selectedCampus = Campus.none;

//   LatLng? _lastCameraTarget;

//   List<_IndoorFloorOption> _floorsForBuilding(String code) {
//     switch (code.toUpperCase()) {
//       case 'HALL':
//         return const [
//           _IndoorFloorOption(
//             label: '1',
//             assetPath: 'assets/indoor_maps/geojson/Hall/h1.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '2',
//             assetPath: 'assets/indoor_maps/geojson/Hall/h2.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '8',
//             assetPath: 'assets/indoor_maps/geojson/Hall/h8.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '9',
//             assetPath: 'assets/indoor_maps/geojson/Hall/h9.geojson.json',
//           ),
//         ];

//       case 'MB':
//         return const [
//           _IndoorFloorOption(
//             label: '1',
//             assetPath: 'assets/indoor_maps/geojson/MB/mb1.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '2',
//             assetPath: 'assets/indoor_maps/geojson/MB/mb2.geojson.json',
//           ),
//         ];

//       case 'VE':
//         return const [
//           _IndoorFloorOption(
//             label: '1',
//             assetPath: 'assets/indoor_maps/geojson/VE/ve1.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '2',
//             assetPath: 'assets/indoor_maps/geojson/VE/ve2.geojson.json',
//           ),
//         ];

//       case 'VL':
//         return const [
//           _IndoorFloorOption(
//             label: '1',
//             assetPath: 'assets/indoor_maps/geojson/VL/vl1.geojson.json',
//           ),
//           _IndoorFloorOption(
//             label: '2',
//             assetPath: 'assets/indoor_maps/geojson/VL/vl2.geojson.json',
//           ),
//         ];

//       case 'CC':
//         return const [
//           _IndoorFloorOption(
//             label: '1',
//             assetPath: 'assets/indoor_maps/geojson/CC/cc1.geojson.json',
//           ),
//         ];

//       default:
//         return const [];
//     }
//   }
//   void _clearIndoorState() {
//     _showIndoor = false;
//     _indoorFloors = const [];
//     _selectedIndoorFloorAsset = null;
//     _indoorPolygons = {};
//     _indoorGeoJson = null;
//     _roomLabelMarkers = {};
//   }

//   Campus _campusFromPoint(LatLng p) {
//     final dSgw = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaSGW.latitude,
//       concordiaSGW.longitude,
//     );

//     final dLoy = Geolocator.distanceBetween(
//       p.latitude,
//       p.longitude,
//       concordiaLoyola.latitude,
//       concordiaLoyola.longitude,
//     );

//     final minDist = dSgw < dLoy ? dSgw : dLoy;
//     if (minDist > campusAutoSwitchRadius) return Campus.none;

//     return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
//   }

//   Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
//   print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
// }

//   Future<void> _syncToggleWithCameraCenter() async {
//     if (!mounted) return;

//     LatLng? center = _lastCameraTarget;

//     if (center == null) {
//       final controller = _mapController;
//       if (controller == null) return;

//       try {
//         final bounds = await controller.getVisibleRegion();
//         final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
//         final lng =
//             (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
//         center = LatLng(lat, lng);
//       } catch (_) {
//         return;
//       }
//     }

//     final newCampus = _campusFromPoint(center);

//     if (newCampus == _selectedCampus) return;

//     setState(() {
//       _selectedCampus = newCampus;
//     });
//   }

//   List<int> _getAvailableFloorsForBuilding(String code) {
//     switch (code.toUpperCase()) {
//       case 'HALL':
//         return [1];
//       case 'MB':
//         return [1];
//       case 'VE':
//         return [1];
//       case 'VL':
//         return [1];
//       case 'CC':
//         return [1];
//       default:
//         return [];
//     }
//   }

//   String? _getIndoorAssetPath(String buildingCode, int floor) {
//     final code = buildingCode.toUpperCase();
//     switch (code) {
//       case 'HALL':
//         return 'assets/indoor_maps/geojson/Hall/h$floor.geojson.json';
//       case 'MB':
//         return 'assets/indoor_maps/geojson/MB/mb$floor.geojson.json';
//       case 'VE':
//         return 'assets/indoor_maps/geojson/VE/ve$floor.geojson.json';
//       case 'VL':
//         return 'assets/indoor_maps/geojson/VL/vl$floor.geojson.json';
//       case 'CC':
//         return 'assets/indoor_maps/geojson/CC/cc$floor.geojson.json';
//       default:
//         return null;
//     }
//   }
// bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//   return geo.pointInPolygon(point, polygon);
// }

//   Future<void> _loadIndoorFloor(String assetPath) async {
//     try {
//       final repo = IndoorMapRepository();
//       final geo = await repo.loadGeoJsonAsset(assetPath);

//       final polys = _geoJsonToPolygons(geo);
//       final labels = await _createRoomLabels(geo);

//       if (!mounted) return;
//       setState(() {
//         _showIndoor = true;
//         _selectedIndoorFloorAsset = assetPath;
//         _indoorPolygons = polys;
//         _indoorGeoJson = geo;
//         _roomLabelMarkers = labels;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load indoor floor: $e')),
//       );
//     }
//   }

//   Future<void> _loadIndoorMapForSelectedBuilding() async {
//     final b = _selectedBuildingPoly;
//     if (b == null) return;

//     final floors = _getAvailableFloorsForBuilding(b.code);
//     if (floors.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//               'Indoor map currently only available for Hall, MB, VE, VL, and CC'),
//         ),
//       );
//       return;
//     }

//     if (!mounted) return;
//     setState(() {
//       _availableFloorsForSelectedBuilding = floors;

//       if (!floors.contains(_selectedIndoorFloor)) {
//         _selectedIndoorFloor = floors.first;
//       }
//     });

//     final assetPath = _getIndoorAssetPath(b.code, _selectedIndoorFloor);
//     if (assetPath == null) return;

//     setState(() {
//       _isLoadingRouteData = false;
//     });

//     try {
//       final repo = IndoorMapRepository();
//       final geo = await repo.loadGeoJsonAsset(assetPath);

//       final polys = _geoJsonToPolygons(geo);
//       final labels = await _createRoomLabels(geo);

//       if (!mounted) return;
//       setState(() {
//         _showIndoor = true;
//         _indoorPolygons = polys;
//         _indoorGeoJson = geo;
//         _roomLabelMarkers = labels;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load indoor map: $e')),
//       );
//     }
//   }
// Future<void> _loadIndoorFloor(String assetPath) async {
//   try {
//     final result = await _indoorController.loadFloor(assetPath);
//     if (!mounted) return;
//     setState(() {
//       _showIndoor = true;
//       _selectedIndoorFloorAsset = assetPath;
//       _indoorPolygons = result.polygons;
//       _indoorGeoJson = result.geoJson;
//       _roomLabelMarkers = result.labels;
//     });
//   } catch (e) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to load indoor floor: $e')),
//     );
//   }
// }

// Future<void> _toggleIndoorMap() async {
//   // turn OFF
//   if (_showIndoor) {
//     setState(() {
//       _clearIndoorState();
//     });
//     return;
//   }
//   Future<void> _toggleIndoorMap() async {
//     if (_showIndoor) {
//       setState(() {
//         _showIndoor = false;
//         _indoorBuildingCode = null;
//         _selectedIndoorFloorAsset = null;
//         _indoorFloors = [];
//         _indoorPolygons = {};
//         _indoorGeoJson = null;
//         _roomLabelMarkers = {};
//       });
//       return;
//     }

//   // turn ON (needs selected building)
//   final b = _selectedBuildingPoly;
//   if (b == null) return;
//     final b = _selectedBuildingPoly;
//     if (b == null) return;

//   final floors = IndoorFloorConfig.floorsForBuilding(b.code);
//   if (floors.isEmpty) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('No indoor maps available for this building')),
//     );
//     return;
//   }
//     final floors = _floorsForBuilding(b.code);
//     if (floors.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Indoor map not available for this building'),
//         ),
//       );
//       return;
//     }

//   setState(() {
//     _indoorFloors = floors;
//     _selectedIndoorFloorAsset = floors.first.assetPath;
//   });
//     setState(() {
//       _indoorBuildingCode = b.code;
//       _indoorFloors = floors;
//     });

//     await _loadIndoorFloor(floors.first.assetPath);
//   }

//   Future<void> _goToMyLocation() async {
//     final controller = _mapController;
//     if (controller == null) return;

//     var loc = _currentLocation;

//     if (loc == null) {
//       try {
//         final p = await Geolocator.getCurrentPosition();
//         loc = LatLng(p.latitude, p.longitude);
//         if (mounted) setState(() => _currentLocation = loc);
//       } catch (_) {
//         return;
//       }
//     }

//     controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
//   }

//   Future<void> _openLink(String url) async {
//     if (url.trim().isEmpty) return;

//     final uri = Uri.tryParse(url);
//     if (uri == null) return;

//     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     if (!ok) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Could not open link")));
//     }
//   }

//   LatLng _polygonCenter(List<LatLng> pts) {
//     if (pts.length < 3) return pts.first;

//     double lat = 0;
//     double lng = 0;
//     for (final p in pts) {
//       lat += p.latitude;
//       lng += p.longitude;
//     }
//     final avg = LatLng(lat / pts.length, lng / pts.length);

//     if (_isPointInPolygon(avg, pts)) return avg;

//     double maxDist = 0;
//     LatLng best = avg;
//     for (int i = 0; i < pts.length; i++) {
//       for (int j = i + 1; j < pts.length; j++) {
//         final mid = LatLng(
//           (pts[i].latitude + pts[j].latitude) / 2,
//           (pts[i].longitude + pts[j].longitude) / 2,
//         );
//         final dist =
//             (pts[i].latitude - pts[j].latitude) *
//                 (pts[i].latitude - pts[j].latitude) +
//             (pts[i].longitude - pts[j].longitude) *
//                 (pts[i].longitude - pts[j].longitude);
//         if (dist > maxDist && _isPointInPolygon(mid, pts)) {
//           maxDist = dist;
//           best = mid;
//         }
//       }
//     }

//     return best;
//   }

//   bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
//     bool inside = false;
//     int j = polygon.length - 1;

//     for (int i = 0; i < polygon.length; i++) {
//       final xi = polygon[i].latitude;
//       final yi = polygon[i].longitude;
//       final xj = polygon[j].latitude;
//       final yj = polygon[j].longitude;

//       if (((yi > point.longitude) != (yj > point.longitude)) &&
//           (point.latitude <
//               (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
//         inside = !inside;
//       }
//       j = i;
//     }

//     return inside;
//   }

//   double _polygonArea(List<LatLng> pts) {
//     double area = 0;
//     int j = pts.length - 1;
//     for (int i = 0; i < pts.length; i++) {
//       area +=
//           (pts[j].longitude + pts[i].longitude) *
//           (pts[j].latitude - pts[i].latitude);
//       j = i;
//     }
//     return area.abs() / 2;
//   }

//   void _schedulePopupUpdate() {
//     _popupDebounce?.cancel();
//     _popupDebounce = Timer(
//       const Duration(milliseconds: 16),
//       _updatePopupOffset,
//     );
//   }

//   Future<void> _updatePopupOffset() async {
//     final controller = _mapController;
//     final center = _selectedBuildingCenter;
//     if (!mounted || controller == null || center == null) return;

//     final sc = await controller.getScreenCoordinate(center);
//     if (!mounted) return;

//     double x = sc.x.toDouble();
//     double y = sc.y.toDouble();

//     final dpr = MediaQuery.of(context).devicePixelRatio;
//     x = x / dpr;
//     y = y / dpr;

//     setState(() {
//       _anchorOffset = Offset(x, y);
//     });
//   }

//   // ignore: unused_element
//   void _selectBuildingWithoutMap(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
//       _cameraMoving = false;
//     });
//   }

//   void _onBuildingTapped(BuildingPolygon b) {
//     final center = geo.polygonCenter(b.points);
//     final controller = _mapController;
//     final name = buildingInfoByCode[b.code]?.name ?? b.name;

//     _searchController.value = TextEditingValue(
//       text: name,
//       selection: TextSelection.collapsed(offset: name.length),
//     );

//     setState(() {
//       _selectedBuildingPoly = b;
//       _selectedBuildingCenter = center;
//       _anchorOffset = null;
//       _cameraMoving = true;
//       _clearIndoorState();
//       _roomLabelMarkers = {};

//       _availableFloorsForSelectedBuilding =
//           _getAvailableFloorsForBuilding(b.code);
//       _selectedIndoorFloor = _availableFloorsForSelectedBuilding.isNotEmpty
//           ? _availableFloorsForSelectedBuilding.first
//           : 1;
//     });

//     if (controller == null) return;

//     controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
//       _,
//     ) async {
//       if (!mounted) return;
//       await _updatePopupOffset();
//       if (!mounted) return;
//       setState(() {
//         _cameraMoving = false;
//       });
//     });
//   }

//   void _closePopup() {
//     _clearSelectedBuilding(clearSearch: true);
//   }

//   void _clearSelectedBuilding({bool clearSearch = false}) {
//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = null;
//       _anchorOffset = null;
//       _routePolylines = {};
//       _showRoutePreview = false;
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _destinationRoomMarker = null;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//       if (clearSearch) {
//         _searchController.clear();
//       }
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//     });
//   }

//   Future<void> _getDirections() async {
//     print('[DEBUG] Get directions button clicked');
//     print('[DEBUG] Current location: $_currentLocation');
//     print(
//       '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
//     );

//     final origin = _currentLocation;
//     final destination = _selectedBuildingPoly?.center;

//     if (origin == null) {
//       print('[ERROR] Cannot get directions: Current location is null');
//       print(
//         '[ERROR] Make sure location services are enabled and location is set in emulator',
//       );
//       return;
//     }

//     if (destination == null) {
//       print('[ERROR] Cannot get directions: Destination is null');
//       return;
//     }

//     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

//     final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

//     setState(() {
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = origin;
//       _routeDestination = destination;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText =
//           '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
//       _routeOriginBuildingCode =
//           currentBuildingCode; // current location has no building code
//       _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
//       print(
//         '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
//       );
//     });

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _fetchRoutesAndDurations() async {
//     final origin = _routeOrigin;
//     final destination = _routeDestination;

//     if (origin == null || destination == null) {
//       print('[ERROR] Cannot fetch route: origin or destination is null');
//       return;
//     }

//     print(
//       '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
//     );

//     setState(() {
//       _isLoadingRouteData = true;
//     });

//     try {
//       final futures = _supportedTravelModes.map(
//         (mode) => GoogleDirectionsService.instance.getRouteDetails(
//           origin: origin,
//           destination: destination,
//           mode: mode.apiValue,
//         ),
//       );

//       final results = await Future.wait(futures);
//       final durations = <String, String?>{};
//       final distances = <String, String?>{};
//       final arrivalTimes = <String, String?>{};
//       final pointsByMode = <String, List<LatLng>>{};
//       final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
//       final stepsByMode = <String, List<NavigationStep>>{};

//       for (var i = 0; i < _supportedTravelModes.length; i++) {
//         final mode = _supportedTravelModes[i].apiValue;
//         final route = results[i];
//         durations[mode] = route?.durationText;
//         distances[mode] = route?.distanceText;
//         arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
//         stepsByMode[mode] = route?.steps ?? const [];
//         if (route != null && route.points.isNotEmpty) {
//           pointsByMode[mode] = route.points;
//         }
//         if (route != null && route.transitSegments.isNotEmpty) {
//           segmentsByMode[mode] = route.transitSegments;
//         }
//       }

//       if (!mounted) return;

//       setState(() {
//         _routeDurations
//           ..clear()
//           ..addAll(durations);
//         _routeDistances
//           ..clear()
//           ..addAll(distances);
//         _routeArrivalTimes
//           ..clear()
//           ..addAll(arrivalTimes);
//         _routePointsByMode
//           ..clear()
//           ..addAll(pointsByMode);
//         _routeSegmentsByMode
//           ..clear()
//           ..addAll(segmentsByMode);
//         _routeStepsByMode
//           ..clear()
//           ..addAll(stepsByMode);

//         _isLoadingRouteData = false;
//       });

//       _applySelectedModeRoute(animateCamera: true);

//       _fetchShuttleInfo();
//     } catch (e) {
//       print('Error getting directions: $e');
//       if (!mounted) return;
//       setState(() {
//         _isLoadingRouteData = false;
//       });
//     }
//   }

//   void _openStepsForSelectedMode() {
//     // ── NEW: shuttle uses a schedule modal instead of steps ───────────────
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       _showShuttleScheduleModal();
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     showNavigationStepsModal(
//       context,
//       title: _selectedTravelMode.label,
//       steps: steps,
//       totalDuration: _routeDurations[key],
//       totalDistance: _routeDistances[key],
//     );
//   }

//   void _applySelectedModeRoute({required bool animateCamera}) {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) return;

//     final selectedModeKey = _selectedTravelMode.apiValue;
//     final selectedSegments = _routeSegmentsByMode[selectedModeKey];
//     if (_selectedTravelMode == RouteTravelMode.transit &&
//         selectedSegments != null &&
//         selectedSegments.isNotEmpty) {
//       _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
//       return;
//     }

//     final selectedPoints = _routePointsByMode[selectedModeKey];

//     if (selectedPoints == null || selectedPoints.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = {
//         Polyline(
//           polylineId: const PolylineId('route'),
//           points: selectedPoints,
//           color: const Color(0xFF76263D),
//           width: 5,
//           patterns: _selectedTravelMode == RouteTravelMode.driving
//               ? const []
//               : [PatternItem.dot, PatternItem.gap(10)],
//         ),
//       };
//     });

//     if (!animateCamera || _mapController == null) return;
//     final bounds = geo.calculateBounds(selectedPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _applyTransitSegments(
//     List<DirectionsRouteSegment> segments, {
//     required bool animateCamera,
//   }) {
//     final polylines = <Polyline>{};
//     final allPoints = <LatLng>[];

//     for (var i = 0; i < segments.length; i++) {
//       final segment = segments[i];
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       allPoints.addAll(segment.points);

//       final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
//       polylines.add(
//         Polyline(
//           polylineId: PolylineId('route_segment_$i'),
//           points: segment.points,
//           color: _resolveTransitSegmentColor(segment),
//           width: 5,
//           patterns: isWalking
//               ? [PatternItem.dot, PatternItem.gap(10)]
//               : const [],
//         ),
//       );
//     }

//     if (polylines.isEmpty) {
//       setState(() {
//         _routePolylines = {};
//       });
//       return;
//     }

//     setState(() {
//       _routePolylines = polylines;
//     });

//     if (!animateCamera || _mapController == null || allPoints.isEmpty) {
//       return;
//     }

//     final bounds = geo.calculateBounds(allPoints);
//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//   }

//   void _startNavigation() {
//     if (_selectedTravelMode == RouteTravelMode.shuttle) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
//           ),
//           duration: Duration(seconds: 3),
//         ),
//       );
//       return;
//     }

//     final key = _selectedTravelMode.apiValue;
//     final steps = _routeStepsByMode[key] ?? const [];

//     if (steps.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No steps available for this route')),
//         );
//       }
//       return;
//     }

//     setState(() {
//       _isNavigating = true;
//       _navModeKey = key;
//       _navStepIndex = 0;

//       _navigationFollowUser = true;
//       _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
//     });

//     if (_currentLocation != null && _mapController != null) {
//       try {
//         final currentPos = _currentLocation!;
//         final initialCam = CameraPosition(
//           target: currentPos,
//           zoom: _navZoom,
//           tilt: _navTilt,
//           bearing: 0.0,
//         );
//         _mapController!.animateCamera(
//           CameraUpdate.newCameraPosition(initialCam),
//         );
//       } catch (e) {
//         print('Error animating camera when starting navigation: $e');
//       }
//     }
//   }

//   void _stopNavigation() {
//     setState(() {
//       _isNavigating = false;
//       _navModeKey = null;
//       _navStepIndex = 0;
//       _navigationFollowUser = false;
//     });
//     if (_mapController != null && _currentLocation != null) {
//       try {
//         final cam = CameraPosition(
//           target: _currentLocation!,
//           zoom: _defaultZoom,
//           tilt: _defaultTilt,
//           bearing: _defaultBearing,
//         );

//         _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//       } catch (e) {
//         print('Error resetting camera after navigation: $e');
//       }
//     }

//     _closeRoutePreview();
//   }

//   void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
//     if (_mapController == null) return;
//     if (!_navigationFollowUser) return;

//     final now = DateTime.now();

//     if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
//       return;
//     }

//     double bearing = 0.0;
//     if (heading != null && heading >= 0.0) {
//       bearing = heading;
//     }

//     final cam = CameraPosition(
//       target: userLatLng,
//       zoom: _navZoom,
//       tilt: _navTilt,
//       bearing: bearing,
//     );

//     try {
//       _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
//     } catch (e) {
//       print('Error animating navigation camera: $e');
//     }
//   }

//   void _maybeAdvanceNavigationStep(LatLng user) {
//     final key = _navModeKey;
//     if (key == null) return;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return;

//     if (_navStepIndex >= steps.length - 1) return;

//     final current = steps[_navStepIndex];
//     final end = current.endPoint;
//     if (end == null) return;

//     final d = Geolocator.distanceBetween(
//       user.latitude,
//       user.longitude,
//       end.latitude,
//       end.longitude,
//     );

//     if (d <= 20) {
//       setState(() => _navStepIndex += 1);
//     }
//   }

//   void _closeRoutePreview() {
//     setState(() {
//       _showRoutePreview = false;
//       _routePolylines = {};
//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//       _routeDurations.clear();
//       _routeDistances.clear();
//       _routeArrivalTimes.clear();
//       _routePointsByMode.clear();
//       _routeSegmentsByMode.clear();
//       _isLoadingRouteData = false;
//       _selectedTravelMode = RouteTravelMode.driving;
//       _searchController.clear();

//       //reset indoor map and building selection state
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _destinationRoomMarker = null;
//       _originRoomController.clear();
//       _destinationRoomController.clear();
//       _routeOriginBuildingCode = null;
//       _routeDestinationBuildingCode = null;
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//     });
//   }

//   String? _formatArrivalTime(int? durationSeconds) {
//     if (durationSeconds == null) {
//       return null;
//     }

//     final now = DateTime.now();
//     final arrival = now.add(Duration(seconds: durationSeconds));
//     int hour = arrival.hour;
//     final minute = arrival.minute.toString().padLeft(2, '0');
//     final isPm = hour >= 12;
//     final period = isPm ? 'pm' : 'am';
//     hour = hour % 12;
//     if (hour == 0) {
//       hour = 12;
//     }
//     return '$hour:$minute $period';
//   }

//   Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
//     const defaultRed = Color(0xFF76263D);
//     final mode = segment.travelMode.toUpperCase();
//     if (mode == 'WALKING') {
//       return defaultRed;
//     }

//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Colors.blue;
//     }

//     final lineColor = parseHexColor(segment.transitLineColorHex);
//     if (lineColor != null) {
//       return lineColor;
//     }

//     return defaultRed;
//   }

//   List<TransitDetailItem> _buildTransitDetailItems() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     final items = <TransitDetailItem>[];

//     for (final segment in segments) {
//       if (segment.points.isEmpty) {
//         continue;
//       }

//       final travelMode = segment.travelMode.toUpperCase();
//       if (travelMode == 'WALKING') {
//         continue;
//       }

//       final vehicleType = segment.transitVehicleType?.toUpperCase();
//       final lineLabel =
//           segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
//       final color = _resolveTransitSegmentColor(segment);

//       IconData icon = Icons.directions_transit;
//       String title = 'Transit $lineLabel';

//       if (vehicleType == 'BUS') {
//         icon = Icons.directions_bus;
//         title = 'Bus $lineLabel';
//       } else if (vehicleType == 'SUBWAY' ||
//           vehicleType == 'METRO_RAIL' ||
//           vehicleType == 'HEAVY_RAIL' ||
//           vehicleType == 'COMMUTER_TRAIN' ||
//           vehicleType == 'RAIL' ||
//           vehicleType == 'TRAM' ||
//           vehicleType == 'LIGHT_RAIL' ||
//           vehicleType == 'MONORAIL') {
//         icon = Icons.directions_subway;
//         title = 'Metro $lineLabel';
//       }

//       items.add(TransitDetailItem(icon: icon, color: color, title: title));
//     }

//     return items;
//   }

//   // ignore: unused_element
//   List<DirectionsRouteSegment> _getTransitDetailSegments() {
//     final segments = _routeSegmentsByMode['transit'] ?? const [];
//     return segments
//         .where(
//           (segment) =>
//               segment.travelMode.toUpperCase() == 'TRANSIT' &&
//               segment.points.isNotEmpty,
//         )
//         .toList();
//   }

//   String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     final lineLabel =
//         segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

//     if (vehicleType == 'BUS') {
//       return 'Bus $lineLabel';
//     }

//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return 'Metro $lineLabel';
//     }

//     return 'Transit $lineLabel';
//   }

//   IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
//     final vehicleType = segment.transitVehicleType?.toUpperCase();
//     if (vehicleType == 'BUS') {
//       return Icons.directions_bus;
//     }
//     if (vehicleType == 'SUBWAY' ||
//         vehicleType == 'METRO_RAIL' ||
//         vehicleType == 'HEAVY_RAIL' ||
//         vehicleType == 'COMMUTER_TRAIN' ||
//         vehicleType == 'RAIL' ||
//         vehicleType == 'TRAM' ||
//         vehicleType == 'LIGHT_RAIL' ||
//         vehicleType == 'MONORAIL') {
//       return Icons.directions_subway;
//     }
//     return Icons.directions_transit;
//   }

//   // ignore: unused_element
//   Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
//     const burgundy = Color(0xFF76263D);

//     return Container(
//       width: 340,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.15),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'Transit details',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: burgundy,
//             ),
//           ),
//           const SizedBox(height: 6),
//           for (final segment in segments)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 6),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(
//                     _transitSegmentIcon(segment),
//                     size: 16,
//                     color: _resolveTransitSegmentColor(segment),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _formatTransitSegmentTitle(segment),
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         if (segment.transitHeadsign != null &&
//                             segment.transitHeadsign!.trim().isNotEmpty)
//                           Text(
//                             segment.transitHeadsign!,
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Colors.black54,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Color? parseHexColor(String? hex) {
//     if (hex == null || hex.trim().isEmpty) {
//       return null;
//     }

//     final normalized = hex.trim().replaceFirst('#', '');
//     if (normalized.length != 6) {
//       return null;
//     }

//     final value = int.tryParse(normalized, radix: 16);
//     if (value == null) {
//       return null;
//     }

//     return Color(0xFF000000 | value);
//   }

//   void _switchOriginDestination() {
//     setState(() {
//       final tempOrigin = _routeOriginText;
//       final tempOriginLatLng = _routeOrigin;
//       final tempDestination = _routeDestinationText;
//       final tempDestinationLatLng = _routeDestination;

//       _routeOriginText = tempDestination;
//       _routeOrigin = tempDestinationLatLng;
//       _routeDestinationText = tempOrigin;
//       _routeDestination = tempOriginLatLng;

//       _routeOriginSuggestions = [];
//       _routeDestinationSuggestions = [];
//     });

//     _fetchRoutesAndDurations();
//   }

//   void _onTravelModeSelected(RouteTravelMode mode) {
//     setState(() {
//       _selectedTravelMode = mode;
//     });

//     if (mode == RouteTravelMode.shuttle) {
//       _fetchShuttleInfo();
//       return;
//     }

//     if (_routePointsByMode.containsKey(mode.apiValue)) {
//       _applySelectedModeRoute(animateCamera: false);
//       return;
//     }

//     _fetchRoutesAndDurations();
//   }


//   ///shuttle stop marker icon
//   Future<void> _createShuttleStopIcon() async {
//   _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
//     const ImageConfiguration(size: Size(600, 600)),
//     'assets/images/shuttle_icon.png',
//   );
// }

//   ///walking time + 4 next buses 
//   Future<void> _fetchShuttleInfo() async {
//     final origin = _routeOrigin ?? _currentLocation;

//     if (origin == null) {
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//       return;
//     }

//     setState(() {
//       _shuttleNextBuses = [];
//       _shuttleWalkingMinutes = null;
//     });

//     try {
//       final nearestStop = ConcordiaShuttleService.nearestStop(origin);
//       final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

//       int walkingSeconds = 0;
//       List<LatLng> walkPoints = [];

//       final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
//         origin: origin,
//         destination: stopLatLng,
//         mode: 'walking',
//       );

//       if (walkRoute != null) {
//         walkingSeconds = walkRoute.durationSeconds ?? 0;
//         walkPoints = walkRoute.points;
//       }

//       final walkingMinutes = (walkingSeconds / 60).ceil();

//       final buses = ConcordiaShuttleService.getNextDepartures(
//         fromStop: nearestStop,
//         now: DateTime.now(),
//         count: 4,
//         walkingDuration: Duration(seconds: walkingSeconds),
//       );

//       String shuttleDurationLabel;
//       if (!ConcordiaShuttleService.isInService()) {
//         shuttleDurationLabel = 'No service';
//       } else if (buses.isNotEmpty) {
//         shuttleDurationLabel = buses.first.statusLabel;
//       } else {
//         shuttleDurationLabel = '–';
//       }

//       if (walkPoints.isNotEmpty) {
//         setState(() {
//           _routePolylines = {
//             Polyline(
//               polylineId: const PolylineId('shuttle_walk'),
//               points: walkPoints,
//               color: const Color(0xFF76263D),
//               width: 5,
//               patterns: [PatternItem.dot, PatternItem.gap(10)],
//             ),
//           };
//         });

//         if (_mapController != null) {
//           final bounds = _calculateBounds([...walkPoints, stopLatLng]);
//           _mapController!
//               .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
//         }
//       } else {
//         setState(() {
//           _routePolylines = {};
//         });
//       }

//       if (!mounted) return;
//       setState(() {
//         _shuttleNearestStop = nearestStop;
//         _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
//         _shuttleNextBuses = buses;
//         _routeDurations['shuttle'] = shuttleDurationLabel;
//       });
//     } catch (e) {
//       print('Error fetching shuttle info: $e');
//       if (!mounted) return;
//       setState(() {
//         _routeDurations['shuttle'] = '–';
//       });
//     }
//   }

//   //open full day schedule 
//   void _showShuttleScheduleModal() {
//     showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) =>
//           _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
//     );
//   }


//   Future<void> _onRouteOriginChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeOriginSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeOriginSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for origin: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} origin suggestions');
//         if (mounted) {
//           setState(() {
//             _routeOriginSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting origin suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteDestinationChanged(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() {
//         _routeDestinationSuggestions = [];
//       });
//       return;
//     }

//     setState(() {
//       _routeDestinationSuggestions = [];
//     });

//     _routeDebounceTimer?.cancel();
//     _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       try {
//         print('[DEBUG] Searching for destination: $query');
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         print('[DEBUG] Found ${suggestions.length} destination suggestions');
//         if (mounted) {
//           setState(() {
//             _routeDestinationSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('[ERROR] Error getting destination suggestions: $e');
//       }
//     });
//   }

//   Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
//     print(
//       '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
//     );
//     LatLng? newOrigin;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       print('[DEBUG] Handling Concordia building');
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newOrigin = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//       print('[DEBUG] Concordia building origin: $newOrigin');
//     } else if (suggestion.placeId != null) {
//       print(
//         '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
//       );
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         print('[DEBUG] Place details result: $placeDetails');
//         if (placeDetails != null) {
//           newOrigin = placeDetails.location;
//           buildingCode = null;
//           print('[DEBUG] Non-Concordia origin location: $newOrigin');
//         } else {
//           print(
//             '[ERROR] Place details returned null for ${suggestion.placeId}',
//           );
//         }
//       } catch (e) {
//         print('[ERROR] Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newOrigin != null) {
//       print('[DEBUG] Updating route origin state');
//       print('[DEBUG] New origin building code: $buildingCode');
//       setState(() {
//         _routeOrigin = newOrigin;
//         _routeOriginText = displayText;
//         _routeOriginSuggestions = [];
//         _routeOriginBuildingCode = buildingCode;
//         _originRoomController.clear();
//       });
//       print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
//       await _fetchRoutesAndDurations();
//     } else {
//       print('[ERROR] Could not determine origin location');
//     }
//   }

//   Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
//     LatLng? newDestination;
//     String displayText = suggestion.name;
//     String? buildingCode;

//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final building = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       newDestination = building?.center;
//       displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
//       buildingCode = suggestion.buildingName!.code;
//     } else if (suggestion.placeId != null) {
//       try {
//         final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//           suggestion.placeId!,
//         );
//         if (placeDetails != null) {
//           newDestination = placeDetails.location;
//           buildingCode = null;
//         }
//       } catch (e) {
//         print('Error fetching place details: $e');
//         return;
//       }
//     }

//     if (newDestination != null) {
//       print('[DEBUG] Updating route destination state');
//       print('[DEBUG] New destination building code: $buildingCode');
//       setState(() {
//         _routeDestination = newDestination;
//         _routeDestinationText = displayText;
//         _routeDestinationSuggestions = [];
//         _routeDestinationBuildingCode = buildingCode;
//         _destinationRoomController.clear();
//       });
//       await _fetchRoutesAndDurations();
//     }
//   }

//   void _hideBuildingPopup() {
//     if (_selectedBuildingPoly == null) return;

//     _clearSelectedBuilding();
//   }

//   Future<void> _onSearchSubmitted(String query) async {
//     if (query.trim().isEmpty) return;

//     final concordiaBuilding = BuildingSearchService.searchBuilding(query);

//     if (concordiaBuilding != null) {
//       _onBuildingTapped(concordiaBuilding);
//       return;
//     }

//     final results = await BuildingSearchService.searchWithGooglePlaces(
//       query,
//       userLocation: _currentLocation,
//     );

//     if (results.isNotEmpty) {
//       SearchResult? selectedResult;

//       for (final result in results) {
//         if (!result.isConcordiaBuilding) {
//           selectedResult = result;
//           break;
//         }
//       }

//       if (selectedResult == null && results.isNotEmpty) {
//         selectedResult = results.first;
//       }

//       if (selectedResult != null) {
//         if (selectedResult.isConcordiaBuilding &&
//             selectedResult.buildingPolygon != null) {
//           _onBuildingTapped(selectedResult.buildingPolygon!);
//         } else {
//           _onPlaceSelected(selectedResult);
//         }
//       }
//     } else {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('"$query" not found'),
//           duration: const Duration(seconds: 2),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//       _searchController.clear();
//     }
//   }

//   void _onPlaceSelected(SearchResult result) {
//     final controller = _mapController;
//     if (controller == null) return;

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _selectedSearchResult = result;
//     });

//     _searchController.value = TextEditingValue(
//       text: result.name,
//       selection: TextSelection.collapsed(offset: result.name.length),
//     );

//     if (result.isConcordiaBuilding) {
//       controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('${result.name} is a Concordia building'),
//           duration: const Duration(seconds: 3),
//           backgroundColor: const Color(0xFF800020),
//         ),
//       );
//     } else {
//       if (_currentLocation == null) {
//         controller.animateCamera(
//           CameraUpdate.newLatLngZoom(result.location, 18),
//         );
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${result.name} is not a Concordia building'),
//             duration: const Duration(seconds: 2),
//             backgroundColor: Colors.grey[700],
//           ),
//         );
//       } else {
//         _enterRoutePreviewForPlace(result);
//       }
//     }
//   }

//   Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
//     if (_currentLocation == null) return;

//     print(
//       '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
//     );

//     setState(() {
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _showRoutePreview = true;
//       _routeOrigin = _currentLocation;
//       _routeDestination = place.location;
//       _routeOriginText = currentLocationTag;
//       _routeDestinationText = place.name;
//       _selectedSearchResult = place;
//     });

//     print(
//       '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
//     );

//     await _fetchRoutesAndDurations();
//   }

//   Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
//     if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
//       final buildingPolygon = BuildingSearchService.searchBuilding(
//         suggestion.buildingName!.code,
//       );
//       if (buildingPolygon == null) return;
//       _onBuildingTapped(buildingPolygon);
//     } else if (suggestion.placeId != null) {
//       final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
//         suggestion.placeId!,
//       );
//       if (placeDetails != null) {
//         final concordiaBuilding = BuildingSearchService.searchBuilding(
//           suggestion.name,
//         );

//         if (concordiaBuilding != null) {
//           _onBuildingTapped(concordiaBuilding);
//         } else {
//           final searchResult = SearchResult.fromGooglePlace(
//             name: placeDetails.name,
//             address: placeDetails.formattedAddress,
//             location: placeDetails.location,
//             isConcordiaBuilding: false,
//             placeId: placeDetails.placeId,
//           );
//           _onPlaceSelected(searchResult);
//         }
//       }
//     }
//   }

//   Set<Polygon> _createBuildingPolygons() {
//     const burgundy = Color(0xFF800020);
//     const selectedBlue = Color(0xFF7F83C3);

//     final polys = <Polygon>{};

//     for (final b in buildingPolygons) {
//       final isCurrent = _currentBuildingPoly?.code == b.code;
//       final isSelected = _selectedBuildingPoly?.code == b.code;

//       final strokeColor = isSelected
//           ? selectedBlue.withOpacity(0.95)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.8)
//           : burgundy.withOpacity(0.55);

//       final fillColor = isSelected
//           ? selectedBlue.withOpacity(0.25)
//           : isCurrent
//           ? Colors.blue.withOpacity(0.25)
//           : burgundy.withOpacity(0.22);

//       final strokeWidth = isSelected
//           ? 3
//           : isCurrent
//           ? 3
//           : 2;
//       final zIndex = isSelected
//           ? 3
//           : isCurrent
//           ? 2
//           : 1;

//       polys.add(
//         Polygon(
//           polygonId: PolygonId('poly_${b.code}'),
//           points: b.points,
//           strokeWidth: strokeWidth,
//           strokeColor: strokeColor,
//           fillColor: fillColor,
//           zIndex: zIndex,
//           consumeTapEvents: true,
//           onTap: () => _onBuildingTapped(b),
//         ),
//       );
//     }

//     return polys;
//   }

//   List<Widget> _createBuildingGestureDetectors() {
//     final detectors = <Widget>[];

//     for (final building in buildingPolygons) {
//       detectors.add(
//         Positioned(
//           left: 0,
//           top: 0,
//           child: GestureDetector(
//             key: Key('building_detector_${building.code}'),
//             onTap: () => _onBuildingTapped(building),
//             child: Container(
//               width: 100,
//               height: 100,
//               color: Colors.transparent,
//             ),
//           ),
//         ),
//       );
//     }

//     return detectors;
//   }

//   @override
//   void initState() {
//     super.initState();

//     _selectedCampus = widget.initialCampus;

//     _lastCameraTarget = widget.initialCampus == Campus.loyola
//         ? concordiaLoyola
//         : concordiaSGW;

//     _createBlueDotIcon();
//     _createShuttleStopIcon(); // NEW
//     _startLocationUpdates();
//     _determineUserLocationAndBuilding().then((_) {
//       _startLocationUpdates();
//     });

//     _searchController.addListener(_onSearchChanged);
//     // Clear destination room marker when room input changes
//     _destinationRoomController.addListener(_onDestinationRoomTextChanged);
//     _determineUserLocationAndBuilding();
//   }

//   Future<void> _determineUserLocationAndBuilding() async {
//     // Get user's current location
//     final position = await Geolocator.getCurrentPosition();
//     _currentLocation = LatLng(position.latitude, position.longitude);

//     // Check which building polygon contains the user
//     final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

//     setState(() {
//       _currentBuildingCode = buildingAtLocation?.code;
//     });
//   }

//   BuildingPolygon? _findBuildingAtLocation(LatLng location) {
//     for (final building in buildingPolygons) {
//       if (_isPointInPolygon(location, building.points)) {
//         return building;
//       }
//     }
//     return null;
//   }

//   void _onDestinationRoomTextChanged() {
//     if (_destinationRoomMarker == null) return;

//     setState(() {
//       _destinationRoomMarker = null;
//     });
//   }

//   void _onSearchChanged() {
//     _debounceTimer?.cancel();

//     _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
//       final query = _searchController.text;
//       try {
//         final suggestions = await BuildingSearchService.getCombinedSuggestions(
//           query,
//           userLocation: _currentLocation,
//         );
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = suggestions;
//           });
//         }
//       } catch (e) {
//         print('Error getting search suggestions: $e');
//         if (mounted) {
//           setState(() {
//             _searchSuggestions = BuildingSearchService.getSuggestions(
//               query,
//             ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
//           });
//         }
//       }
//     });
//   }

//   Future<void> _createBlueDotIcon() async {
//     _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
//       BitmapDescriptor.hueAzure,
//     );
//   }

//   Future<void> _startLocationUpdates() async {
//     print('[DEBUG] Starting location updates...');

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     print('[DEBUG] Location service enabled: $serviceEnabled');

//     if (!serviceEnabled) {
//       print('[ERROR] Location services are disabled');
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     print('[DEBUG] Initial permission status: $permission');

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       print('[DEBUG] Permission after request: $permission');
//       if (permission == LocationPermission.denied) {
//         print('[ERROR] Location permission denied by user');
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       print('[ERROR] Location permission denied forever');
//       return;
//     }

//     try {
//       print('[DEBUG] Attempting to get current position...');
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//           timeLimit: Duration(seconds: 10),
//         ),
//       );
//       final newLatLng = LatLng(position.latitude, position.longitude);

//       print(
//         '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
//       );
//       print('[DEBUG] Location accuracy: ${position.accuracy} meters');

//       if (!mounted) return;
//       setState(() {
//         _currentLocation = newLatLng;
//         _currentCampus = detectCampus(newLatLng);
//         _currentBuildingPoly = detectBuildingPoly(newLatLng);
//       });

//       print('[DEBUG] Current campus: $_currentCampus');
//       print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

//       _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
//     } catch (e) {
//       print('[ERROR] Failed to get current position: $e');
//       print(
//         '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
//       );
//     }

//     _posSub =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.best,
//             distanceFilter: 5,
//           ),
//         ).listen((position) {
//           final newLatLng = LatLng(position.latitude, position.longitude);
//           print(
//             '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
//           );

//           final buildingAtLocation = _findBuildingAtLocation(newLatLng);

//           if (!mounted) return;
//           setState(() {
//             _currentLocation = newLatLng;
//             _currentCampus = detectCampus(newLatLng);
//             _currentBuildingPoly = detectBuildingPoly(newLatLng);
//             _currentBuildingCode = buildingAtLocation?.code;
//           });

//           if (_isNavigating) {
//             _maybeAdvanceNavigationStep(newLatLng);
//           }
//           if (_navigationFollowUser) {
//             _maybeUpdateCameraForNavigation(newLatLng, position.heading);
//           }
//         });
//   }

//   Set<Marker> _createMarkers() {
//     final markers = <Marker>{};
//     // Add current location marker
//     if (_currentLocation != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: _currentLocation!,
//           icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           zIndex: 999,
//         ),
//       );
//     }

//     // Add destination room marker only when indoor map is shown
//     if (_destinationRoomMarker != null && _showIndoor) {
//       markers.add(_destinationRoomMarker!);
//     }
//     final shuttleIcon = _shuttleStopIcon;
//     if (shuttleIcon != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_sgw'),
//           position: shuttleStopSGW,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — SGW',
//             snippet: 'Hall Building stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//       markers.add(
//         Marker(
//           markerId: const MarkerId('shuttle_stop_loyola'),
//           position: shuttleStopLoyola,
//           icon: shuttleIcon,
//           infoWindow: const InfoWindow(
//             title: 'Concordia Shuttle — Loyola',
//             snippet: 'Loyola campus stop',
//           ),
//           onTap: () {
//             if (_showRoutePreview) {
//               setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
//               _fetchShuttleInfo();
//             }
//           },
//         ),
//       );
//     }

//     if (_showRoutePreview) {
//       if (_routeDestination != null) {
//         markers.add(
//           Marker(
//             markerId: const MarkerId('route_destination'),
//             position: _routeDestination!,
//             infoWindow: InfoWindow(title: _routeDestinationText),
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//               BitmapDescriptor.hueRed,
//             ),
//           ),
//         );
//       }
//     }

//     return markers;
//   }

//   Set<Circle> _createCircles() {
//     final circles = <Circle>{};

//     if (_currentLocation == null) return {};

//     circles.add(
//       Circle(
//         circleId: const CircleId('current_location_accuracy'),
//         center: _currentLocation!,
//         radius: 20,
//         fillColor: Colors.blue.withOpacity(0.1),
//         strokeColor: Colors.blue.withOpacity(0.3),
//         strokeWidth: 1,
//       ),
//     );

//     if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
//       final segments = _routeSegmentsByMode['transit'] ?? const [];
//       final seen = <String>{};

//       for (final segment in segments) {
//         if (segment.travelMode.toUpperCase() != 'TRANSIT') {
//           continue;
//         }
//         if (segment.points.isEmpty) {
//           continue;
//         }

//         final endpoints = [segment.points.first, segment.points.last];
//         for (final point in endpoints) {
//           final key =
//               '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
//           if (!seen.add(key)) {
//             continue;
//           }

//           circles.add(
//             Circle(
//               circleId: CircleId('transit_stop_$key'),
//               center: point,
//               radius: 15,
//               fillColor: Colors.white,
//               strokeColor: const Color(0xFF76263D),
//               strokeWidth: 2,
//             ),
//           );
//         }
//       }
//     }

//     return circles;
//   }

//   NavigationStep? _getCurrentNavStep() {
//     final key = _navModeKey;
//     if (key == null) return null;

//     final steps = _routeStepsByMode[key] ?? const [];
//     if (steps.isEmpty) return null;

//     if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
//     return steps[_navStepIndex];
//   }

//   void _switchCampus(Campus newCampus) {
//     LatLng targetLocation;

//     switch (newCampus) {
//       case Campus.sgw:
//         targetLocation = concordiaSGW;
//         break;
//       case Campus.loyola:
//         targetLocation = concordiaLoyola;
//         break;
//       case Campus.none:
//         return;
//     }

//     _lastCameraTarget = targetLocation;
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(targetLocation, 16),
//     );

//     setState(() {
//       _selectedCampus = newCampus;
//       _selectedBuildingPoly = null;
//       _selectedBuildingCenter = null;
//       _anchorOffset = null;
//       _cameraMoving = false;
//       _searchController.clear();
//     });
//   }

//   Offset? _computePopupPosition(BuildContext context) {
//   final screen = MediaQuery.of(context).size;
//   final topPad = MediaQuery.of(context).padding.top;

//   final anchor = widget.debugAnchorOffset ?? _anchorOffset;
//   if (anchor == null || _cameraMoving) return null;

//   final ax = anchor.dx;
//   final ay = anchor.dy;

//   final inView =
//       ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
//   if (!inView) return null;

//   double left = ax - (_popupW / 2);
//   double top = ay - (_popupH / 2);

//   const margin = 8.0;
//   final minLeft = margin;
//   final maxLeft = screen.width - _popupW - margin;
//   final minTop = topPad + margin;
//   final maxTop = screen.height - _popupH - margin;

//   if (left < minLeft) left = minLeft;
//   if (left > maxLeft) left = maxLeft;
//   if (top < minTop) top = minTop;
//   if (top > maxTop) top = maxTop;

//   return Offset(left, top);
// }

//   Future<void> _onDestinationRoomSubmitted(
//     String buildingCode,
//     String roomCode,
//   ) async {
//     print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

//     try {
//       final repo = IndoorMapRepository();
//       final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

//       if (roomLocation == null) {
//         print('[ERROR] Could not find location for room $roomCode');
//         return;
//       }
//       print('[DEBUG] Room location found: $roomLocation');
//       // Create marker at room location
//       final marker = Marker(
//         markerId: const MarkerId('destination_room'),
//         position: roomLocation,
//         infoWindow: InfoWindow(title: 'Room $roomCode'),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       );

//       // Update state with the new marker
//       if (!mounted) return;
//       setState(() {
//         _destinationRoomMarker = marker;
//       });

//       print('[DEBUG] Destination room marker placed at $roomLocation');
//     } catch (e) {
//       print('[ERROR] Error processing destination room: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: const Color(0xFFE53935),
//         ),
//       );
//     }
//   }

//   @override
// Widget build(BuildContext context) {
//   final LatLng initialTarget =
//       widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

//   final Campus labelCampus =
//       _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

//   final String campusLabel = labelCampus == Campus.sgw
//       ? 'SGW'
//       : labelCampus == Campus.loyola
//           ? 'Loyola'
//           : '';

//   final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
//   final popupPos = _computePopupPosition(context);

//   return Scaffold(
//     body: Stack(
//       children: [
//         if (widget.debugDisableMap)
//           const SizedBox.expand()
//         else
//           OutdoorMapView(
//             initialTarget: initialTarget,
//             showIndoorStyle: _showIndoor,
//             indoorMapStyle: _indoorMapStyle,
//             onMapCreated: (c) => _mapController = c,
//             onCameraMove: (pos) {
//               _lastCameraTarget = pos.target;
//               if (_selectedBuildingCenter != null) _schedulePopupUpdate();
//             },
//             onCameraMoveStarted: () {
//               if (_selectedBuildingCenter == null) return;
//               setState(() => _cameraMoving = true);
//             },
//             onCameraIdle: () {
//               _syncToggleWithCameraCenter();
//               if (_selectedBuildingCenter == null) return;
//               setState(() => _cameraMoving = false);
//               _updatePopupOffset();
//             },
//             markers: {
//               ..._createMarkers(),
//               ..._roomLabelMarkers,
//             },
//             circles: _createCircles(),
//             polygons: {
//               ..._createBuildingPolygons(),
//               ..._indoorPolygons,
//             },
//             polylines: _routePolylines,
//           ),

//           if (_isNavigating)
//             Positioned(
//               top: 80,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: NavigationNextStepHeader(
//                   modeLabel: _selectedTravelMode.label,
//                   nextStep: _getCurrentNavStep(),
//                   onStop: _stopNavigation,
//                   onShowSteps: _openStepsForSelectedMode,
//                 ),
//               ),
//             ),
//           if (!_showRoutePreview && !_isNavigating)
//             Positioned(
//               top: 65,
//               left: 20,
//               right: 20,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   MapSearchBar(
//                     key: const Key('destination_search_bar'),
//                     campusLabel: campusLabel,
//                     controller: _searchController,
//                     onSubmitted: _onSearchSubmitted,
//                     suggestions: _searchSuggestions,
//                     onSuggestionSelected: _onSuggestionSelected,
//                     onFocus: _hideBuildingPopup,
//                   ),
//                   if (_showIndoor && _indoorFloors.isNotEmpty) ...[
//                     const SizedBox(height: 10),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: PointerInterceptor(
//                         child: IntrinsicWidth(
//                           child: Container(
//                             height: 40,
//                             padding:
//                                 const EdgeInsets.symmetric(horizontal: 12),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF8B1D3B),
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.25),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               child: DropdownButtonHideUnderline(
//                                 child: DropdownButton<String>(
//                                   value: _selectedIndoorFloorAsset ??
//                                       _indoorFloors.first.assetPath,
//                                   isDense: true,
//                                   dropdownColor: const Color(0xFF8B1D3B),
//                                   icon: const Icon(
//                                     Icons.keyboard_arrow_down,
//                                     color: Colors.white,
//                                   ),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                   items: _indoorFloors
//                                       .map(
//                                         (f) => DropdownMenuItem<String>(
//                                           value: f.assetPath,
//                                           child: Text(
//                                             f.label,
//                                             style: const TextStyle(
//                                                 color: Colors.white),
//                                           ),
//                                         ),
//                                       )
//                                       .toList(),
//                                   onChanged: (asset) async {
//                                     if (asset == null) return;
//                                     await _loadIndoorFloor(asset);
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           if ((widget.debugSelectedBuilding ?? _selectedBuildingPoly) != null &&
//               popupLeft != null &&
//               popupTop != null)
//             Positioned(
//               left: popupLeft,
//               top: popupTop,
//               child: PointerInterceptor(
//                 child: BuildingInfoPopup(
//                   title:
//                       '${buildingInfoByCode[(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code]?.name ?? (widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.name} - ${(widget.debugSelectedBuilding ?? _selectedBuildingPoly)!.code}',
//                   description:
//                       buildingInfoByCode[(widget.debugSelectedBuilding ??
//                                   _selectedBuildingPoly)!
//                               .code]
//                           ?.description ??
//                       'No description available.',
//                   accessibility:
//                       buildingInfoByCode[(widget.debugSelectedBuilding ??
//                                   _selectedBuildingPoly)!
//                               .code]
//                           ?.accessibility ??
//                       false,
//                   facilities:
//                       buildingInfoByCode[(widget.debugSelectedBuilding ??
//                                   _selectedBuildingPoly)!
//                               .code]
//                           ?.facilities ??
//                       const [],
//                   onMore: () {
//                     final link =
//                         widget.debugLinkOverride ??
//                         (buildingInfoByCode[(widget.debugSelectedBuilding ??
//                                         _selectedBuildingPoly)!
//                                     .code]
//                                 ?.link ??
//                             '');
//                     _openLink(link);
//                   },
//                   onClose: _closePopup,
//                   isLoggedIn: widget.isLoggedIn,
//                   onIndoorMap: _toggleIndoorMap,
//                   onGetDirections: _getDirections,
//                 ),
//               ),
//             ),

//         if (_showRoutePreview && !_isNavigating)
//   Positioned(
//     top: 80,
//     left: 0,
//     right: 0,
//     child: RoutePreviewPanel(
//       originText: _routeOriginText,
//       destinationText: _routeDestinationText,
//       onClose: _closeRoutePreview,
//       onSwitch: _switchOriginDestination,
//       onOriginChanged: _onRouteOriginChanged,
//       onDestinationChanged: _onRouteDestinationChanged,
//       onOriginSelected: _onRouteOriginSelected,
//       onDestinationSelected: _onRouteDestinationSelected,
//       originSuggestions: _routeOriginSuggestions,
//       destinationSuggestions: _routeDestinationSuggestions,

//       originRoomController: _originRoomController,
//       destinationRoomController: _destinationRoomController,
//       onOriginRoomSubmitted: _onOriginRoomSubmitted,
//       onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
//       originBuildingCode: _routeOriginBuildingCode,
//       destinationBuildingCode: _routeDestinationBuildingCode,
//       isConcordiaBuilding: (buildingCode) {
//         return buildingPolygons.any(
//           (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
//         );
//       },
//     ),
//   ),

//           if (_showRoutePreview)
//             Positioned(
//               bottom: 25,
//               left: 0,
//               right: 0,
//               child: PointerInterceptor(
//                 child: Center(
//                   child: RouteTravelModeBar(
//                     selectedTravelMode: _selectedTravelMode,
//                     onTravelModeSelected: _onTravelModeSelected,
//                     modeDurations: _routeDurations,
//                     isLoadingDurations: _isLoadingRouteData,
//                     onClose: _closeRoutePreview,
//                     onStart: _startNavigation,
//                     isNavigating: _isNavigating,
//                     onShowSteps: _openStepsForSelectedMode,
//                     transitDetails: _buildTransitDetailItems(),
//                     modeDistances: _routeDistances,
//                     modeArrivalTimes: _routeArrivalTimes,
//                   ),
//                 ),
//               ),
//             ),

//         OutdoorBottomBar(
//           showRoutePreview: _showRoutePreview,
//           isNavigating: _isNavigating,
//           selectedCampus: _selectedCampus,
//           onCampusChanged: _switchCampus,
//           selectedTravelMode: _selectedTravelMode,
//           onTravelModeSelected: _onTravelModeSelected,
//           routeDurations: _routeDurations,
//           routeDistances: _routeDistances,
//           routeArrivalTimes: _routeArrivalTimes,
//           isLoadingRouteData: _isLoadingRouteData,
//           onCloseRoutePreview: _closeRoutePreview,
//           onStartNavigation: _startNavigation,
//           onShowSteps: _openStepsForSelectedMode,
//           transitDetails: _buildTransitDetailItems(),
//         ),

//           // Invisible gesture detectors for building polygons (for testing)
//           ..._createBuildingGestureDetectors(),
//         ],
//       ),
//     );
//   }

//   Set<Polygon> _geoJsonToPolygons(Map<String, dynamic> geojson) {
//     final features = (geojson['features'] as List).cast<dynamic>();

//     final polygons = <Polygon>{};

//     for (final f in features) {
//       final feature = f as Map<String, dynamic>;
//       final geometry = feature['geometry'] as Map<String, dynamic>;
//       if (geometry['type'] != 'Polygon') continue;

//       final rings = geometry['coordinates'] as List;
//       if (rings.isEmpty) continue;

//       final outer = rings[0] as List;

//       final points = outer.map<LatLng>((p) {
//         final coords = p as List;
//         final lng = (coords[0] as num).toDouble();
//         final lat = (coords[1] as num).toDouble();
//         return LatLng(lat, lng); // GeoJSON is [lng,lat]
//       }).toList();

//       if (points.length < 3) continue;

//       final props =
//           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
//       final id = (props['ref'] ?? polygons.length).toString();

//       // Determine fill color based on feature type
//       Color fillColor;
//       if (props['escalators'] == 'yes') {
//         fillColor = Colors.green; // Escalator = green
//       } else if (props['highway'] == 'elevator') {
//         fillColor = Colors.orange; // Elevator = orange
//       } else if (props['highway'] == 'steps') {
//         fillColor = Colors.pink; // Steps = pink
//       } else if (props['amenity'] == 'toilets') {
//         fillColor = Colors.blue; // Toilets = blue
//       } else if (props['indoor'] == 'corridor') {
//         fillColor = const Color.fromARGB(
//           255,
//           232,
//           122,
//           149,
//         ); // Corridor = lighter red
//       } else {
//         fillColor = const Color(0xFF800020); // Default room = dark red
//       }

//       polygons.add(
//         Polygon(
//           polygonId: PolygonId('indoor-$id'),
//           points: points,
//           strokeWidth: 2,
//           strokeColor: Colors.black,
//           fillColor: fillColor.withOpacity(1.0),
//           zIndex: 20,
//         ),
//       );
//     }

//     return polygons;
//   }

//   Future<BitmapDescriptor> _createTextBitmap(
//     String text, {
//     double fontSize = 10,
//   }) async {
//     final painter = TextPainter(
//       text: TextSpan(
//         text: text,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: fontSize,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       textDirection: ui.TextDirection.ltr,
//     );
//     painter.layout();

//     final width = painter.width.ceil();
//     final height = painter.height.ceil();

//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(
//       recorder,
//       Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
//     );

//     painter.paint(canvas, Offset.zero);

//     final picture = recorder.endRecording();
//     ui.Image? img;
//     ByteData? byteData;
//     try {
//       img = await picture.toImage(width, height);
//       byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     } finally {
//       img?.dispose();
//       picture.dispose();
//     }
//     final Uint8List bytes = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.bytes(bytes);
//   }

//   /// Creates text labels at the center of each room polygon
//   Future<Set<Marker>> _createRoomLabels(Map<String, dynamic> geojson) async {
//     final features = (geojson['features'] as List).cast<dynamic>();
//     final markers = <Marker>{};
//     int index = 0;

//     for (final f in features) {
//       final feature = f as Map<String, dynamic>;
//       final geometry = feature['geometry'] as Map<String, dynamic>;
//       final props =
//           (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

//       if (geometry['type'] != 'Polygon') continue;
//       if (props['ref'] == null) continue;

//       final rings = geometry['coordinates'] as List;
//       if (rings.isEmpty) continue;
//       final outer = rings[0] as List;

//       final points = outer.map<LatLng>((p) {
//         final coords = p as List;
//         final lng = (coords[0] as num).toDouble();
//         final lat = (coords[1] as num).toDouble();
//         return LatLng(lat, lng);
//       }).toList();

//       if (points.length < 3) continue;

//       // Skip very small polygons where text won't fit
//       final area = _polygonArea(points);
//       if (area < 1e-10) continue;

//       final center = _polygonCenter(points);
//       final ref = props['ref'].toString();

//       // Choose font size based on polygon area
//       final double fontSize = area > 5e-8 ? 10 : 8;
//       final icon = await _createTextBitmap(ref, fontSize: fontSize);

//       markers.add(
//         Marker(
//           markerId: MarkerId('room-label-${index++}-$ref'),
//           position: center,
//           icon: icon,
//           anchor: const Offset(0.5, 0.5),
//           flat: true,
//           zIndex: 30,
//           consumeTapEvents: false,
//           infoWindow: InfoWindow.noText,
//         ),
//       );
//     }

//     return markers;
//   }

//   static const String _indoorMapStyle = '''
//   [
//     {
//       "featureType": "poi",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.school",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "poi.business",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     },
//     {
//       "featureType": "transit",
//       "stylers": [
//         { "visibility": "off" }
//       ]
//     }
//   ]
//   ''';

//   @override
//   void dispose() {
//     _posSub?.cancel();
//     _popupDebounce?.cancel();
//     _debounceTimer?.cancel();
//     _routeDebounceTimer?.cancel();
//     _mapController?.dispose();
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _originRoomController.dispose();
//     _destinationRoomController.dispose();
//     super.dispose();
//   }
// }


// class _ShuttleScheduleSheet extends StatelessWidget {
//   final String nearestStop;

//   const _ShuttleScheduleSheet({required this.nearestStop});

//   @override
//   Widget build(BuildContext context) {
//     const burgundy = Color(0xFF76263D);
//     final today = DateTime.now();
//     final times = ConcordiaShuttleService.getFullScheduleForDay(today);
//     final isWeekday =
//         today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

//     return DraggableScrollableSheet(
//       initialChildSize: 0.62,
//       minChildSize: 0.35,
//       maxChildSize: 0.92,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//           ),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 height: 4,
//                 width: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.directions_bus_filled, color: burgundy),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Concordia Shuttle Schedule',
//                             style: TextStyle(
//                               color: burgundy,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 16,
//                             ),
//                           ),
//                           Text(
//                             isWeekday
//                                 ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
//                                 : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
//                             style: const TextStyle(
//                               color: Colors.black54,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.of(context).maybePop(),
//                       icon: const Icon(Icons.close),
//                     ),
//                   ],
//                 ),
//               ),

//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: Row(
//                   children: [
//                     _StopChip(
//                         label: 'SGW  (Hall Building)', color: burgundy),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 8),
//                       child: Icon(Icons.sync_alt,
//                           size: 16, color: Colors.black45),
//                     ),
//                     _StopChip(label: 'Loyola', color: burgundy),
//                   ],
//                 ),
//               ),

//               const Divider(height: 1),

//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                   itemCount: times.length,
//                   itemBuilder: (context, index) {
//                     final t = times[index];
//                     final now = DateTime.now();
//                     final isPast = t.isBefore(now);
//                     final isNext = !isPast &&
//                         (index == 0 || times[index - 1].isBefore(now));

//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 6),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isNext
//                             ? burgundy.withOpacity(0.08)
//                             : Colors.transparent,
//                         border: isNext
//                             ? Border.all(color: burgundy.withOpacity(0.3))
//                             : null,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.directions_bus_filled,
//                             size: 16,
//                             color: isPast
//                                 ? Colors.black26
//                                 : isNext
//                                     ? burgundy
//                                     : Colors.black54,
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             ConcordiaShuttleService.formatTime(t),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: isNext
//                                   ? FontWeight.w700
//                                   : FontWeight.w400,
//                               color: isPast
//                                   ? Colors.black26
//                                   : isNext
//                                       ? burgundy
//                                       : Colors.black87,
//                             ),
//                           ),
//                           if (isNext) ...[
//                             const SizedBox(width: 10),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: burgundy,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: const Text(
//                                 'Next bus',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _StopChip extends StatelessWidget {
//   final String label;
//   final Color color;

//   const _StopChip({required this.label, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         border: Border.all(color: color.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/map_search_bar.dart';
import '../building_detection.dart';
import '../../data/building_polygons.dart';
import '../../data/search_result.dart';
import '../../data/search_suggestion.dart';
import '../building_search_service.dart';
import '../google_places_service.dart';
import '../google_directions_service.dart';
import '../../shared/widgets/campus_toggle.dart';
import '../../shared/widgets/building_info_popup.dart';
import '../../shared/widgets/route_preview_panel.dart';
import '../../features/indoor/data/building_info.dart';
import '../../services/navigation_steps.dart';
import '../indoor_maps/indoor_floor_config.dart';
import 'package:campus_app/utils/geo.dart' as geo;
import '../../shared/widgets/indoor_floor_dropdown.dart';
import '../indoor_maps/indoor_map_controller.dart';
import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
import 'package:campus_app/models/campus.dart';
import '../../shared/widgets/outdoor/outdoor_map_view.dart';
import '../indoor_maps/indoor_map_repository.dart';
import '../../shared/widgets/outdoor/outdoor_top_search.dart';
import '../../services/concordia_shuttle_service.dart';

// concordia campus coordinates
const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
const double campusRadius = 500; // meters
const String currentLocationTag = "Current location";

// when camera center is within this distance auto-switch toggle
const double campusAutoSwitchRadius = 500; // meters
// knowing which campus the user is in
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
  final bool isLoggedIn;

  @visibleForTesting
  final BuildingPolygon? debugSelectedBuilding;

  @visibleForTesting
  final Offset? debugAnchorOffset;

  @visibleForTesting
  final bool debugDisableMap;

  @visibleForTesting
  final bool debugDisableLocation;

  @visibleForTesting
  final String? debugLinkOverride;

  const OutdoorMapPage({
    super.key,
    required this.initialCampus,
    this.debugSelectedBuilding,
    this.debugAnchorOffset,
    this.debugDisableMap = false,
    this.debugDisableLocation = false,
    this.debugLinkOverride,
    required this.isLoggedIn,
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _originRoomController = TextEditingController();
  final TextEditingController _destinationRoomController = TextEditingController();
  bool _cameraMoving = false;
  List<SearchSuggestion> _searchSuggestions = [];
  Timer? _debounceTimer;

  // Indoor overlay state
  Set<Polygon> _indoorPolygons = {};
  bool _showIndoor = false;
  List<IndoorFloorOption> _indoorFloors = const [];
  String? _selectedIndoorFloorAsset;
  final IndoorMapController _indoorController = IndoorMapController();

  // --- Indoor floors state ---
  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;
  BuildingPolygon? _currentBuildingPoly;
  BuildingPolygon? _selectedBuildingPoly;
  // ignore: unused_field
  SearchResult? _selectedSearchResult;
  // ignore: unused_field
  Map<String, dynamic>? _indoorGeoJson;
  Set<Marker> _roomLabelMarkers = {};

  Set<Polyline> _routePolylines = {};

  // Room location marker
  Marker? _destinationRoomMarker;
  String? _currentBuildingCode;

  // Route preview mode
  bool _showRoutePreview = false;
  LatLng? _routeOrigin;
  LatLng? _routeDestination;
  String _routeOriginText = currentLocationTag;
  String _routeDestinationText = '';
  RouteTravelMode _selectedTravelMode = RouteTravelMode.driving;
  final Map<String, String?> _routeDurations = {};
  final Map<String, String?> _routeDistances = {};
  final Map<String, String?> _routeArrivalTimes = {};
  final Map<String, List<LatLng>> _routePointsByMode = {};
  final Map<String, List<DirectionsRouteSegment>> _routeSegmentsByMode = {};
  String? _routeOriginBuildingCode;
  String? _routeDestinationBuildingCode;

  final Map<String, List<NavigationStep>> _routeStepsByMode = {};
  // --- Navigation camera follow state ---
  bool _navigationFollowUser = false;
  DateTime _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const double _navZoom = 18.0;
  static const double _navTilt = 60.0;
  static const double _defaultZoom = 15.0;
  static const double _defaultTilt = 0.0;
  static const double _defaultBearing = 0.0;
  // ignore: unused_field
  static const double _navBearingThresholdDegrees = 10.0;
  // ignore: unused_field
  static const double _navDistanceThresholdMeters = 5.0;
  static const Duration _navCameraMinInterval = Duration(milliseconds: 700);
  bool _isNavigating = false;
  String? _navModeKey;
  int _navStepIndex = 0;
  bool _isLoadingRouteData = false;
  List<SearchSuggestion> _routeOriginSuggestions = [];
  List<SearchSuggestion> _routeDestinationSuggestions = [];
  Timer? _routeDebounceTimer;

  // Google Directions modes only — shuttle is handled separately
  static const List<RouteTravelMode> _supportedTravelModes = [
    RouteTravelMode.driving,
    RouteTravelMode.walking,
    RouteTravelMode.bicycling,
    RouteTravelMode.transit,
  ];

  // Shuttle state
  List<ShuttleDeparture> _shuttleNextBuses = [];
  int? _shuttleWalkingMinutes;
  String _shuttleNearestStop = 'SGW';
  BitmapDescriptor? _shuttleStopIcon;

  StreamSubscription<Position>? _posSub;

  Timer? _popupDebounce;

  static const double _popupW = 300;
  static const double _popupH = 260;

  LatLng? _selectedBuildingCenter;
  Offset? _anchorOffset;

  Campus _currentCampus = Campus.none;
  Campus _selectedCampus = Campus.none;

  LatLng? _lastCameraTarget;

  void _clearIndoorState() {
    _showIndoor = false;
    _indoorFloors = const [];
    _selectedIndoorFloorAsset = null;
    _indoorPolygons = {};
    _indoorGeoJson = null;
    _roomLabelMarkers = {};
  }

  Campus _campusFromPoint(LatLng p) {
    final dSgw = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      concordiaSGW.latitude,
      concordiaSGW.longitude,
    );

    final dLoy = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      concordiaLoyola.latitude,
      concordiaLoyola.longitude,
    );

    final minDist = dSgw < dLoy ? dSgw : dLoy;
    if (minDist > campusAutoSwitchRadius) return Campus.none;

    return dSgw <= dLoy ? Campus.sgw : Campus.loyola;
  }

  Future<void> _onOriginRoomSubmitted(String buildingCode, String roomCode) async {
    print('[DEBUG] Origin room submitted: $roomCode in $buildingCode');
  }

  Future<void> _syncToggleWithCameraCenter() async {
    if (!mounted) return;

    LatLng? center = _lastCameraTarget;

    if (center == null) {
      final controller = _mapController;
      if (controller == null) return;

      try {
        final bounds = await controller.getVisibleRegion();
        final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final lng =
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        center = LatLng(lat, lng);
      } catch (_) {
        return;
      }
    }

    final newCampus = _campusFromPoint(center);

    if (newCampus == _selectedCampus) return;

    setState(() {
      _selectedCampus = newCampus;
    });
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    return geo.pointInPolygon(point, polygon);
  }

  Future<void> _loadIndoorFloor(String assetPath) async {
    try {
      final result = await _indoorController.loadFloor(assetPath);
      if (!mounted) return;
      setState(() {
        _showIndoor = true;
        _selectedIndoorFloorAsset = assetPath;
        _indoorPolygons = result.polygons;
        _indoorGeoJson = result.geoJson;
        _roomLabelMarkers = result.labels;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load indoor floor: $e')),
      );
    }
  }

  Future<void> _toggleIndoorMap() async {
    // turn OFF
    if (_showIndoor) {
      setState(() {
        _clearIndoorState();
      });
      return;
    }

    // turn ON (needs selected building)
    final b = _selectedBuildingPoly;
    if (b == null) return;

    final floors = IndoorFloorConfig.floorsForBuilding(b.code);
    if (floors.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No indoor maps available for this building')),
      );
      return;
    }

    setState(() {
      _indoorFloors = floors;
      _selectedIndoorFloorAsset = floors.first.assetPath;
    });

    await _loadIndoorFloor(floors.first.assetPath);
  }

  Future<void> _goToMyLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    var loc = _currentLocation;

    if (loc == null) {
      try {
        final p = await Geolocator.getCurrentPosition();
        loc = LatLng(p.latitude, p.longitude);
        if (mounted) setState(() => _currentLocation = loc);
      } catch (_) {
        return;
      }
    }

    controller.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
  }

  Future<void> _openLink(String url) async {
    if (url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }

  void _schedulePopupUpdate() {
    _popupDebounce?.cancel();
    _popupDebounce = Timer(
      const Duration(milliseconds: 16),
      _updatePopupOffset,
    );
  }

  Future<void> _updatePopupOffset() async {
    final controller = _mapController;
    final center = _selectedBuildingCenter;
    if (!mounted || controller == null || center == null) return;

    final sc = await controller.getScreenCoordinate(center);
    if (!mounted) return;

    double x = sc.x.toDouble();
    double y = sc.y.toDouble();

    final dpr = MediaQuery.of(context).devicePixelRatio;
    x = x / dpr;
    y = y / dpr;

    setState(() {
      _anchorOffset = Offset(x, y);
    });
  }

  // ignore: unused_element
  void _selectBuildingWithoutMap(BuildingPolygon b) {
    final center = geo.polygonCenter(b.points);
    final name = buildingInfoByCode[b.code]?.name ?? b.name;

    _searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );

    setState(() {
      _selectedBuildingPoly = b;
      _selectedBuildingCenter = center;
      _anchorOffset = widget.debugAnchorOffset ?? const Offset(200, 420);
      _cameraMoving = false;
    });
  }

  void _onBuildingTapped(BuildingPolygon b) {
    final center = geo.polygonCenter(b.points);
    final controller = _mapController;
    final name = buildingInfoByCode[b.code]?.name ?? b.name;

    _searchController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );

    setState(() {
      _selectedBuildingPoly = b;
      _selectedBuildingCenter = center;
      _anchorOffset = null;
      _cameraMoving = true;
      _clearIndoorState();
      _roomLabelMarkers = {};
    });

    if (controller == null) return;

    controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((
      _,
    ) async {
      if (!mounted) return;
      await _updatePopupOffset();
      if (!mounted) return;
      setState(() {
        _cameraMoving = false;
      });
    });
  }

  void _closePopup() {
    _clearSelectedBuilding(clearSearch: true);
  }

  void _clearSelectedBuilding({bool clearSearch = false}) {
    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _selectedSearchResult = null;
      _anchorOffset = null;
      _routePolylines = {};
      _showRoutePreview = false;
      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
      _routeDurations.clear();
      _routeDistances.clear();
      _routeArrivalTimes.clear();
      _routePointsByMode.clear();
      _routeSegmentsByMode.clear();
      _isLoadingRouteData = false;
      _selectedTravelMode = RouteTravelMode.driving;
      _shuttleNextBuses = [];
      _shuttleWalkingMinutes = null;
      _destinationRoomMarker = null;
      if (clearSearch) {
        _searchController.clear();
      }
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _destinationRoomMarker = null;
      _routeOriginBuildingCode = null;
      _routeDestinationBuildingCode = null;
      _originRoomController.clear();
      _destinationRoomController.clear();
    });
  }

  Future<void> _getDirections() async {
    print('[DEBUG] Get directions button clicked');
    print('[DEBUG] Current location: $_currentLocation');
    print(
      '[DEBUG] Selected building: ${_selectedBuildingPoly?.name} (${_selectedBuildingPoly?.code})',
    );

    final origin = _currentLocation;
    final destination = _selectedBuildingPoly?.center;

    if (origin == null) {
      print('[ERROR] Cannot get directions: Current location is null');
      print(
        '[ERROR] Make sure location services are enabled and location is set in emulator',
      );
      return;
    }

    if (destination == null) {
      print('[ERROR] Cannot get directions: Destination is null');
      return;
    }

    final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

    // Enter route preview mode
    setState(() {
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _showRoutePreview = true;
      _routeOrigin = origin;
      _routeDestination = destination;
      _routeOriginText = currentLocationTag;
      _routeDestinationText =
          '${_selectedBuildingPoly?.name} - ${_selectedBuildingPoly?.code}';
      _routeOriginBuildingCode = currentBuildingCode;
      _routeDestinationBuildingCode = _selectedBuildingPoly?.code;
      print(
        '[DEBUG] Route building codes: origin=$_routeOriginBuildingCode, destination=$_routeDestinationBuildingCode',
      );
    });

    await _fetchRoutesAndDurations();
  }

  Future<void> _fetchRoutesAndDurations() async {
    final origin = _routeOrigin;
    final destination = _routeDestination;

    if (origin == null || destination == null) {
      print('[ERROR] Cannot fetch route: origin or destination is null');
      return;
    }

    print(
      '[DEBUG] Fetching route data for all travel modes from $origin to $destination',
    );

    setState(() {
      _isLoadingRouteData = true;
    });

    try {
      final futures = _supportedTravelModes.map(
        (mode) => GoogleDirectionsService.instance.getRouteDetails(
          origin: origin,
          destination: destination,
          mode: mode.apiValue,
        ),
      );

      final results = await Future.wait(futures);
      final durations = <String, String?>{};
      final distances = <String, String?>{};
      final arrivalTimes = <String, String?>{};
      final pointsByMode = <String, List<LatLng>>{};
      final segmentsByMode = <String, List<DirectionsRouteSegment>>{};
      final stepsByMode = <String, List<NavigationStep>>{};

      for (var i = 0; i < _supportedTravelModes.length; i++) {
        final mode = _supportedTravelModes[i].apiValue;
        final route = results[i];
        durations[mode] = route?.durationText;
        distances[mode] = route?.distanceText;
        arrivalTimes[mode] = _formatArrivalTime(route?.durationSeconds);
        stepsByMode[mode] = route?.steps ?? const [];
        if (route != null && route.points.isNotEmpty) {
          pointsByMode[mode] = route.points;
        }
        if (route != null && route.transitSegments.isNotEmpty) {
          segmentsByMode[mode] = route.transitSegments;
        }
      }

      if (!mounted) return;

      setState(() {
        _routeDurations
          ..clear()
          ..addAll(durations);
        _routeDistances
          ..clear()
          ..addAll(distances);
        _routeArrivalTimes
          ..clear()
          ..addAll(arrivalTimes);
        _routePointsByMode
          ..clear()
          ..addAll(pointsByMode);
        _routeSegmentsByMode
          ..clear()
          ..addAll(segmentsByMode);
        _routeStepsByMode
          ..clear()
          ..addAll(stepsByMode);

        _isLoadingRouteData = false;
      });

      _applySelectedModeRoute(animateCamera: true);

      _fetchShuttleInfo();
    } catch (e) {
      print('Error getting directions: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingRouteData = false;
      });
    }
  }

  void _openStepsForSelectedMode() {
    if (_selectedTravelMode == RouteTravelMode.shuttle) {
      _showShuttleScheduleModal();
      return;
    }

    final key = _selectedTravelMode.apiValue;
    final steps = _routeStepsByMode[key] ?? const [];

    showNavigationStepsModal(
      context,
      title: _selectedTravelMode.label,
      steps: steps,
      totalDuration: _routeDurations[key],
      totalDistance: _routeDistances[key],
    );
  }

  void _applySelectedModeRoute({required bool animateCamera}) {
    if (_selectedTravelMode == RouteTravelMode.shuttle) return;

    final selectedModeKey = _selectedTravelMode.apiValue;
    final selectedSegments = _routeSegmentsByMode[selectedModeKey];
    if (_selectedTravelMode == RouteTravelMode.transit &&
        selectedSegments != null &&
        selectedSegments.isNotEmpty) {
      _applyTransitSegments(selectedSegments, animateCamera: animateCamera);
      return;
    }

    final selectedPoints = _routePointsByMode[selectedModeKey];

    if (selectedPoints == null || selectedPoints.isEmpty) {
      setState(() {
        _routePolylines = {};
      });
      return;
    }

    setState(() {
      _routePolylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: selectedPoints,
          color: const Color(0xFF76263D),
          width: 5,
          patterns: _selectedTravelMode == RouteTravelMode.driving
              ? const []
              : [PatternItem.dot, PatternItem.gap(10)],
        ),
      };
    });

    if (!animateCamera || _mapController == null) return;
    final bounds = geo.calculateBounds(selectedPoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _applyTransitSegments(
    List<DirectionsRouteSegment> segments, {
    required bool animateCamera,
  }) {
    final polylines = <Polyline>{};
    final allPoints = <LatLng>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (segment.points.isEmpty) {
        continue;
      }

      allPoints.addAll(segment.points);

      final isWalking = segment.travelMode.toUpperCase() == 'WALKING';
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_segment_$i'),
          points: segment.points,
          color: _resolveTransitSegmentColor(segment),
          width: 5,
          patterns: isWalking
              ? [PatternItem.dot, PatternItem.gap(10)]
              : const [],
        ),
      );
    }

    if (polylines.isEmpty) {
      setState(() {
        _routePolylines = {};
      });
      return;
    }

    setState(() {
      _routePolylines = polylines;
    });

    if (!animateCamera || _mapController == null || allPoints.isEmpty) {
      return;
    }

    final bounds = geo.calculateBounds(allPoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _startNavigation() {
    if (_selectedTravelMode == RouteTravelMode.shuttle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please follow the shuttle schedule. Turn-by-turn navigation is not available for the Concordia Shuttle.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final key = _selectedTravelMode.apiValue;
    final steps = _routeStepsByMode[key] ?? const [];

    if (steps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No steps available for this route')),
        );
      }
      return;
    }

    setState(() {
      _isNavigating = true;
      _navModeKey = key;
      _navStepIndex = 0;

      _navigationFollowUser = true;
      _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    });

    if (_currentLocation != null && _mapController != null) {
      try {
        final currentPos = _currentLocation!;
        final initialCam = CameraPosition(
          target: currentPos,
          zoom: _navZoom,
          tilt: _navTilt,
          bearing: 0.0,
        );
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(initialCam),
        );
      } catch (e) {
        print('Error animating camera when starting navigation: $e');
      }
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _navModeKey = null;
      _navStepIndex = 0;
      _navigationFollowUser = false;
    });
    if (_mapController != null && _currentLocation != null) {
      try {
        final cam = CameraPosition(
          target: _currentLocation!,
          zoom: _defaultZoom,
          tilt: _defaultTilt,
          bearing: _defaultBearing,
        );

        _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
      } catch (e) {
        print('Error resetting camera after navigation: $e');
      }
    }

    _closeRoutePreview();
  }

  void _maybeUpdateCameraForNavigation(LatLng userLatLng, double? heading) {
    if (_mapController == null) return;
    if (!_navigationFollowUser) return;

    final now = DateTime.now();

    if (now.difference(_lastNavCameraUpdate) < _navCameraMinInterval) {
      return;
    }

    double bearing = 0.0;
    if (heading != null && heading >= 0.0) {
      bearing = heading;
    }

    final cam = CameraPosition(
      target: userLatLng,
      zoom: _navZoom,
      tilt: _navTilt,
      bearing: bearing,
    );

    try {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(cam));
    } catch (e) {
      print('Error animating navigation camera: $e');
    }
  }

  void _maybeAdvanceNavigationStep(LatLng user) {
    final key = _navModeKey;
    if (key == null) return;

    final steps = _routeStepsByMode[key] ?? const [];
    if (steps.isEmpty) return;

    if (_navStepIndex >= steps.length - 1) return;

    final current = steps[_navStepIndex];
    final end = current.endPoint;
    if (end == null) return;

    final d = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      end.latitude,
      end.longitude,
    );

    if (d <= 20) {
      setState(() => _navStepIndex += 1);
    }
  }

  void _closeRoutePreview() {
    setState(() {
      _showRoutePreview = false;
      _routePolylines = {};
      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
      _routeDurations.clear();
      _routeDistances.clear();
      _routeArrivalTimes.clear();
      _routePointsByMode.clear();
      _routeSegmentsByMode.clear();
      _isLoadingRouteData = false;
      _selectedTravelMode = RouteTravelMode.driving;
      _shuttleNextBuses = [];
      _shuttleWalkingMinutes = null;
      _searchController.clear();

      //reset indoor map and building selection state
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _destinationRoomMarker = null;
      _originRoomController.clear();
      _destinationRoomController.clear();
      _routeOriginBuildingCode = null;
      _routeDestinationBuildingCode = null;
    });
  }

  String? _formatArrivalTime(int? durationSeconds) {
    if (durationSeconds == null) {
      return null;
    }

    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: durationSeconds));
    int hour = arrival.hour;
    final minute = arrival.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final period = isPm ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    return '$hour:$minute $period';
  }

  Color _resolveTransitSegmentColor(DirectionsRouteSegment segment) {
    const defaultRed = Color(0xFF76263D);
    final mode = segment.travelMode.toUpperCase();
    if (mode == 'WALKING') {
      return defaultRed;
    }

    final vehicleType = segment.transitVehicleType?.toUpperCase();
    if (vehicleType == 'BUS') {
      return Colors.blue;
    }

    final lineColor = parseHexColor(segment.transitLineColorHex);
    if (lineColor != null) {
      return lineColor;
    }

    return defaultRed;
  }

  List<TransitDetailItem> _buildTransitDetailItems() {
    final segments = _routeSegmentsByMode['transit'] ?? const [];
    final items = <TransitDetailItem>[];

    for (final segment in segments) {
      if (segment.points.isEmpty) {
        continue;
      }

      final travelMode = segment.travelMode.toUpperCase();
      if (travelMode == 'WALKING') {
        continue;
      }

      final vehicleType = segment.transitVehicleType?.toUpperCase();
      final lineLabel =
          segment.transitLineShortName ?? segment.transitLineName ?? 'Route';
      final color = _resolveTransitSegmentColor(segment);

      IconData icon = Icons.directions_transit;
      String title = 'Transit $lineLabel';

      if (vehicleType == 'BUS') {
        icon = Icons.directions_bus;
        title = 'Bus $lineLabel';
      } else if (vehicleType == 'SUBWAY' ||
          vehicleType == 'METRO_RAIL' ||
          vehicleType == 'HEAVY_RAIL' ||
          vehicleType == 'COMMUTER_TRAIN' ||
          vehicleType == 'RAIL' ||
          vehicleType == 'TRAM' ||
          vehicleType == 'LIGHT_RAIL' ||
          vehicleType == 'MONORAIL') {
        icon = Icons.directions_subway;
        title = 'Metro $lineLabel';
      }

      items.add(TransitDetailItem(icon: icon, color: color, title: title));
    }

    return items;
  }

  // ignore: unused_element
  List<DirectionsRouteSegment> _getTransitDetailSegments() {
    final segments = _routeSegmentsByMode['transit'] ?? const [];
    return segments
        .where(
          (segment) =>
              segment.travelMode.toUpperCase() == 'TRANSIT' &&
              segment.points.isNotEmpty,
        )
        .toList();
  }

  String _formatTransitSegmentTitle(DirectionsRouteSegment segment) {
    final vehicleType = segment.transitVehicleType?.toUpperCase();
    final lineLabel =
        segment.transitLineShortName ?? segment.transitLineName ?? 'Route';

    if (vehicleType == 'BUS') {
      return 'Bus $lineLabel';
    }

    if (vehicleType == 'SUBWAY' ||
        vehicleType == 'METRO_RAIL' ||
        vehicleType == 'HEAVY_RAIL' ||
        vehicleType == 'COMMUTER_TRAIN' ||
        vehicleType == 'RAIL' ||
        vehicleType == 'TRAM' ||
        vehicleType == 'LIGHT_RAIL' ||
        vehicleType == 'MONORAIL') {
      return 'Metro $lineLabel';
    }

    return 'Transit $lineLabel';
  }

  IconData _transitSegmentIcon(DirectionsRouteSegment segment) {
    final vehicleType = segment.transitVehicleType?.toUpperCase();
    if (vehicleType == 'BUS') {
      return Icons.directions_bus;
    }
    if (vehicleType == 'SUBWAY' ||
        vehicleType == 'METRO_RAIL' ||
        vehicleType == 'HEAVY_RAIL' ||
        vehicleType == 'COMMUTER_TRAIN' ||
        vehicleType == 'RAIL' ||
        vehicleType == 'TRAM' ||
        vehicleType == 'LIGHT_RAIL' ||
        vehicleType == 'MONORAIL') {
      return Icons.directions_subway;
    }
    return Icons.directions_transit;
  }

  // ignore: unused_element
  Widget _buildTransitDetailsCard(List<DirectionsRouteSegment> segments) {
    const burgundy = Color(0xFF76263D);

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Transit details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: burgundy,
            ),
          ),
          const SizedBox(height: 6),
          for (final segment in segments)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _transitSegmentIcon(segment),
                    size: 16,
                    color: _resolveTransitSegmentColor(segment),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTransitSegmentTitle(segment),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (segment.transitHeadsign != null &&
                            segment.transitHeadsign!.trim().isNotEmpty)
                          Text(
                            segment.transitHeadsign!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color? parseHexColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return null;
    }

    final normalized = hex.trim().replaceFirst('#', '');
    if (normalized.length != 6) {
      return null;
    }

    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return null;
    }

    return Color(0xFF000000 | value);
  }

  void _switchOriginDestination() {
    setState(() {
      final tempOrigin = _routeOriginText;
      final tempOriginLatLng = _routeOrigin;
      final tempDestination = _routeDestinationText;
      final tempDestinationLatLng = _routeDestination;

      _routeOriginText = tempDestination;
      _routeOrigin = tempDestinationLatLng;
      _routeDestinationText = tempOrigin;
      _routeDestination = tempOriginLatLng;

      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
    });

    _fetchRoutesAndDurations();
  }

  void _onTravelModeSelected(RouteTravelMode mode) {
    setState(() {
      _selectedTravelMode = mode;
    });

    if (mode == RouteTravelMode.shuttle) {
      _fetchShuttleInfo();
      return;
    }

    if (_routePointsByMode.containsKey(mode.apiValue)) {
      _applySelectedModeRoute(animateCamera: false);
      return;
    }

    _fetchRoutesAndDurations();
  }

  /// Shuttle stop marker icon
  Future<void> _createShuttleStopIcon() async {
    _shuttleStopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(600, 600)),
      'assets/images/shuttle_icon.png',
    );
  }

  /// Walking time + 4 next buses
  Future<void> _fetchShuttleInfo() async {
    final origin = _routeOrigin ?? _currentLocation;

    if (origin == null) {
      setState(() {
        _routeDurations['shuttle'] = '–';
      });
      return;
    }

    setState(() {
      _shuttleNextBuses = [];
      _shuttleWalkingMinutes = null;
    });

    try {
      final nearestStop = ConcordiaShuttleService.nearestStop(origin);
      final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

      int walkingSeconds = 0;
      List<LatLng> walkPoints = [];

      final walkRoute = await GoogleDirectionsService.instance.getRouteDetails(
        origin: origin,
        destination: stopLatLng,
        mode: 'walking',
      );

      if (walkRoute != null) {
        walkingSeconds = walkRoute.durationSeconds ?? 0;
        walkPoints = walkRoute.points;
      }

      final walkingMinutes = (walkingSeconds / 60).ceil();

      final buses = ConcordiaShuttleService.getNextDepartures(
        fromStop: nearestStop,
        now: DateTime.now(),
        count: 4,
        walkingDuration: Duration(seconds: walkingSeconds),
      );

      String shuttleDurationLabel;
      if (!ConcordiaShuttleService.isInService()) {
        shuttleDurationLabel = 'No service';
      } else if (buses.isNotEmpty) {
        shuttleDurationLabel = buses.first.statusLabel;
      } else {
        shuttleDurationLabel = '–';
      }

      if (_selectedTravelMode == RouteTravelMode.shuttle) {
        if (walkPoints.isNotEmpty) {
          setState(() {
            _routePolylines = {
              Polyline(
                polylineId: const PolylineId('shuttle_walk'),
                points: walkPoints,
                color: const Color(0xFF76263D),
                width: 5,
                patterns: [PatternItem.dot, PatternItem.gap(10)],
              ),
            };
          });

          if (_mapController != null) {
            final bounds = geo.calculateBounds([...walkPoints, stopLatLng]);
            _mapController!
                .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
          }
        } else {
          setState(() {
            _routePolylines = {};
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _shuttleNearestStop = nearestStop;
        _shuttleWalkingMinutes = walkingMinutes > 1 ? walkingMinutes : null;
        _shuttleNextBuses = buses;
        _routeDurations['shuttle'] = shuttleDurationLabel;
      });
    } catch (e) {
      print('Error fetching shuttle info: $e');
      if (!mounted) return;
      setState(() {
        _routeDurations['shuttle'] = '–';
      });
    }
  }

  /// Open full day schedule
  void _showShuttleScheduleModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ShuttleScheduleSheet(nearestStop: _shuttleNearestStop),
    );
  }

  Future<void> _onRouteOriginChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _routeOriginSuggestions = [];
      });
      return;
    }

    setState(() {
      _routeOriginSuggestions = [];
    });

    _routeDebounceTimer?.cancel();
    _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        print('[DEBUG] Searching for origin: $query');
        final suggestions = await BuildingSearchService.getCombinedSuggestions(
          query,
          userLocation: _currentLocation,
        );
        print('[DEBUG] Found ${suggestions.length} origin suggestions');
        if (mounted) {
          setState(() {
            _routeOriginSuggestions = suggestions;
          });
        }
      } catch (e) {
        print('[ERROR] Error getting origin suggestions: $e');
      }
    });
  }

  Future<void> _onRouteDestinationChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _routeDestinationSuggestions = [];
      });
      return;
    }

    setState(() {
      _routeDestinationSuggestions = [];
    });

    _routeDebounceTimer?.cancel();
    _routeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        print('[DEBUG] Searching for destination: $query');
        final suggestions = await BuildingSearchService.getCombinedSuggestions(
          query,
          userLocation: _currentLocation,
        );
        print('[DEBUG] Found ${suggestions.length} destination suggestions');
        if (mounted) {
          setState(() {
            _routeDestinationSuggestions = suggestions;
          });
        }
      } catch (e) {
        print('[ERROR] Error getting destination suggestions: $e');
      }
    });
  }

  Future<void> _onRouteOriginSelected(SearchSuggestion suggestion) async {
    print(
      '[DEBUG] Origin selected: ${suggestion.name}, isConcordia: ${suggestion.isConcordiaBuilding}, placeId: ${suggestion.placeId}',
    );
    LatLng? newOrigin;
    String displayText = suggestion.name;
    String? buildingCode;

    if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
      print('[DEBUG] Handling Concordia building');
      final building = BuildingSearchService.searchBuilding(
        suggestion.buildingName!.code,
      );
      newOrigin = building?.center;
      displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
      buildingCode = suggestion.buildingName!.code;
      print('[DEBUG] Concordia building origin: $newOrigin');
    } else if (suggestion.placeId != null) {
      print(
        '[DEBUG] Fetching place details for non-Concordia place: ${suggestion.placeId}',
      );
      try {
        final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
          suggestion.placeId!,
        );
        print('[DEBUG] Place details result: $placeDetails');
        if (placeDetails != null) {
          newOrigin = placeDetails.location;
          buildingCode = null;
          print('[DEBUG] Non-Concordia origin location: $newOrigin');
        } else {
          print(
            '[ERROR] Place details returned null for ${suggestion.placeId}',
          );
        }
      } catch (e) {
        print('[ERROR] Error fetching place details: $e');
        return;
      }
    }

    if (newOrigin != null) {
      print('[DEBUG] Updating route origin state');
      print('[DEBUG] New origin building code: $buildingCode');
      setState(() {
        _routeOrigin = newOrigin;
        _routeOriginText = displayText;
        _routeOriginSuggestions = [];
        _routeOriginBuildingCode = buildingCode;
        _originRoomController.clear();
      });
      print('[DEBUG] Calling _fetchRoute with new origin: $newOrigin');
      await _fetchRoutesAndDurations();
    } else {
      print('[ERROR] Could not determine origin location');
    }
  }

  Future<void> _onRouteDestinationSelected(SearchSuggestion suggestion) async {
    LatLng? newDestination;
    String displayText = suggestion.name;
    String? buildingCode;

    if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
      final building = BuildingSearchService.searchBuilding(
        suggestion.buildingName!.code,
      );
      newDestination = building?.center;
      displayText = '${suggestion.name} - ${suggestion.buildingName!.code}';
      buildingCode = suggestion.buildingName!.code;
    } else if (suggestion.placeId != null) {
      try {
        final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
          suggestion.placeId!,
        );
        if (placeDetails != null) {
          newDestination = placeDetails.location;
          buildingCode = null;
        }
      } catch (e) {
        print('Error fetching place details: $e');
        return;
      }
    }

    if (newDestination != null) {
      print('[DEBUG] Updating route destination state');
      print('[DEBUG] New destination building code: $buildingCode');
      setState(() {
        _routeDestination = newDestination;
        _routeDestinationText = displayText;
        _routeDestinationSuggestions = [];
        _routeDestinationBuildingCode = buildingCode;
        _destinationRoomController.clear();
      });
      await _fetchRoutesAndDurations();
    }
  }

  void _hideBuildingPopup() {
    if (_selectedBuildingPoly == null) return;

    _clearSelectedBuilding();
  }

  Future<void> _onSearchSubmitted(String query) async {
    if (query.trim().isEmpty) return;

    final concordiaBuilding = BuildingSearchService.searchBuilding(query);

    if (concordiaBuilding != null) {
      _onBuildingTapped(concordiaBuilding);
      return;
    }

    final results = await BuildingSearchService.searchWithGooglePlaces(
      query,
      userLocation: _currentLocation,
    );

    if (results.isNotEmpty) {
      SearchResult? selectedResult;

      for (final result in results) {
        if (!result.isConcordiaBuilding) {
          selectedResult = result;
          break;
        }
      }

      if (selectedResult == null && results.isNotEmpty) {
        selectedResult = results.first;
      }

      if (selectedResult != null) {
        if (selectedResult.isConcordiaBuilding &&
            selectedResult.buildingPolygon != null) {
          _onBuildingTapped(selectedResult.buildingPolygon!);
        } else {
          _onPlaceSelected(selectedResult);
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$query" not found'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF800020),
        ),
      );
      _searchController.clear();
    }
  }

  void _onPlaceSelected(SearchResult result) {
    final controller = _mapController;
    if (controller == null) return;

    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _selectedSearchResult = result;
    });

    _searchController.value = TextEditingValue(
      text: result.name,
      selection: TextSelection.collapsed(offset: result.name.length),
    );

    if (result.isConcordiaBuilding) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(result.location, 18));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} is a Concordia building'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF800020),
        ),
      );
    } else {
      if (_currentLocation == null) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(result.location, 18),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.name} is not a Concordia building'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey[700],
          ),
        );
      } else {
        _enterRoutePreviewForPlace(result);
      }
    }
  }

  Future<void> _enterRoutePreviewForPlace(SearchResult place) async {
    if (_currentLocation == null) return;

    print(
      '[DEBUG] Entering route preview for non-Concordia place: ${place.name}',
    );

    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _showRoutePreview = true;
      _routeOrigin = _currentLocation;
      _routeDestination = place.location;
      _routeOriginText = currentLocationTag;
      _routeDestinationText = place.name;
      _selectedSearchResult = place;
    });

    print(
      '[DEBUG] Route preview initialized - origin: $_routeOrigin, destination: $_routeDestination',
    );

    await _fetchRoutesAndDurations();
  }

  Future<void> _onSuggestionSelected(SearchSuggestion suggestion) async {
    if (suggestion.isConcordiaBuilding && suggestion.buildingName != null) {
      final buildingPolygon = BuildingSearchService.searchBuilding(
        suggestion.buildingName!.code,
      );
      if (buildingPolygon == null) return;
      _onBuildingTapped(buildingPolygon);
    } else if (suggestion.placeId != null) {
      final placeDetails = await GooglePlacesService.instance.getPlaceDetails(
        suggestion.placeId!,
      );
      if (placeDetails != null) {
        final concordiaBuilding = BuildingSearchService.searchBuilding(
          suggestion.name,
        );

        if (concordiaBuilding != null) {
          _onBuildingTapped(concordiaBuilding);
        } else {
          final searchResult = SearchResult.fromGooglePlace(
            name: placeDetails.name,
            address: placeDetails.formattedAddress,
            location: placeDetails.location,
            isConcordiaBuilding: false,
            placeId: placeDetails.placeId,
          );
          _onPlaceSelected(searchResult);
        }
      }
    }
  }

  Set<Polygon> _createBuildingPolygons() {
    const burgundy = Color(0xFF800020);
    const selectedBlue = Color(0xFF7F83C3);

    final polys = <Polygon>{};

    for (final b in buildingPolygons) {
      final isCurrent = _currentBuildingPoly?.code == b.code;
      final isSelected = _selectedBuildingPoly?.code == b.code;

      final strokeColor = isSelected
          ? selectedBlue.withOpacity(0.95)
          : isCurrent
          ? Colors.blue.withOpacity(0.8)
          : burgundy.withOpacity(0.55);

      final fillColor = isSelected
          ? selectedBlue.withOpacity(0.25)
          : isCurrent
          ? Colors.blue.withOpacity(0.25)
          : burgundy.withOpacity(0.22);

      final strokeWidth = isSelected
          ? 3
          : isCurrent
          ? 3
          : 2;
      final zIndex = isSelected
          ? 3
          : isCurrent
          ? 2
          : 1;

      polys.add(
        Polygon(
          polygonId: PolygonId('poly_${b.code}'),
          points: b.points,
          strokeWidth: strokeWidth,
          strokeColor: strokeColor,
          fillColor: fillColor,
          zIndex: zIndex,
          consumeTapEvents: true,
          onTap: () => _onBuildingTapped(b),
        ),
      );
    }

    return polys;
  }

  List<Widget> _createBuildingGestureDetectors() {
    final detectors = <Widget>[];

    for (final building in buildingPolygons) {
      detectors.add(
        Positioned(
          left: 0,
          top: 0,
          child: GestureDetector(
            key: Key('building_detector_${building.code}'),
            onTap: () => _onBuildingTapped(building),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }

    return detectors;
  }

  @override
  void initState() {
    super.initState();

    _selectedCampus = widget.initialCampus;

    _lastCameraTarget = widget.initialCampus == Campus.loyola
        ? concordiaLoyola
        : concordiaSGW;

    _createBlueDotIcon();
    _createShuttleStopIcon();
    _determineUserLocationAndBuilding().then((_) {
      _startLocationUpdates();
    });

    _searchController.addListener(_onSearchChanged);
    // Clear destination room marker when room input changes
    _destinationRoomController.addListener(_onDestinationRoomTextChanged);
    _determineUserLocationAndBuilding();
  }

  Future<void> _determineUserLocationAndBuilding() async {
    final position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);

    final buildingAtLocation = _findBuildingAtLocation(_currentLocation!);

    setState(() {
      _currentBuildingCode = buildingAtLocation?.code;
    });
  }

  BuildingPolygon? _findBuildingAtLocation(LatLng location) {
    for (final building in buildingPolygons) {
      if (_isPointInPolygon(location, building.points)) {
        return building;
      }
    }
    return null;
  }

  void _onDestinationRoomTextChanged() {
    if (_destinationRoomMarker == null) return;

    setState(() {
      _destinationRoomMarker = null;
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final query = _searchController.text;
      try {
        final suggestions = await BuildingSearchService.getCombinedSuggestions(
          query,
          userLocation: _currentLocation,
        );
        if (mounted) {
          setState(() {
            _searchSuggestions = suggestions;
          });
        }
      } catch (e) {
        print('Error getting search suggestions: $e');
        if (mounted) {
          setState(() {
            _searchSuggestions = BuildingSearchService.getSuggestions(
              query,
            ).map((b) => SearchSuggestion.fromConcordiaBuilding(b)).toList();
          });
        }
      }
    });
  }

  Future<void> _createBlueDotIcon() async {
    _blueDotIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
  }

  Future<void> _startLocationUpdates() async {
    print('[DEBUG] Starting location updates...');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('[DEBUG] Location service enabled: $serviceEnabled');

    if (!serviceEnabled) {
      print('[ERROR] Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    print('[DEBUG] Initial permission status: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('[DEBUG] Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        print('[ERROR] Location permission denied by user');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[ERROR] Location permission denied forever');
      return;
    }

    try {
      print('[DEBUG] Attempting to get current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final newLatLng = LatLng(position.latitude, position.longitude);

      print(
        '[DEBUG] Location obtained: ${position.latitude}, ${position.longitude}',
      );
      print('[DEBUG] Location accuracy: ${position.accuracy} meters');

      if (!mounted) return;
      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = detectBuildingPoly(newLatLng);
      });

      print('[DEBUG] Current campus: $_currentCampus');
      print('[DEBUG] Current building: ${_currentBuildingPoly?.name}');

      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    } catch (e) {
      print('[ERROR] Failed to get current position: $e');
      print(
        '[ERROR] On emulator: Use Extended Controls (... button) > Location to set GPS coordinates',
      );
    }

    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((position) {
          final newLatLng = LatLng(position.latitude, position.longitude);
          print(
            '[DEBUG] Location update: ${position.latitude}, ${position.longitude}',
          );

          final buildingAtLocation = _findBuildingAtLocation(newLatLng);

          if (!mounted) return;
          setState(() {
            _currentLocation = newLatLng;
            _currentCampus = detectCampus(newLatLng);
            _currentBuildingPoly = detectBuildingPoly(newLatLng);
            _currentBuildingCode = buildingAtLocation?.code;
          });

          if (_isNavigating) {
            _maybeAdvanceNavigationStep(newLatLng);
          }
          if (_navigationFollowUser) {
            _maybeUpdateCameraForNavigation(newLatLng, position.heading);
          }
        });
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: _blueDotIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 999,
        ),
      );
    }

    // Shuttle stop markers
    final shuttleIcon = _shuttleStopIcon;
    if (shuttleIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('shuttle_stop_sgw'),
          position: shuttleStopSGW,
          icon: shuttleIcon,
          infoWindow: const InfoWindow(
            title: 'Concordia Shuttle — SGW',
            snippet: 'Hall Building stop',
          ),
          onTap: () {
            if (_showRoutePreview) {
              setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
              _fetchShuttleInfo();
            }
          },
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('shuttle_stop_loyola'),
          position: shuttleStopLoyola,
          icon: shuttleIcon,
          infoWindow: const InfoWindow(
            title: 'Concordia Shuttle — Loyola',
            snippet: 'Loyola campus stop',
          ),
          onTap: () {
            if (_showRoutePreview) {
              setState(() => _selectedTravelMode = RouteTravelMode.shuttle);
              _fetchShuttleInfo();
            }
          },
        ),
      );
    }

    // Add destination room marker only when indoor map is shown
    if (_destinationRoomMarker != null && _showIndoor) {
      markers.add(_destinationRoomMarker!);
    }

    if (_showRoutePreview) {
      if (_routeDestination != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('route_destination'),
            position: _routeDestination!,
            infoWindow: InfoWindow(title: _routeDestinationText),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Circle> _createCircles() {
    final circles = <Circle>{};

    if (_currentLocation == null) return {};

    circles.add(
      Circle(
        circleId: const CircleId('current_location_accuracy'),
        center: _currentLocation!,
        radius: 20,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 1,
      ),
    );

    if (_showRoutePreview && _selectedTravelMode == RouteTravelMode.transit) {
      final segments = _routeSegmentsByMode['transit'] ?? const [];
      final seen = <String>{};

      for (final segment in segments) {
        if (segment.travelMode.toUpperCase() != 'TRANSIT') {
          continue;
        }
        if (segment.points.isEmpty) {
          continue;
        }

        final endpoints = [segment.points.first, segment.points.last];
        for (final point in endpoints) {
          final key =
              '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
          if (!seen.add(key)) {
            continue;
          }

          circles.add(
            Circle(
              circleId: CircleId('transit_stop_$key'),
              center: point,
              radius: 15,
              fillColor: Colors.white,
              strokeColor: const Color(0xFF76263D),
              strokeWidth: 2,
            ),
          );
        }
      }
    }

    return circles;
  }

  NavigationStep? _getCurrentNavStep() {
    final key = _navModeKey;
    if (key == null) return null;

    final steps = _routeStepsByMode[key] ?? const [];
    if (steps.isEmpty) return null;

    if (_navStepIndex < 0 || _navStepIndex >= steps.length) return null;
    return steps[_navStepIndex];
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
        return;
    }

    _lastCameraTarget = targetLocation;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(targetLocation, 16),
    );

    setState(() {
      _selectedCampus = newCampus;
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _cameraMoving = false;
      _searchController.clear();
    });
  }

  Offset? _computePopupPosition(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    final anchor = widget.debugAnchorOffset ?? _anchorOffset;
    if (anchor == null || _cameraMoving) return null;

    final ax = anchor.dx;
    final ay = anchor.dy;

    final inView =
        ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;
    if (!inView) return null;

    double left = ax - (_popupW / 2);
    double top = ay - (_popupH / 2);

    const margin = 8.0;
    final minLeft = margin;
    final maxLeft = screen.width - _popupW - margin;
    final minTop = topPad + margin;
    final maxTop = screen.height - _popupH - margin;

    if (left < minLeft) left = minLeft;
    if (left > maxLeft) left = maxLeft;
    if (top < minTop) top = minTop;
    if (top > maxTop) top = maxTop;

    return Offset(left, top);
  }

  Future<void> _onDestinationRoomSubmitted(
    String buildingCode,
    String roomCode,
  ) async {
    print('[DEBUG] Destination room submitted: $roomCode in $buildingCode');

    try {
      final repo = IndoorMapRepository();
      final roomLocation = await repo.getRoomLocation(buildingCode, roomCode);

      if (roomLocation == null) {
        print('[ERROR] Could not find location for room $roomCode');
        return;
      }
      print('[DEBUG] Room location found: $roomLocation');
      final marker = Marker(
        markerId: const MarkerId('destination_room'),
        position: roomLocation,
        infoWindow: InfoWindow(title: 'Room $roomCode'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      if (!mounted) return;
      setState(() {
        _destinationRoomMarker = marker;
      });

      print('[DEBUG] Destination room marker placed at $roomLocation');
    } catch (e) {
      print('[ERROR] Error processing destination room: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget =
        widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

    final Campus labelCampus =
        _selectedCampus != Campus.none ? _selectedCampus : _currentCampus;

    final String campusLabel = labelCampus == Campus.sgw
        ? 'SGW'
        : labelCampus == Campus.loyola
            ? 'Loyola'
            : '';

    final selectedBuilding = widget.debugSelectedBuilding ?? _selectedBuildingPoly;
    final popupPos = _computePopupPosition(context);

    return Scaffold(
      body: Stack(
        children: [
          if (widget.debugDisableMap)
            const SizedBox.expand()
          else
            OutdoorMapView(
              initialTarget: initialTarget,
              showIndoorStyle: _showIndoor,
              indoorMapStyle: _indoorMapStyle,
              onMapCreated: (c) => _mapController = c,
              onCameraMove: (pos) {
                _lastCameraTarget = pos.target;
                if (_selectedBuildingCenter != null) _schedulePopupUpdate();
              },
              onCameraMoveStarted: () {
                if (_selectedBuildingCenter == null) return;
                setState(() => _cameraMoving = true);
              },
              onCameraIdle: () {
                _syncToggleWithCameraCenter();
                if (_selectedBuildingCenter == null) return;
                setState(() => _cameraMoving = false);
                _updatePopupOffset();
              },
              markers: {
                ..._createMarkers(),
                ..._roomLabelMarkers,
              },
              circles: _createCircles(),
              polygons: {
                ..._createBuildingPolygons(),
                ..._indoorPolygons,
              },
              polylines: _routePolylines,
            ),

          if (_isNavigating)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: NavigationNextStepHeader(
                  modeLabel: _selectedTravelMode.label,
                  nextStep: _getCurrentNavStep(),
                  onStop: _stopNavigation,
                  onShowSteps: _openStepsForSelectedMode,
                ),
              ),
            ),

          if (_showRoutePreview && !_isNavigating)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: RoutePreviewPanel(
                originText: _routeOriginText,
                destinationText: _routeDestinationText,
                onClose: _closeRoutePreview,
                onSwitch: _switchOriginDestination,
                onOriginChanged: _onRouteOriginChanged,
                onDestinationChanged: _onRouteDestinationChanged,
                onOriginSelected: _onRouteOriginSelected,
                onDestinationSelected: _onRouteDestinationSelected,
                originSuggestions: _routeOriginSuggestions,
                destinationSuggestions: _routeDestinationSuggestions,
                originRoomController: _originRoomController,
                destinationRoomController: _destinationRoomController,
                onOriginRoomSubmitted: _onOriginRoomSubmitted,
                onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
                originBuildingCode: _routeOriginBuildingCode,
                destinationBuildingCode: _routeDestinationBuildingCode,
                isConcordiaBuilding: (buildingCode) {
                  return buildingPolygons.any(
                    (b) => (b.code ?? '').toUpperCase() == buildingCode.toUpperCase(),
                  );
                },
              ),
            ),

          if (_showRoutePreview)
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: Center(
                  child: RouteTravelModeBar(
                    selectedTravelMode: _selectedTravelMode,
                    onTravelModeSelected: _onTravelModeSelected,
                    modeDurations: _routeDurations,
                    isLoadingDurations: _isLoadingRouteData,
                    onClose: _closeRoutePreview,
                    onStart: _startNavigation,
                    isNavigating: _isNavigating,
                    onShowSteps: _openStepsForSelectedMode,
                    transitDetails: _buildTransitDetailItems(),
                    modeDistances: _routeDistances,
                    modeArrivalTimes: _routeArrivalTimes,
                    shuttleNextBuses:
                        _shuttleNextBuses.map((b) => b.statusLabel).toList(),
                    shuttleWalkingMinutes: _shuttleWalkingMinutes,
                    shuttleNearestStop: _shuttleNearestStop,
                    onViewSchedule: _showShuttleScheduleModal,
                  ),
                ),
              ),
            ),

          if (!_showRoutePreview && !_isNavigating)
            OutdoorTopSearch(
              campusLabel: campusLabel,
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              suggestions: _searchSuggestions,
              onSuggestionSelected: _onSuggestionSelected,
              onFocus: _hideBuildingPopup,
              originRoomController: _originRoomController,
              destinationRoomController: _destinationRoomController,
              onOriginRoomSubmitted: _onOriginRoomSubmitted,
              onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
              selectedBuildingCode: _selectedBuildingPoly?.code,
              currentBuildingCode: _currentBuildingCode,
              userLocation: _currentLocation,
              isConcordiaBuilding: (buildingCode) {
                return buildingPolygons.any(
                  (b) =>
                      (b.code ?? '').toUpperCase() ==
                      buildingCode.toUpperCase(),
                );
              },
              showIndoor: _showIndoor,
              floors: _indoorFloors,
              selectedAssetPath: _selectedIndoorFloorAsset,
              onFloorChanged: _loadIndoorFloor,
            ),

          if (selectedBuilding != null && popupPos != null)
            OutdoorBuildingPopup(
              building: selectedBuilding,
              position: popupPos,
              buildingInfoByCode: buildingInfoByCode,
              debugLinkOverride: widget.debugLinkOverride,
              onClose: _closePopup,
              onIndoorMap: _toggleIndoorMap,
              onGetDirections: _getDirections,
              onOpenLink: _openLink,
              isLoggedIn: widget.isLoggedIn,
            ),

          if (!_showRoutePreview)
            OutdoorBottomControls(
              currentLocation: _currentLocation,
              currentCampus: _currentCampus,
              onGoToMyLocation: _goToMyLocation,
              onCenterOnUser: () {
                final loc = _currentLocation;
                if (loc == null) return;
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
              },
            ),

          if (!_showRoutePreview)
            OutdoorBottomBar(
              showRoutePreview: _showRoutePreview,
              isNavigating: _isNavigating,
              selectedCampus: _selectedCampus,
              onCampusChanged: _switchCampus,
              selectedTravelMode: _selectedTravelMode,
              onTravelModeSelected: _onTravelModeSelected,
              routeDurations: _routeDurations,
              routeDistances: _routeDistances,
              routeArrivalTimes: _routeArrivalTimes,
              isLoadingRouteData: _isLoadingRouteData,
              onCloseRoutePreview: _closeRoutePreview,
              onStartNavigation: _startNavigation,
              onShowSteps: _openStepsForSelectedMode,
              transitDetails: _buildTransitDetailItems(),
            ),

          ..._createBuildingGestureDetectors(),
        ],
      ),
    );
  }

  static const String _indoorMapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "poi.school",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "poi.business",
      "stylers": [
        { "visibility": "off" }
      ]
    },
    {
      "featureType": "transit",
      "stylers": [
        { "visibility": "off" }
      ]
    }
  ]
  ''';

  @override
  void dispose() {
    _posSub?.cancel();
    _popupDebounce?.cancel();
    _debounceTimer?.cancel();
    _routeDebounceTimer?.cancel();
    _mapController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _originRoomController.dispose();
    _destinationRoomController.dispose();
    super.dispose();
  }
}


class _ShuttleScheduleSheet extends StatelessWidget {
  final String nearestStop;

  const _ShuttleScheduleSheet({required this.nearestStop});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);
    final today = DateTime.now();
    final times = ConcordiaShuttleService.getFullScheduleForDay(today);
    final isWeekday =
        today.weekday >= DateTime.monday && today.weekday <= DateTime.friday;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus_filled, color: burgundy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Concordia Shuttle Schedule',
                            style: TextStyle(
                              color: burgundy,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isWeekday
                                ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
                                : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _StopChip(
                        label: 'SGW  (Hall Building)', color: burgundy),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.sync_alt,
                          size: 16, color: Colors.black45),
                    ),
                    _StopChip(label: 'Loyola', color: burgundy),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: times.length,
                  itemBuilder: (context, index) {
                    final t = times[index];
                    final now = DateTime.now();
                    final isPast = t.isBefore(now);
                    final isNext = !isPast &&
                        (index == 0 || times[index - 1].isBefore(now));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isNext
                            ? burgundy.withOpacity(0.08)
                            : Colors.transparent,
                        border: isNext
                            ? Border.all(color: burgundy.withOpacity(0.3))
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_bus_filled,
                            size: 16,
                            color: isPast
                                ? Colors.black26
                                : isNext
                                    ? burgundy
                                    : Colors.black54,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            ConcordiaShuttleService.formatTime(t),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isNext
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isPast
                                  ? Colors.black26
                                  : isNext
                                      ? burgundy
                                      : Colors.black87,
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: burgundy,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Next bus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StopChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StopChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}