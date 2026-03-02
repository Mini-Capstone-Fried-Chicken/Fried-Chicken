import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/map_search_bar.dart';
import '../building_detection.dart';
import '../../data/building_polygons.dart';
import '../../shared/widgets/campus_toggle.dart';
import '../../shared/widgets/building_info_popup.dart';
import '../../features/indoor/data/building_info.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';

// concordia campus coordinates
const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
const double campusRadius = 500; // meters

// when camera center is within this distance auto-switch toggle
const double campusAutoSwitchRadius = 500; // meters

enum Campus { sgw, loyola, none }

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
    required this.isLoggedIn,
    this.debugSelectedBuilding,
    this.debugAnchorOffset,
    this.debugDisableMap = false,
    this.debugDisableLocation = false,
    this.debugLinkOverride,
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

// Indoor overlay state
Set<Polygon> _indoorPolygons = {};
bool _showIndoor = false;

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _cameraMoving = false;

  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;
  BuildingPolygon? _currentBuildingPoly;
  BuildingPolygon? _selectedBuildingPoly;
  Map<String, dynamic>? _indoorGeoJson;
  Set<Marker> _roomLabelMarkers = {};

  StreamSubscription<Position>? _posSub;

  Timer? _popupDebounce;

  static const double _popupW = 300;
  static const double _popupH = 260;

  LatLng? _selectedBuildingCenter;
  Offset? _anchorOffset;

  Campus _currentCampus = Campus.none;
  Campus _selectedCampus = Campus.none;

  LatLng? _lastCameraTarget;

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

  Future<void> _toggleIndoorMap() async {
  final b = _selectedBuildingPoly;
  if (b == null) return;

  // Support Hall (H), MB, VE, VL, and CC
  String? assetPath;
  if (b.code.toUpperCase() == 'H') {
    assetPath = 'assets/indoor_maps/geojson/Hall/h1.geojson.json';
  } else if (b.code.toUpperCase() == 'MB') {
    assetPath = 'assets/indoor_maps/geojson/MB/mb1.geojson.json';
  } else if (b.code.toUpperCase() == 'VE') {
    assetPath = 'assets/indoor_maps/geojson/VE/VE2.geojson.json';
  } else if (b.code.toUpperCase() == 'VL') {
    assetPath = 'assets/indoor_maps/geojson/VL/VL2.geojson.json';
  } else if (b.code.toUpperCase() == 'CC') {
    assetPath = 'assets/indoor_maps/geojson/CC/cc1.geojson.json';
  } else {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Indoor map currently only available for Hall (H), MB, VE, VL, and CC'),
      ),
    );
    return;
  }

  if (_showIndoor) {
    setState(() {
      _showIndoor = false;
      _indoorPolygons = {};
      _indoorGeoJson = null;
      _roomLabelMarkers = {};
    });
    return;
  }

  try {
    final repo = IndoorMapRepository();
    final geo = await repo.loadGeoJsonAsset(assetPath);

    final polys = _geoJsonToPolygons(geo);
    final labels = await _createRoomLabels(geo);

    if (!mounted) return;
    setState(() {
      _showIndoor = true;
      _indoorPolygons = polys;
      _indoorGeoJson = geo;
      _roomLabelMarkers = labels;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to load indoor map: $e')));
  }
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
      // optional: show a snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }

  // ...existing code...

  LatLng _polygonCenter(List<LatLng> pts) {
    if (pts.length < 3) return pts.first;

    // First try: simple average
    double lat = 0;
    double lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final avg = LatLng(lat / pts.length, lng / pts.length);

    // Check if the average point is inside the polygon
    if (_isPointInPolygon(avg, pts)) return avg;

    // Fallback: try midpoint of the longest diagonal
    double maxDist = 0;
    LatLng best = avg;
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final mid = LatLng(
          (pts[i].latitude + pts[j].latitude) / 2,
          (pts[i].longitude + pts[j].longitude) / 2,
        );
        final dist = (pts[i].latitude - pts[j].latitude) *
                (pts[i].latitude - pts[j].latitude) +
            (pts[i].longitude - pts[j].longitude) *
                (pts[i].longitude - pts[j].longitude);
        if (dist > maxDist && _isPointInPolygon(mid, pts)) {
          maxDist = dist;
          best = mid;
        }
      }
    }

    return best;
  }

  /// Ray-casting algorithm to check if a point is inside a polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      if (((yi > point.longitude) != (yj > point.longitude)) &&
          (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Calculates the approximate area of a polygon in square degrees
  double _polygonArea(List<LatLng> pts) {
    double area = 0;
    int j = pts.length - 1;
    for (int i = 0; i < pts.length; i++) {
      area += (pts[j].longitude + pts[i].longitude) *
          (pts[j].latitude - pts[i].latitude);
      j = i;
    }
    return area.abs() / 2;
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

  void _selectBuildingWithoutMap(BuildingPolygon b) {
    final center = _polygonCenter(b.points);
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
    final center = _polygonCenter(b.points);
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
    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _searchController.clear();
    });
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

  @override
  void initState() {
    super.initState();

    _selectedCampus = widget.initialCampus;

    _lastCameraTarget = widget.initialCampus == Campus.loyola
        ? concordiaLoyola
        : concordiaSGW;

    _createBlueDotIcon();
    if (!widget.debugDisableLocation) {
      _startLocationUpdates();
    }

    final debugB = widget.debugSelectedBuilding;
    if (debugB != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectBuildingWithoutMap(debugB);
      });
    }
  }

  Future<void> _createBlueDotIcon() async {
    _blueDotIcon =
        await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/blue_dot.png',
        ).catchError((_) {
          return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
        });

    _blueDotIcon ??= BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
  }

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

      if (!mounted) return;
      setState(() {
        _currentLocation = newLatLng;
        _currentCampus = detectCampus(newLatLng);
        _currentBuildingPoly = detectBuildingPoly(newLatLng);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    } catch (_) {}

    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((position) {
          final newLatLng = LatLng(position.latitude, position.longitude);

          if (!mounted) return;
          setState(() {
            _currentLocation = newLatLng;
            _currentCampus = detectCampus(newLatLng);
            _currentBuildingPoly = detectBuildingPoly(newLatLng);
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
        radius: 20,
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

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = widget.initialCampus == Campus.loyola
        ? concordiaLoyola
        : concordiaSGW;

    final Campus labelCampus = _selectedCampus;

    final String campusLabel = labelCampus == Campus.sgw
        ? 'SGW'
        : labelCampus == Campus.loyola
        ? 'Loyola'
        : '';

    final screen = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;

    double? popupLeft;
    double? popupTop;

    if (_anchorOffset != null && !_cameraMoving) {
      final ax = _anchorOffset!.dx;
      final ay = _anchorOffset!.dy;

      final inView =
          ax >= 0 && ax <= screen.width && ay >= topPad && ay <= screen.height;

      if (inView) {
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

        popupLeft = left;
        popupTop = top;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          if (widget.debugDisableMap)
            const SizedBox.expand()
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 16,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
                            style: _showIndoor ? _indoorMapStyle : null, // Hide POIs when indoor map is showing

              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (pos) {
                _lastCameraTarget = pos.target;
                if (_selectedBuildingCenter != null) {
                  _schedulePopupUpdate();
                }
              },
              onCameraMoveStarted: () {
                if (_selectedBuildingCenter == null) return;
                setState(() {
                  _cameraMoving = true;
                });
              },
              onCameraIdle: () {
                _syncToggleWithCameraCenter();

                if (_selectedBuildingCenter == null) return;
                setState(() {
                  _cameraMoving = false;
                });
                _updatePopupOffset();
              },
              markers: {
                ..._createMarkers(),
                if (_showIndoor) ..._roomLabelMarkers,
              },
              circles: _createCircles(),
              polygons: {..._createBuildingPolygons(), ..._indoorPolygons},
            ),
          Positioned(
            top: 65,
            left: 20,
            right: 20,
            child: MapSearchBar(
              campusLabel: campusLabel,
              controller: _searchController,
            ),
          ),

          if (_selectedBuildingPoly != null &&
              popupLeft != null &&
              popupTop != null)
            Positioned(
              left: popupLeft,
              top: popupTop,
              child: PointerInterceptor(
                child: BuildingInfoPopup(
                  title:
                      '${buildingInfoByCode[_selectedBuildingPoly!.code]?.name ?? _selectedBuildingPoly!.name} - ${_selectedBuildingPoly!.code}',
                  description:
                      buildingInfoByCode[_selectedBuildingPoly!.code]
                          ?.description ??
                      'No description available.',
                  accessibility:
                      buildingInfoByCode[_selectedBuildingPoly!.code]
                          ?.accessibility ??
                      false,
                  facilities:
                      buildingInfoByCode[_selectedBuildingPoly!.code]
                          ?.facilities ??
                      const [],
                  onMore: () {
                    final link =
                        widget.debugLinkOverride ??
                        (buildingInfoByCode[_selectedBuildingPoly!.code]
                                ?.link ??
                            '');
                    _openLink(link);
                  },
                  onClose: _closePopup,
                  isLoggedIn: widget.isLoggedIn,
                  onIndoorMap: _toggleIndoorMap,
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 290,
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

  Set<Polygon> _geoJsonToPolygons(Map<String, dynamic> geojson) {
    final features = (geojson['features'] as List).cast<dynamic>();

    final polygons = <Polygon>{};

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      if (geometry['type'] != 'Polygon') continue;

      final rings = geometry['coordinates'] as List;
      if (rings.isEmpty) continue;

      final outer = rings[0] as List;

      final points = outer.map<LatLng>((p) {
        final coords = p as List;
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        return LatLng(lat, lng); // GeoJSON is [lng,lat]
      }).toList();

      if (points.length < 3) continue;

      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      final id = (props['ref'] ?? polygons.length).toString();

      // Determine fill color based on feature type
      Color fillColor;
      if (props['escalators'] == 'yes') {
        fillColor = Colors.green; // Escalator = green
      } else if (props['highway'] == 'elevator') {
        fillColor = Colors.orange; // Elevator = orange
      } else if (props['highway'] == 'steps') {
        fillColor = Colors.pink; // Steps = pink
      } else if (props['amenity'] == 'toilets') {
        fillColor = Colors.blue; // Toilets = blue
      } else if (props['indoor'] == 'corridor') {
        fillColor = const Color.fromARGB(255, 232, 122, 149); // Corridor = lighter red
      } else {
        fillColor = const Color(0xFF800020); // Default room = dark red
      }

      polygons.add(
        Polygon(
          polygonId: PolygonId('indoor-$id'),
          points: points,
          strokeWidth: 2,
          strokeColor: Colors.black,
          fillColor: fillColor.withOpacity(1.0),
          zIndex: 20,
        ),
      );
    }

    return polygons;
  }


  Future<BitmapDescriptor> _createTextBitmap(String text, {double fontSize = 10}) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    painter.layout();

    final width = painter.width.ceil();
    final height = painter.height.ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    painter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }


  /// Creates text labels at the center of each room polygon
  Future<Set<Marker>> _createRoomLabels(Map<String, dynamic> geojson) async {
    final features = (geojson['features'] as List).cast<dynamic>();
    final markers = <Marker>{};
    int index = 0;

    for (final f in features) {
      final feature = f as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final props =
          (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

      if (geometry['type'] != 'Polygon') continue;
      if (props['indoor'] != 'room') continue;
      if (props['ref'] == null) continue;

      final rings = geometry['coordinates'] as List;
      if (rings.isEmpty) continue;
      final outer = rings[0] as List;

      final points = outer.map<LatLng>((p) {
        final coords = p as List;
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();

      if (points.length < 3) continue;

      // Skip very small polygons where text won't fit
      final area = _polygonArea(points);
      if (area < 1e-10) continue;

      final center = _polygonCenter(points);
      final ref = props['ref'].toString();

      // Choose font size based on polygon area
      final double fontSize = area > 5e-8 ? 10 : 8;
      final icon = await _createTextBitmap(ref, fontSize: fontSize);

      markers.add(
        Marker(
          markerId: MarkerId('room-label-${index++}-$ref'),
          position: center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 30,
          consumeTapEvents: false,
          infoWindow: InfoWindow.noText,
        ),
      );
    }

    return markers;
  }


  void _turnOffIndoorMap() {
    if (_showIndoor) {
      setState(() {
        _showIndoor = false;
        _indoorPolygons = {};
        _indoorGeoJson = null;
        _roomLabelMarkers = {};
      });
    }
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
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
