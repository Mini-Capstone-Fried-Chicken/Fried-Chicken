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

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _cameraMoving = false;

  GoogleMapController? _mapController;

  LatLng? _currentLocation;
  BitmapDescriptor? _blueDotIcon;
  BuildingPolygon? _currentBuildingPoly;
  BuildingPolygon? _selectedBuildingPoly;

  StreamSubscription<Position>? _posSub;

  Timer? _popupDebounce;

  static const double _popupW = 300;
  static const double _popupH = 260;

  LatLng? _selectedBuildingCenter;
  Offset? _anchorOffset;

  Campus _currentCampus = Campus.none;
  Campus _selectedCampus = Campus.none;

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
    final controller = _mapController;
    if (!mounted || controller == null) return;

    LatLng center;

    try {
      final bounds = await controller.getVisibleRegion();
      final lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
      final lng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      center = LatLng(lat, lng);
    } catch (_) {
      return;
    }

    final newCampus = _campusFromPoint(center);

    if (newCampus == _selectedCampus) return;

    setState(() {
      _selectedCampus = newCampus; 
    });
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

    controller.animateCamera(
      CameraUpdate.newLatLngZoom(loc, 17),
    );
  }

  Future<void> _openLink(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  LatLng _polygonCenter(List<LatLng> pts) {
    if (pts.length < 3) return pts.first;

    double area = 0;
    double cx = 0;
    double cy = 0;

    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];

      final x1 = p1.longitude;
      final y1 = p1.latitude;
      final x2 = p2.longitude;
      final y2 = p2.latitude;

      final cross = x1 * y2 - x2 * y1;
      area += cross;
      cx += (x1 + x2) * cross;
      cy += (y1 + y2) * cross;
    }

    area *= 0.5;
    if (area.abs() < 1e-12) return pts.first;

    cx /= (6 * area);
    cy /= (6 * area);

    return LatLng(cy, cx);
  }

  void _schedulePopupUpdate() {
    _popupDebounce?.cancel();
    _popupDebounce = Timer(const Duration(milliseconds: 16), _updatePopupOffset);
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

    controller.animateCamera(CameraUpdate.newLatLngZoom(center, 18)).then((_) async {
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

      final strokeWidth = isSelected ? 3 : isCurrent ? 3 : 2;
      final zIndex = isSelected ? 3 : isCurrent ? 2 : 1;

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
    _blueDotIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/blue_dot.png',
    ).catchError((_) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    });

    _blueDotIcon ??=
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newLatLng),
      );
    } catch (_) {}

    _posSub = Geolocator.getPositionStream(
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
    final LatLng initialTarget =
        widget.initialCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;

    //  campus label follows the camera
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
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (pos) {
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
              markers: _createMarkers(),
              circles: _createCircles(),
              polygons: _createBuildingPolygons(),
            ),
          Positioned(
            top: 65,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 70,
              child: MapSearchBar(
                campusLabel: campusLabel,
                controller: _searchController,
              ),
            ),
          ),
          if (_selectedBuildingPoly != null && popupLeft != null && popupTop != null)
            Positioned(
              left: popupLeft,
              top: popupTop,
              child: PointerInterceptor(
                child: BuildingInfoPopup(
                  title:
                      '${buildingInfoByCode[_selectedBuildingPoly!.code]?.name ?? _selectedBuildingPoly!.name} - ${_selectedBuildingPoly!.code}',
                  description:
                      buildingInfoByCode[_selectedBuildingPoly!.code]?.description ??
                          'No description available.',
                  accessibility:
                      buildingInfoByCode[_selectedBuildingPoly!.code]?.accessibility ??
                          false,
                  facilities:
                      buildingInfoByCode[_selectedBuildingPoly!.code]?.facilities ??
                          const [],
                  onMore: () {
                    final link = widget.debugLinkOverride ??
                        (buildingInfoByCode[_selectedBuildingPoly!.code]?.link ?? '');
                    _openLink(link);
                  },
                  onClose: _closePopup,
                  isLoggedIn: widget.isLoggedIn,
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

  @override
  void dispose() {
    _posSub?.cancel();
    _popupDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
