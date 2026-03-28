import 'dart:async';
import 'dart:ui' as ui;

import 'package:campus_app/models/campus.dart';
import 'package:campus_app/utils/geo.dart' as geo;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/building_polygons.dart';
import '../../data/search_result.dart';
import '../../data/search_suggestion.dart';
import '../../features/indoor/data/building_info.dart';
import '../../features/saved/saved_directions_controller.dart';
import '../../features/saved/saved_place.dart';
import '../../features/settings/app_settings.dart';
import '../../services/concordia_shuttle_service.dart';
import '../../services/navigation_steps.dart';
import '../../services/nearby_poi_service.dart';
import '../../services/poi_icon_factory.dart';
import '../../shared/widgets/building_info_popup.dart';
import '../../shared/widgets/outdoor/outdoor_bottom_bar.dart';
import '../../shared/widgets/outdoor/outdoor_bottom_controls.dart';
import '../../shared/widgets/outdoor/outdoor_building_popup.dart';
import '../../shared/widgets/outdoor/outdoor_map_view.dart';
import '../../shared/widgets/outdoor/outdoor_top_search.dart';
import '../../shared/widgets/route_preview_panel.dart';
import '../building_detection.dart';
import '../building_search_service.dart';
import '../google_directions_service.dart';
import '../google_places_service.dart';
import '../indoor_maps/indoor_floor_config.dart';
import '../indoor_maps/indoor_map_controller.dart';
import '../indoors_routing/core/indoor_route_plan_models.dart';
import '../indoors_routing/core/indoor_routing_models.dart';
import 'indoor_manual_navigation_controller.dart';
import 'indoor_navigation_session.dart';
import 'indoor_route_service.dart';
import 'shuttle_route_service.dart';

// concordia campus coordinates
const LatLng concordiaSGW = LatLng(45.4973, -73.5789);
const LatLng concordiaLoyola = LatLng(45.4582, -73.6405);
const double campusRadius = 500; // meters
const String currentLocationTag = "Current location";

// Key is injected at build time via --dart-define=GOOGLE_PLACES_API_KEY=...
// Never hardcode the key here — read it from local.properties via run.ps1
const String _googleApiKey = String.fromEnvironment(
  'GOOGLE_PLACES_API_KEY',
  defaultValue: '',
);

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

/// Merges outdoor and indoor polylines into a single set.
/// Returns an empty set if both inputs are empty.
Set<Polyline> mergeMapPolylines({
  required Set<Polyline> outdoorPolylines,
  required Set<Polyline> indoorPolylines,
}) {
  return {...outdoorPolylines, ...indoorPolylines};
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

  @visibleForTesting
  final IndoorRouteService? debugIndoorRouteService;

  @visibleForTesting
  final IndoorMapController? debugIndoorMapController;
  @visibleForTesting
  final Future<BitmapDescriptor> Function(String text)?
  debugBuildingLabelIconFactory;

  const OutdoorMapPage({
    super.key,
    required this.initialCampus,
    this.debugSelectedBuilding,
    this.debugAnchorOffset,
    this.debugDisableMap = false,
    this.debugDisableLocation = false,
    this.debugLinkOverride,
    this.debugIndoorRouteService,
    this.debugIndoorMapController,
    this.debugBuildingLabelIconFactory,
    required this.isLoggedIn,
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  final Map<String, BitmapDescriptor> _buildingLabelIcons = {};
  bool _buildingLabelIconsReady = false;
  late final IndoorRouteService _indoorRouteService;
  final IndoorManualNavigationController _indoorNavigationController =
      IndoorManualNavigationController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _originRoomController = TextEditingController();
  final TextEditingController _destinationRoomController =
      TextEditingController();
  bool _cameraMoving = false;
  List<SearchSuggestion> _searchSuggestions = [];
  Timer? _debounceTimer;

  // Indoor overlay state
  Set<Polygon> _indoorPolygons = {};
  bool _showIndoor = false;
  List<IndoorFloorOption> _indoorFloors = const [];
  String? _selectedIndoorFloorAsset;
  late final IndoorMapController _indoorController;

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
  Set<Marker> _amenityMarkers = {};

  Set<Polyline> _routePolylines = {};

  // Room location marker
  Marker? _originRoomMarker;
  Marker? _destinationRoomMarker;
  String? _currentBuildingCode;
  bool _isBuildingIndoorRoute = false;

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
  IndoorResolvedRoom? _pendingDestinationIndoorRoom;
  bool _autoHandoffToIndoorPending = false;
  IndoorResolvedRoom? _pendingOriginIndoorRoom;
  bool _isOriginIndoorHandoffPhase = false;
  bool _isCompletingOriginIndoorPhase = false;
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
  List<String> _shuttleNextBuses = [];
  int? _shuttleWalkingToDestinationMinutes;
  int? _shuttleWalkingFromDestinationMinutes;
  String _shuttleNearestStop = 'SGW';
  BitmapDescriptor? _shuttleStopIcon;
  int? _shuttleTotalTripDuration; // ignore: unused_field
  ShuttleRouteData? _shuttleRouteData;

  // POI state
  List<PoiPlace> _nearbyPois = [];
  bool _poisLoaded = false;
  final Map<PoiCategory, BitmapDescriptor> _poiIcons = {};
  PoiPlace? _selectedPoi;
  PlaceResult? _selectedPoiDetails;
  LatLng? _selectedPoiCenter;

  StreamSubscription<Position>? _posSub;

  Timer? _popupDebounce;

  static const double _popupW = 300;
  static const double _popupH = 260;

  LatLng? _selectedBuildingCenter;
  Offset? _anchorOffset;

  Campus _currentCampus = Campus.none;
  Campus _selectedCampus = Campus.none;

  LatLng? _lastCameraTarget;
  bool _highContrastMode = false;
  bool _wheelchairRoutingDefaultEnabled = false;
  IndoorTransitionMode? _preferredIndoorTransitionMode;

  void _onSavedDirectionsRequested() {
    final place = SavedDirectionsController.notifier.value;
    if (place == null) return;
    unawaited(_startDirectionsForSavedPlace(place));
  }

  Future<LatLng> _resolveOriginForSavedDirections() async {
    if (_currentLocation != null) {
      return _currentLocation!;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final origin = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = origin;
        });
      }
      return origin;
    } catch (_) {
      // Fall back to map context when GPS is unavailable/denied.
    }

    if (_lastCameraTarget != null) {
      return _lastCameraTarget!;
    }

    return _selectedCampus == Campus.loyola ? concordiaLoyola : concordiaSGW;
  }

  Future<void> _startDirectionsForSavedPlace(SavedPlace place) async {
    try {
      final origin = await _resolveOriginForSavedDirections();

      final destination = LatLng(place.latitude, place.longitude);
      final selectedBuilding = _findBuildingByCode(place.id);
      final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

      if (!mounted) return;
      setState(() {
        _selectedBuildingPoly = selectedBuilding;
        _selectedBuildingCenter = null;
        _selectedPoi = null;
        _selectedPoiDetails = null;
        _selectedPoiCenter = null;
        _anchorOffset = null;
        _showRoutePreview = true;
        _routeOrigin = origin;
        _routeDestination = destination;
        _routeOriginText = currentLocationTag;
        _routeDestinationText = place.name;
        _routeOriginBuildingCode = currentBuildingCode;
        _routeDestinationBuildingCode = selectedBuilding?.code;

        // Prefill destination room only when explicitly provided (Calendar Go to Room).
        final requestedRoom = (place.roomCode ?? '').trim();
        if (requestedRoom.isNotEmpty) {
          _destinationRoomController.text = requestedRoom;
        }
      });

      await _fetchRoutesAndDurations();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start directions for this place.'),
        ),
      );
    } finally {
      SavedDirectionsController.clear();
    }
  }

  void _onAppSettingsChanged() {
    final settings = AppSettingsController.state;
    final highContrastEnabled = settings.highContrastModeEnabled;
    final wheelchairRoutingEnabled = settings.wheelchairRoutingDefaultEnabled;

    final highContrastChanged = highContrastEnabled != _highContrastMode;

    if (!mounted ||
        (!highContrastChanged &&
            wheelchairRoutingEnabled == _wheelchairRoutingDefaultEnabled)) {
      return;
    }

    setState(() {
      _highContrastMode = highContrastEnabled;
      _wheelchairRoutingDefaultEnabled = wheelchairRoutingEnabled;
      if (_wheelchairRoutingDefaultEnabled) {
        _preferredIndoorTransitionMode = IndoorTransitionMode.elevator;
      }
    });

    if (highContrastChanged) {
      unawaited(initBuildingLabelIcons());
    }
  }

  bool get _isIndoorNavigationActive => _indoorNavigationController.isActive;

  IndoorNavigationSession? get _activeIndoorSession =>
      _indoorNavigationController.session;

  NavigationStep? get _currentIndoorStep =>
      _indoorNavigationController.currentStep;

  void _onIndoorNavigationChanged() {
    _syncIndoorNavigationUi();
    _maybeAutoCompleteOriginIndoorPhase();
  }

  void _maybeAutoCompleteOriginIndoorPhase() {
    if (!_isOriginIndoorHandoffPhase) return;
    if (_isCompletingOriginIndoorPhase) return;
    if (!_isIndoorNavigationActive) return;
    if (_indoorNavigationController.canGoNext) return;

    _isCompletingOriginIndoorPhase = true;
    unawaited(
      _completeOriginIndoorPhaseAndStartOutdoor().whenComplete(() {
        _isCompletingOriginIndoorPhase = false;
      }),
    );
  }

  Future<void> _syncIndoorNavigationUi() async {
    final session = _activeIndoorSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _originRoomMarker = null;
        _destinationRoomMarker = null;
        _routePolylines = {};
        _isBuildingIndoorRoute = false;
      });
      return;
    }

    final displayedFloorAssetPath =
        _indoorNavigationController.displayedFloorAssetPath;
    if (displayedFloorAssetPath != null &&
        displayedFloorAssetPath != _selectedIndoorFloorAsset) {
      await _loadIndoorFloor(displayedFloorAssetPath);
    }

    final currentStep = _currentIndoorStep;
    final progressPoint =
        currentStep?.startPoint ??
        (displayedFloorAssetPath ==
                session.routePlan.destinationRoom.floorAssetPath
            ? session.routePlan.destinationRoom.center
            : session.routePlan.originRoom.center);
    final showDestinationMarker =
        displayedFloorAssetPath ==
        session.routePlan.destinationRoom.floorAssetPath;

    if (!mounted) return;
    setState(() {
      _originRoomMarker = _indoorRouteService.buildIndoorProgressMarker(
        progressPoint,
        title: currentStep?.instruction,
      );
      _destinationRoomMarker = showDestinationMarker
          ? session.destinationMarker
          : null;
      _routePolylines = displayedFloorAssetPath == null
          ? {}
          : session.polylinesByFloorAsset[displayedFloorAssetPath] ?? {};
      _isBuildingIndoorRoute = true;
    });
  }

  void _clearIndoorState() {
    _showIndoor = false;
    _indoorFloors = const [];
    _selectedIndoorFloorAsset = null;
    _indoorPolygons = {};
    _indoorGeoJson = null;
    _roomLabelMarkers = {};
    _amenityMarkers = {};
    _originRoomMarker = null;
    _destinationRoomMarker = null;
    _isBuildingIndoorRoute = false;
  }

  void _clearPendingDestinationIndoorHandoff() {
    _pendingDestinationIndoorRoom = null;
    _autoHandoffToIndoorPending = false;
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

  String? _resolvedIndoorOriginBuildingCode() {
    if (_showRoutePreview) {
      return _resolveBuildingCode(
        explicitCode: _routeOriginBuildingCode,
        fallbackText: _routeOriginText,
      );
    }
    return _resolveBuildingCode(
      explicitCode: _selectedBuildingPoly?.code ?? _currentBuildingCode,
    );
  }

  String? _resolvedIndoorDestinationBuildingCode() {
    if (_showRoutePreview) {
      return _resolveBuildingCode(
        explicitCode: _routeDestinationBuildingCode,
        fallbackText: _routeDestinationText,
      );
    }
    return _resolveBuildingCode(explicitCode: _selectedBuildingPoly?.code);
  }

  String? _resolveBuildingCode({String? explicitCode, String? fallbackText}) {
    final normalizedExplicit = explicitCode?.trim();
    if (normalizedExplicit != null && normalizedExplicit.isNotEmpty) {
      final explicitMatch = BuildingSearchService.searchBuilding(
        normalizedExplicit,
      );
      return explicitMatch?.code ?? normalizedExplicit.toUpperCase();
    }

    final normalizedText = fallbackText?.trim();
    if (normalizedText == null || normalizedText.isEmpty) {
      return null;
    }

    final directMatch = BuildingSearchService.searchBuilding(normalizedText);
    if (directMatch != null) {
      return directMatch.code;
    }

    final roomLabelIndex = normalizedText.indexOf('(Room');
    final candidateText = roomLabelIndex > 0
        ? normalizedText.substring(0, roomLabelIndex).trim()
        : normalizedText;

    final fallbackMatch = BuildingSearchService.searchBuilding(candidateText);
    return fallbackMatch?.code;
  }

  String _buildingWithRoomLabel(String buildingCode, String roomCode) {
    final building = BuildingSearchService.searchBuilding(buildingCode);
    final buildingLabel = building == null
        ? buildingCode.toUpperCase()
        : '${building.name} - ${building.code}';
    return '$buildingLabel (Room ${roomCode.toUpperCase()})';
  }

  Future<void> _onOriginRoomSubmitted(
    String buildingCode,
    String roomCode,
  ) async {
    await _maybeStartIndoorNavigationFromRooms();
  }

  Future<void> _maybeStartIndoorNavigationFromRooms() async {
    final originBuildingCode = _resolvedIndoorOriginBuildingCode();
    final destinationBuildingCode = _resolvedIndoorDestinationBuildingCode();
    final originRoomCode = _originRoomController.text.trim();
    final destinationRoomCode = _destinationRoomController.text.trim();

    if (originBuildingCode == null ||
        destinationBuildingCode == null ||
        originRoomCode.isEmpty ||
        destinationRoomCode.isEmpty) {
      return;
    }

    final normalizedOriginBuildingCode = originBuildingCode
        .toUpperCase()
        .trim();
    final normalizedDestinationBuildingCode = destinationBuildingCode
        .toUpperCase()
        .trim();

    if (normalizedOriginBuildingCode != normalizedDestinationBuildingCode) {
      await _prepareCrossBuildingRouteFromRooms(
        originBuildingCode: normalizedOriginBuildingCode,
        destinationBuildingCode: normalizedDestinationBuildingCode,
        originRoomCode: originRoomCode,
        destinationRoomCode: destinationRoomCode,
      );
      return;
    }

    final session = await _indoorRouteService.buildIndoorNavigationSession(
      buildingCode: normalizedOriginBuildingCode,
      originRoomCode: originRoomCode,
      destinationRoomCode: destinationRoomCode,
      preferredTransitionMode: _effectiveIndoorTransitionMode,
    );

    if (session == null) {
      if (!mounted) return;
      final preferredMode = _preferredIndoorTransitionModeLabel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preferredMode == null
                ? 'Select stairs, elevator, or escalator before starting a multi-floor route.'
                : 'Could not build an indoor route using $preferredMode.',
          ),
        ),
      );
      return;
    }

    await _activateIndoorNavigation(session);
  }

  Future<void> _prepareCrossBuildingRouteFromRooms({
    required String originBuildingCode,
    required String destinationBuildingCode,
    required String originRoomCode,
    required String destinationRoomCode,
  }) async {
    final originRoom = await _indoorRouteService.indoorRepository.resolveRoom(
      originBuildingCode,
      originRoomCode,
    );
    final destinationRoom = await _indoorRouteService.indoorRepository
        .resolveRoom(destinationBuildingCode, destinationRoomCode);

    if (originRoom == null || destinationRoom == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not resolve one or both rooms. Please check the room numbers and try again.',
          ),
        ),
      );
      return;
    }

    // Detect whether origin room is on a non-default floor so we can show
    // origin-building indoor navigation before the outdoor leg.
    final originFloors = _indoorController.floorsForBuilding(
      originBuildingCode,
    );
    final isOriginOnNonDefaultFloor =
        originFloors.isNotEmpty &&
        originRoom.floorAssetPath != originFloors.first.assetPath;

    if (!mounted) return;
    setState(() {
      _showRoutePreview = true;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _routeOrigin = originRoom.center;
      _routeDestination = destinationRoom.center;
      _routeOriginBuildingCode = originBuildingCode;
      _routeDestinationBuildingCode = destinationBuildingCode;
      _routeOriginText = _buildingWithRoomLabel(
        originBuildingCode,
        originRoomCode,
      );
      _routeDestinationText = _buildingWithRoomLabel(
        destinationBuildingCode,
        destinationRoomCode,
      );
      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
      _pendingDestinationIndoorRoom = destinationRoom;
      _autoHandoffToIndoorPending = true;
      _pendingOriginIndoorRoom = isOriginOnNonDefaultFloor ? originRoom : null;
    });

    unawaited(_fetchRoutesAndDurations());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cross-building classroom route ready. Tap Start to begin navigation.',
        ),
      ),
    );
  }

  Future<void> _activateIndoorNavigation(
    IndoorNavigationSession session,
  ) async {
    final building = BuildingSearchService.searchBuilding(
      session.routePlan.buildingCode,
    );
    final floors = _indoorController.floorsForBuilding(
      session.routePlan.buildingCode,
    );

    if (building == null || floors.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indoor maps are not available for that building.'),
        ),
      );
      return;
    }

    final center = geo.polygonCenter(building.points);

    final preserveOutdoorRouteState = _isOriginIndoorHandoffPhase;

    if (!mounted) return;
    setState(() {
      _selectedBuildingPoly = building;
      _selectedBuildingCenter = center;
      _anchorOffset = null;
      _cameraMoving = false;
      _showRoutePreview = false;
      _indoorFloors = floors;
      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
      _routePolylines = {};
      _isLoadingRouteData = false;
      if (!preserveOutdoorRouteState) {
        _selectedTravelMode = RouteTravelMode.walking;
        _routeDurations.clear();
        _routeDistances.clear();
        _routeArrivalTimes.clear();
        _routePointsByMode.clear();
        _routeSegmentsByMode.clear();
        _routeStepsByMode.clear();
      }
    });

    _indoorNavigationController.start(session);
    await _syncIndoorNavigationUi();
  }

  void _stopIndoorNavigation() {
    if (_isOriginIndoorHandoffPhase) {
      if (_isCompletingOriginIndoorPhase) return;
      _isCompletingOriginIndoorPhase = true;
      unawaited(
        _completeOriginIndoorPhaseAndStartOutdoor().whenComplete(() {
          _isCompletingOriginIndoorPhase = false;
        }),
      );
      return;
    }

    _indoorNavigationController.stop();
    // If stopping during origin-building indoor phase, cancel the whole
    // cross-building navigation so outdoor and destination indoor also end.
    if (_isOriginIndoorHandoffPhase) {
      setState(() {
        _isOriginIndoorHandoffPhase = false;
        _pendingOriginIndoorRoom = null;
      });
      _clearPendingDestinationIndoorHandoff();
    }
  }

  void _goToPreviousIndoorStep() {
    _indoorNavigationController.previousStep();
  }

  void _goToNextIndoorStep() {
    // When in origin-building phase and already at the last step, pressing
    // Next transitions the user to outdoor navigation.
    if (_isOriginIndoorHandoffPhase && !_indoorNavigationController.canGoNext) {
      if (_isCompletingOriginIndoorPhase) return;
      _isCompletingOriginIndoorPhase = true;
      unawaited(
        _completeOriginIndoorPhaseAndStartOutdoor().whenComplete(() {
          _isCompletingOriginIndoorPhase = false;
        }),
      );
      return;
    }
    _indoorNavigationController.nextStep();
  }

  void _onIndoorTransitionModeChanged(IndoorTransitionMode? mode) {
    if (_wheelchairRoutingDefaultEnabled &&
        mode != IndoorTransitionMode.elevator) {
      return;
    }

    if (_preferredIndoorTransitionMode == mode) {
      return;
    }

    setState(() {
      _preferredIndoorTransitionMode = mode;
    });

    if (_effectiveIndoorTransitionMode != null) {
      unawaited(_maybeStartIndoorNavigationFromRooms());
    }
  }

  String? _preferredIndoorTransitionModeLabel() {
    return switch (_effectiveIndoorTransitionMode) {
      IndoorTransitionMode.stairs => 'stairs',
      IndoorTransitionMode.elevator => 'elevators',
      IndoorTransitionMode.escalator => 'escalators',
      null => null,
    };
  }

  IndoorTransitionMode? get _effectiveIndoorTransitionMode =>
      _wheelchairRoutingDefaultEnabled
      ? IndoorTransitionMode.elevator
      : _preferredIndoorTransitionMode;

  void _openIndoorSteps() {
    final session = _activeIndoorSession;
    if (session == null) {
      return;
    }

    showNavigationStepsModal(
      context,
      title: 'Indoor',
      steps: session.steps,
      totalDuration: session.durationText,
      totalDistance: session.distanceText,
      highContrastMode: _highContrastMode,
    );
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
        _amenityMarkers = result.amenityIcons;
        if (_isIndoorNavigationActive) {
          _routePolylines =
              _activeIndoorSession?.polylinesByFloorAsset[assetPath] ?? {};
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load indoor floor: $e')),
      );
    }
  }

  Future<void> _onIndoorFloorChanged(String assetPath) async {
    await _loadIndoorFloor(assetPath);
    if (_isIndoorNavigationActive) {
      _indoorNavigationController.setDisplayedFloorAssetPath(assetPath);
    }
  }

  Future<void> _toggleIndoorMap() async {
    // turn OFF
    if (_showIndoor) {
      if (_isIndoorNavigationActive) {
        _indoorNavigationController.stop();
      }
      setState(() {
        _clearIndoorState();
        _routePolylines = {};
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
        const SnackBar(
          content: Text('No indoor maps available for this building'),
        ),
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

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open link")));
    } catch (_) {
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
    final center = _selectedBuildingCenter ?? _selectedPoiCenter;
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
      _anchorOffset = widget.debugAnchorOffset;
      _cameraMoving = false;
    });
  }

  void _onBuildingTapped(BuildingPolygon b) {
    if (_isIndoorNavigationActive) {
      _indoorNavigationController.stop();
    }
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
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
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

  Future<void> _onPoiTapped(PoiPlace poi) async {
    final controller = _mapController;

    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _selectedPoi = poi;
      _selectedPoiDetails = null;
      _selectedPoiCenter = poi.location;
      _anchorOffset = null;
      _cameraMoving = true;
      _clearIndoorState();
      _roomLabelMarkers = {};
    });

    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(poi.location, 18),
      );
      if (!mounted) return;
      await _updatePopupOffset();
      if (!mounted) return;
      setState(() {
        _cameraMoving = false;
      });
    }

    final details = await GooglePlacesService.instance.getPlaceDetails(
      poi.placeId,
      includeMetadata: true,
    );

    if (!mounted) return;
    if (_selectedPoi?.placeId != poi.placeId) return;

    setState(() {
      _selectedPoiDetails = details;
    });
  }

  Future<void> _getDirectionsToSelectedPoi() async {
    final poi = _selectedPoi;
    final origin = _currentLocation;
    if (poi == null || origin == null) {
      return;
    }

    final currentBuildingCode = _findBuildingAtLocation(origin)?.code;

    setState(() {
      _selectedBuildingCenter = null;
      _selectedPoiCenter = null;
      _anchorOffset = null;
      _showRoutePreview = true;
      _routeOrigin = origin;
      _routeDestination = poi.location;
      _routeOriginText = currentLocationTag;
      _routeDestinationText = poi.name;
      _routeOriginBuildingCode = currentBuildingCode;
      _routeDestinationBuildingCode = null;
    });

    await _fetchRoutesAndDurations();
  }

  String _poiDescription(PoiPlace poi) {
    final details = _selectedPoiDetails;
    final address = details?.formattedAddress?.trim();
    final category = _poiCategoryLabel(poi.category);

    if (address != null && address.isNotEmpty) {
      return '$address\n$category';
    }

    return category;
  }

  List<String> _poiFacilities() {
    final types = _selectedPoiDetails?.types ?? const <String>[];
    return types.map((t) => t.replaceAll('_', ' ')).toList();
  }

  SavedPlace? _selectedPoiSavedPlace() {
    final poi = _selectedPoi;
    if (poi == null) return null;

    return SavedPlace(
      id: poi.placeId.startsWith('places/')
          ? poi.placeId
          : 'places/${poi.placeId}',
      name: _selectedPoiDetails?.name ?? poi.name,
      category: _poiCategoryLabel(poi.category).toLowerCase(),
      latitude: poi.location.latitude,
      longitude: poi.location.longitude,
      openingHoursToday: 'Open today: Hours unavailable',
      googlePlaceType: _selectedPoiDetails?.primaryType,
    );
  }

  Future<void> _openSelectedPoiLink() async {
    final poi = _selectedPoi;
    if (poi == null) return;
    await _openLink(
      'https://www.google.com/maps/place/?q=place_id:${poi.placeId}',
    );
  }

  void _clearSelectedBuilding({bool clearSearch = false}) {
    _indoorNavigationController.stop();
    setState(() {
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
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
      _shuttleWalkingToDestinationMinutes = null;
      _shuttleWalkingFromDestinationMinutes = null;
      _shuttleTotalTripDuration = null;
      _originRoomMarker = null;
      _destinationRoomMarker = null;
      _isBuildingIndoorRoute = false;
      if (clearSearch) {
        _searchController.clear();
      }
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _anchorOffset = null;
      _destinationRoomMarker = null;
      _routeOriginBuildingCode = null;
      _routeDestinationBuildingCode = null;
      _preferredIndoorTransitionMode = null;
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
        _routeDurations['shuttle'] = '...';
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
      highContrastMode: _highContrastMode,
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
          color: _highContrastMode
              ? AppUiColors.highContrastRoutePreview
              : const Color(0xFF76263D),
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

    // If origin room is on a non-default floor, show origin-building indoor
    // navigation first before the outdoor leg begins.
    if (_pendingOriginIndoorRoom != null) {
      unawaited(_maybeAutoSwitchToOriginIndoorMap());
      return;
    }

    if (_autoHandoffToIndoorPending && steps.isEmpty) {
      unawaited(_maybeAutoSwitchToDestinationIndoorMap());
      return;
    }

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
      _isOriginIndoorHandoffPhase = false;
      _pendingOriginIndoorRoom = null;
    });
    _clearPendingDestinationIndoorHandoff();
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
      final nextIndex = _navStepIndex + 1;
      final reachedFinalStep = nextIndex >= steps.length - 1;
      setState(() => _navStepIndex = nextIndex);
      if (reachedFinalStep) {
        unawaited(_maybeAutoSwitchToDestinationIndoorMap());
      }
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
      _shuttleWalkingToDestinationMinutes = null;
      _shuttleWalkingFromDestinationMinutes = null;
      _shuttleTotalTripDuration = null;
      _searchController.clear();

      //reset indoor map and building selection state
      _selectedBuildingPoly = null;
      _selectedBuildingCenter = null;
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
      _anchorOffset = null;
      _destinationRoomMarker = null;
      _preferredIndoorTransitionMode = null;
      _originRoomController.clear();
      _destinationRoomController.clear();
      _routeOriginBuildingCode = null;
      _routeDestinationBuildingCode = null;
    });
    _clearPendingDestinationIndoorHandoff();
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
    if (_highContrastMode) {
      return AppUiColors.highContrastRoutePreview;
    }

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
    final accent = AppUiColors.primary(highContrastEnabled: _highContrastMode);

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Transit details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
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

  /// Pre-builds all four POI icons then fetches nearby places.
  Future<void> _initPois() async {
    for (final category in PoiCategory.values) {
      _poiIcons[category] = await PoiIconFactory.iconFor(category);
    }
    await _loadNearbyPois();
  }

  /// Fetches POIs centred on SGW and Loyola campuses in parallel.
  Future<void> _loadNearbyPois() async {
    try {
      final results = await Future.wait([
        NearbyPoiService.fetchNearby(concordiaSGW, apiKey: _googleApiKey),
        NearbyPoiService.fetchNearby(concordiaLoyola, apiKey: _googleApiKey),
      ]);

      // Deduplicate by placeId across both campus results
      final seen = <String>{};
      final merged = <PoiPlace>[];
      for (final list in results) {
        for (final poi in list) {
          if (seen.add(poi.placeId)) {
            merged.add(poi);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _nearbyPois = merged;
        _poisLoaded = true;
      });
    } catch (e) {
      print('[POI] Failed to load nearby POIs: $e');
    }
  }

  /// Adds a map marker for every loaded POI.
  void _addPoiMarkers(Set<Marker> markers) {
    if (!_poisLoaded) return;

    for (final poi in _nearbyPois) {
      final icon = _poiIcons[poi.category];
      if (icon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('poi_${poi.placeId}'),
          position: poi.location,
          icon: icon,
          onTap: () => unawaited(_onPoiTapped(poi)),
          zIndexInt: 0,
        ),
      );
    }
  }

  String _poiCategoryLabel(PoiCategory category) {
    switch (category) {
      case PoiCategory.cafe:
        return 'Cafe';
      case PoiCategory.restaurant:
        return 'Restaurant';
      case PoiCategory.pharmacy:
        return 'Pharmacy';
      case PoiCategory.depanneur:
        return 'Dépanneur';
    }
  }

  /// Fetch shuttle info: walk, wait, shuttle, walk + next buses
  Future<void> _fetchShuttleInfo() async {
    final origin = _routeOrigin ?? _currentLocation;
    final destinationLatLng = _routeDestination;

    if (origin == null || destinationLatLng == null) {
      setState(() => _routeDurations['shuttle'] = '–');
      return;
    }

    final originStop = ConcordiaShuttleService.nearestStop(origin);
    final destinationStop = ConcordiaShuttleService.nearestStop(
      destinationLatLng,
    );

    // Compute direct walking route
    DirectionsRouteResult? directWalkRoute;
    try {
      directWalkRoute = await GoogleDirectionsService.instance.getRouteDetails(
        origin: origin,
        destination: destinationLatLng,
        mode: 'walking',
      );

      // If same campus, show walking route only
      if (originStop == destinationStop) {
        _handleWalkingRoute(directWalkRoute);
        return;
      }
    } catch (e) {
      print('[ERROR] Failed to compute direct walking route: $e');
    }

    try {
      final nearestStop = originStop;
      final stopLatLng = ConcordiaShuttleService.stopLocation(nearestStop);

      // Compute walk to shuttle, walk from & shuttle route
      final shuttleDestinationStop = nearestStop == 'SGW'
          ? shuttleStopLoyola
          : shuttleStopSGW;
      final shuttleStart = nearestStop == 'SGW'
          ? shuttleStopSGW
          : shuttleStopLoyola;
      final shuttleEnd = nearestStop == 'SGW'
          ? shuttleStopLoyola
          : shuttleStopSGW;

      final results = await Future.wait([
        GoogleDirectionsService.instance.getRouteDetails(
          origin: origin,
          destination: stopLatLng,
          mode: 'walking',
        ), // walkTo
        GoogleDirectionsService.instance.getRouteDetails(
          origin: shuttleDestinationStop,
          destination: destinationLatLng,
          mode: 'walking',
        ), // walkFrom
        GoogleDirectionsService.instance.getRouteDetails(
          origin: shuttleStart,
          destination: shuttleEnd,
          mode: 'driving',
        ), // shuttle
      ]);

      final walkToShuttleRoute = results[0];
      final walkFromShuttleRoute = results[1];
      final shuttleDrivingRoute = results[2];

      // Fetch shuttle data
      final routeData = await ShuttleRouteService.fetchShuttleRouteData(
        nearestStop: nearestStop,
        stopLatLng: stopLatLng,
        walkToShuttleRoute: walkToShuttleRoute,
        walkFromShuttleRoute: walkFromShuttleRoute,
        shuttleDrivingRoute: shuttleDrivingRoute,
        directWalkRoute: directWalkRoute,
      );

      // Walking faster than shuttle
      if (routeData == null) {
        if (directWalkRoute != null) _handleWalkingRoute(directWalkRoute);
        return;
      }

      //  Display shuttle route polylines
      await _buildAndDisplayShuttlePolylines(
        routeData: routeData,
        nearestStop: nearestStop,
      );

      // Update shuttle UI
      _updateShuttleUI(routeData);
    } catch (e) {
      print('[ERROR] Error fetching shuttle info: $e');
      if (!mounted) return;
      setState(() => _routeDurations['shuttle'] = '–');
    }
  }

  // walking route only
  void _handleWalkingRoute(
    DirectionsRouteResult? walkRoute, {
    String label = 'walking',
  }) {
    setState(() {
      _shuttleRouteData = null;
      _shuttleNextBuses = [];
      _shuttleWalkingToDestinationMinutes = null;
      _shuttleWalkingFromDestinationMinutes = null;
      _shuttleTotalTripDuration = null;

      _routeDurations['shuttle'] = walkRoute?.durationText ?? label;

      // Show walking polyline
      _routePolylines = {
        Polyline(
          polylineId: const PolylineId('walking_route'),
          points: walkRoute?.points ?? [],
          color: _highContrastMode
              ? AppUiColors.highContrastRoutePreview
              : const Color(0xFF76263D),
          width: 5,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      };
    });

    // Animate camera to walking route
    if (_mapController != null && (walkRoute?.points ?? []).isNotEmpty) {
      final bounds = geo.calculateBounds(walkRoute!.points);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  // build & display shuttle poyline
  Future<void> _buildAndDisplayShuttlePolylines({
    required ShuttleRouteData routeData,
    required String nearestStop,
  }) async {
    if (_selectedTravelMode != RouteTravelMode.shuttle) return;

    if (_noShuttlePoints(routeData)) {
      setState(() => _routePolylines = {});
      return;
    }

    final opacity = routeData.isInService ? 1.0 : 0.4;
    final polylines = <Polyline>{};

    // Helper to add a polyline
    void addPolyline(
      String id,
      List<LatLng> points, {
      Color? color,
      bool geodesic = false,
      List<PatternItem>? patterns,
    }) {
      if (points.isEmpty) return;
      polylines.add(
        Polyline(
          polylineId: PolylineId(id),
          points: points,
          color:
              color ??
              const Color(0xFF76263D).withAlpha((opacity * 255).round()),
          width: 5,
          geodesic: geodesic,
          patterns: patterns ?? [],
        ),
      );
    }

    final defaultColor = const Color(
      0xFF76263D,
    ).withAlpha((opacity * 255).round());
    final shuttleColor = const Color(
      0xFF9C27B0,
    ).withAlpha((opacity * 255).round());
    const highContrastColor = AppUiColors.highContrastRoutePreview;

    addPolyline(
      'shuttle_walk',
      routeData.walkToShuttlePoints,
      color: _highContrastMode ? highContrastColor : defaultColor,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
    );

    addPolyline(
      'shuttle_route',
      routeData.shuttleRoutePoints,
      color: shuttleColor,
      geodesic: true,
    );

    addPolyline(
      'shuttle_walk_from',
      routeData.walkFromShuttlePoints,
      color: _highContrastMode ? highContrastColor : defaultColor,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
    );

    setState(() => _routePolylines = polylines);

    _updateCameraBounds(routeData, nearestStop);
  }

  /// Checks if there are no shuttle or walk points
  bool _noShuttlePoints(ShuttleRouteData routeData) =>
      routeData.walkToShuttlePoints.isEmpty &&
      routeData.shuttleRoutePoints.isEmpty;

  /// Animates camera to fit all relevant points
  void _updateCameraBounds(ShuttleRouteData routeData, String nearestStop) {
    if (_mapController == null) return;

    final allPoints = [
      ...routeData.walkToShuttlePoints,
      routeData.stopLatLng,
      ...routeData.shuttleRoutePoints,
      nearestStop == 'SGW' ? shuttleStopLoyola : shuttleStopSGW,
      ...routeData.walkFromShuttlePoints,
    ];

    if (allPoints.isEmpty) return;

    final bounds = geo.calculateBounds(allPoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  //update shuttle info in route details UI
  void _updateShuttleUI(ShuttleRouteData routeData) {
    if (!mounted) return;
    setState(() {
      _shuttleNearestStop = routeData.nearestStop;
      _shuttleNextBuses = routeData.buses.map((b) => b.statusLabel).toList();
      _routeDurations['shuttle'] = routeData.isInService
          ? routeData.shuttleDurationLabel
          : 'No service';
      _shuttleWalkingToDestinationMinutes = routeData.walkingToShuttleMinutes;
      _shuttleWalkingFromDestinationMinutes =
          routeData.walkingFromShuttleMinutes;
      _shuttleTotalTripDuration = routeData.totalTripDuration;
      _shuttleRouteData = routeData;
    });
  }

  /// Open full day schedule
  void _showShuttleScheduleModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShuttleScheduleSheet(
        nearestStop: _shuttleNearestStop,
        highContrastMode: _highContrastMode,
      ),
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
    if (_selectedBuildingPoly == null && _selectedPoi == null) return;

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
          backgroundColor: AppUiColors.primary(
            highContrastEnabled: _highContrastMode,
          ),
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
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
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
          backgroundColor: AppUiColors.primary(
            highContrastEnabled: _highContrastMode,
          ),
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
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
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
    const selectedBlue = Color(0xFF7F83C3);
    const highContrastBuildingBase = Color(0xFF365C60);
    const highContrastCurrent = Color(0xFF365C60);
    const burgundy = Color(0xFF800020);

    final polys = <Polygon>{};

    for (final b in buildingPolygons) {
      final isCurrent = _currentBuildingPoly?.code == b.code;
      final isSelected = _selectedBuildingPoly?.code == b.code;

      late final Color strokeColor;
      late final Color fillColor;
      late final int strokeWidth;
      late final int zIndex;

      if (isSelected) {
        strokeColor = _highContrastMode
            ? AppUiColors.highContrastBuildingHighlight.withValues(alpha: 0.95)
            : selectedBlue.withValues(alpha: 0.95);
        fillColor = _highContrastMode
            ? AppUiColors.highContrastBuildingHighlight.withValues(alpha: 0.32)
            : selectedBlue.withValues(alpha: 0.25);
        strokeWidth = 3;
        zIndex = 3;
      } else if (isCurrent) {
        strokeColor = _highContrastMode
            ? highContrastCurrent.withValues(alpha: 0.9)
            : Colors.blue.withValues(alpha: 0.8);
        fillColor = _highContrastMode
            ? highContrastCurrent.withValues(alpha: 0.28)
            : Colors.blue.withValues(alpha: 0.25);
        strokeWidth = 3;
        zIndex = 2;
      } else {
        strokeColor = _highContrastMode
            ? highContrastBuildingBase.withValues(alpha: 0.8)
            : burgundy.withValues(alpha: 0.55);
        fillColor = _highContrastMode
            ? highContrastBuildingBase.withValues(alpha: 0.22)
            : burgundy.withValues(alpha: 0.22);
        strokeWidth = 2;
        zIndex = 1;
      }

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
    _indoorRouteService =
        widget.debugIndoorRouteService ?? IndoorRouteService();
    _indoorController =
        widget.debugIndoorMapController ?? IndoorMapController();

    _highContrastMode = AppSettingsController.state.highContrastModeEnabled;
    _wheelchairRoutingDefaultEnabled =
        AppSettingsController.state.wheelchairRoutingDefaultEnabled;
    if (_wheelchairRoutingDefaultEnabled) {
      _preferredIndoorTransitionMode = IndoorTransitionMode.elevator;
    }

    unawaited(initBuildingLabelIcons());

    AppSettingsController.notifier.addListener(_onAppSettingsChanged);
    _indoorNavigationController.addListener(_onIndoorNavigationChanged);
    SavedDirectionsController.notifier.addListener(_onSavedDirectionsRequested);

    _selectedCampus = widget.initialCampus;

    if (widget.debugDisableMap && widget.debugSelectedBuilding != null) {
      _selectedBuildingPoly = widget.debugSelectedBuilding;
      _selectedBuildingCenter = geo.polygonCenter(
        widget.debugSelectedBuilding!.points,
      );
      _anchorOffset = widget.debugAnchorOffset;
    }

    _lastCameraTarget = widget.initialCampus == Campus.loyola
        ? concordiaLoyola
        : concordiaSGW;
    _createBlueDotIcon();

    if (!widget.debugDisableLocation) {
      _createShuttleStopIcon();
      _bootstrapLocationState();
      _initPois();
    }

    _searchController.addListener(_onSearchChanged);
    _destinationRoomController.addListener(_onDestinationRoomTextChanged);

    _onSavedDirectionsRequested();
  }

  Future<void> _bootstrapLocationState() async {
    await _determineUserLocationAndBuilding();
    if (!mounted) return;
    await _startLocationUpdates();
  }

  Future<void> _determineUserLocationAndBuilding() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      final buildingAtLocation = _findBuildingAtLocation(currentLocation);

      if (!mounted) return;
      setState(() {
        _currentLocation = currentLocation;
        _currentCampus = detectCampus(currentLocation);
        _currentBuildingPoly = detectBuildingPoly(currentLocation);
        _currentBuildingCode = buildingAtLocation?.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentBuildingCode = null;
      });
    }
  }

  BuildingPolygon? _findBuildingAtLocation(LatLng location) {
    for (final building in buildingPolygons) {
      if (_isPointInPolygon(location, building.points)) {
        return building;
      }
    }
    return null;
  }

  BuildingPolygon? _findBuildingByCode(String code) {
    for (final building in buildingPolygons) {
      if (building.code.toUpperCase() == code.toUpperCase()) {
        return building;
      }
    }
    return null;
  }

  void _onDestinationRoomTextChanged() {
    if (_destinationRoomMarker == null && _originRoomMarker == null) return;

    setState(() {
      _originRoomMarker = null;
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

    addBuildingLabelMarkers(markers);
    _addPoiMarkers(markers);
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

    if (_showIndoor) {
      markers.addAll(_amenityMarkers);
      if (_originRoomMarker != null) {
        markers.add(_originRoomMarker!);
      }
      if (_destinationRoomMarker != null) {
        markers.add(_destinationRoomMarker!);
      }
    }

    if (_showRoutePreview && !_isBuildingIndoorRoute) {
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
        fillColor: Colors.blue.withValues(alpha: 0.1),
        strokeColor: Colors.blue.withValues(alpha: 0.3),
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
              strokeColor: AppUiColors.primary(
                highContrastEnabled: _highContrastMode,
              ),
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

  bool get _canGoToPreviousNavStep {
    final key = _navModeKey;
    if (key == null) return false;
    final steps = _routeStepsByMode[key] ?? const [];
    if (steps.isEmpty) return false;
    return _navStepIndex > 0;
  }

  bool get _canGoToNextNavStep {
    final key = _navModeKey;
    if (key == null) return false;
    final steps = _routeStepsByMode[key] ?? const [];
    if (steps.isEmpty) return false;
    return _navStepIndex < steps.length - 1;
  }

  String? get _navProgressLabel {
    final key = _navModeKey;
    if (key == null) return null;
    final steps = _routeStepsByMode[key] ?? const [];
    if (steps.isEmpty) return null;
    return '${_navStepIndex + 1}/${steps.length}';
  }

  void _goToPreviousNavStep() {
    if (!_canGoToPreviousNavStep) {
      return;
    }
    setState(() {
      _navStepIndex -= 1;
    });
  }

  void _goToNextNavStep() {
    if (!_canGoToNextNavStep) {
      return;
    }
    final key = _navModeKey;
    if (key == null) {
      return;
    }
    final steps = _routeStepsByMode[key] ?? const [];
    final nextIndex = _navStepIndex + 1;
    final reachedFinalStep = steps.isNotEmpty && nextIndex >= steps.length - 1;
    setState(() {
      _navStepIndex = nextIndex;
    });
    if (reachedFinalStep) {
      unawaited(_maybeAutoSwitchToDestinationIndoorMap());
    }
  }

  /// Switches to indoor navigation for the origin building when the origin
  /// room is on a non-default floor (e.g., MB S2). The user navigates from
  /// their origin room to the nearest transition (stair/elevator/escalator)
  /// on the entry floor, then proceeds outdoors.
  Future<void> _maybeAutoSwitchToOriginIndoorMap() async {
    final originRoom = _pendingOriginIndoorRoom;
    if (originRoom == null) return;

    final building = _findBuildingByCode(originRoom.buildingCode);
    final floors = _indoorController.floorsForBuilding(originRoom.buildingCode);

    if (!mounted) return;
    if (building == null || floors.isEmpty) {
      // Can't show origin building indoor — skip straight to outdoor nav.
      setState(() {
        _pendingOriginIndoorRoom = null;
      });
      return;
    }

    final entryFloor = floors.first;

    // Find the exit transition room on the entry floor closest to the origin room.
    final exitRoomCode = await _resolveEntryRoomForIndoorHandoff(
      buildingCode: originRoom.buildingCode,
      entryFloorAssetPath: entryFloor.assetPath,
      transitionMode: _effectiveIndoorTransitionMode,
      destinationCenter: originRoom.center,
    );

    if (!mounted) return;
    if (exitRoomCode == null || exitRoomCode.trim().isEmpty) {
      setState(() {
        _pendingOriginIndoorRoom = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to find exit route from origin building. Starting outdoor navigation.',
            ),
          ),
        );
        // Resume outdoor navigation.
        setState(() {
          _isNavigating = true;
        });
      }
      return;
    }

    setState(() {
      _isNavigating = false;
      _navigationFollowUser = false;
      _showRoutePreview = false;

      _selectedBuildingPoly = building;
      _selectedBuildingCenter = geo.polygonCenter(building.points);
      _anchorOffset = null;
      _cameraMoving = false;
      _currentBuildingCode = building.code;

      _indoorFloors = floors;
      _originRoomController.text = originRoom.roomCode;
      _destinationRoomController.text = exitRoomCode;
      _originRoomMarker = null;
      _destinationRoomMarker = null;
      _isBuildingIndoorRoute = false;

      _isOriginIndoorHandoffPhase = true;
      _pendingOriginIndoorRoom = null;
    });

    // Start on the origin room's floor so the user sees their starting point.
    await _loadIndoorFloor(originRoom.floorAssetPath);

    if (!mounted) return;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: originRoom.center,
          zoom: 19,
          tilt: _defaultTilt,
          bearing: _defaultBearing,
        ),
      ),
    );

    final originFloorOption = IndoorFloorConfig.optionForAssetPath(
      originRoom.buildingCode,
      originRoom.floorAssetPath,
    );
    final needsFloorSwitch =
        originFloorOption != null &&
        originFloorOption.assetPath != entryFloor.assetPath;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsFloorSwitch
              ? 'Navigate from ${originRoom.roomCode} to the ${_preferredIndoorTransitionModeLabel() ?? 'exit'} on floor ${entryFloor.label}, then continue outdoors.'
              : 'Navigate to the building exit, then continue outdoors.',
        ),
      ),
    );

    await _maybeStartIndoorNavigationFromRooms();
  }

  /// Called when the user finishes the origin-building indoor phase and is
  /// ready to begin (or bypass) the outdoor leg toward the destination.
  Future<void> _completeOriginIndoorPhaseAndStartOutdoor() async {
    if (!_isOriginIndoorHandoffPhase) {
      return;
    }

    _indoorNavigationController.stop();

    if (!mounted) return;

    final key = _navModeKey;
    final steps = key != null ? (_routeStepsByMode[key] ?? const []) : const [];

    setState(() {
      _isOriginIndoorHandoffPhase = false;
      _isNavigating = true;
      _navStepIndex = 0;
      _navigationFollowUser = true;
      _lastNavCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      // Clear indoor display state.
      _showIndoor = false;
      _indoorFloors = const [];
      _selectedIndoorFloorAsset = null;
      _indoorPolygons = {};
      _indoorGeoJson = null;
      _roomLabelMarkers = {};
      _amenityMarkers = {};
      _originRoomMarker = null;
      _destinationRoomMarker = null;
      _isBuildingIndoorRoute = false;
    });

    _applySelectedModeRoute(animateCamera: false);

    // If there is no outdoor leg at all, skip straight to
    // destination building indoor navigation if a handoff is pending.
    if (_autoHandoffToIndoorPending && steps.isEmpty) {
      await _maybeAutoSwitchToDestinationIndoorMap();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Now navigate outdoors to the destination building.'),
      ),
    );

    if (_currentLocation != null && _mapController != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: _navZoom,
              tilt: _navTilt,
              bearing: 0.0,
            ),
          ),
        );
      } catch (e) {
        // ignore camera animation failures
      }
    }
  }

  Future<void> _maybeAutoSwitchToDestinationIndoorMap() async {
    if (!_autoHandoffToIndoorPending) {
      return;
    }

    final destinationRoom = _pendingDestinationIndoorRoom;
    if (destinationRoom == null) {
      _clearPendingDestinationIndoorHandoff();
      return;
    }

    final building = _findBuildingByCode(destinationRoom.buildingCode);
    final floors = _indoorController.floorsForBuilding(
      destinationRoom.buildingCode,
    );

    if (!mounted) return;
    if (building == null || floors.isEmpty) {
      _clearPendingDestinationIndoorHandoff();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Indoor maps are not available for the destination building.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isNavigating = false;
      _navModeKey = null;
      _navStepIndex = 0;
      _navigationFollowUser = false;

      _showRoutePreview = false;
      _routePolylines = {};
      _routeOriginSuggestions = [];
      _routeDestinationSuggestions = [];
      _routeDurations.clear();
      _routeDistances.clear();
      _routeArrivalTimes.clear();
      _routePointsByMode.clear();
      _routeSegmentsByMode.clear();
      _routeStepsByMode.clear();

      _selectedBuildingPoly = building;
      _selectedBuildingCenter = geo.polygonCenter(building.points);
      _anchorOffset = null;
      _cameraMoving = false;
      _currentBuildingCode = building.code;

      _indoorFloors = floors;
      _originRoomController.clear();
      _destinationRoomController.text = destinationRoom.roomCode;
      _originRoomMarker = null;
      _destinationRoomMarker = null;
      _isBuildingIndoorRoute = false;
    });

    final destinationFloorOption = IndoorFloorConfig.optionForAssetPath(
      destinationRoom.buildingCode,
      destinationRoom.floorAssetPath,
    );
    final entryFloorOption = floors.first;
    final targetAsset = entryFloorOption.assetPath;

    final entryRoomCode = await _resolveEntryRoomForIndoorHandoff(
      buildingCode: destinationRoom.buildingCode,
      entryFloorAssetPath: targetAsset,
      transitionMode: _effectiveIndoorTransitionMode,
      destinationCenter: destinationRoom.center,
    );

    if (entryRoomCode == null || entryRoomCode.trim().isEmpty) {
      _clearPendingDestinationIndoorHandoff();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start indoor navigation automatically from the destination building entry floor.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _originRoomController.text = entryRoomCode;
    });

    await _loadIndoorFloor(targetAsset);

    _clearPendingDestinationIndoorHandoff();

    if (!mounted) return;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: destinationRoom.center,
          zoom: 19,
          tilt: _defaultTilt,
          bearing: _defaultBearing,
        ),
      ),
    );
    final destinationFloorLabel =
        destinationFloorOption?.label ?? destinationRoom.floorLabel;
    final needsFloorSwitch =
        destinationFloorLabel.trim().toUpperCase() !=
        entryFloorOption.label.trim().toUpperCase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          needsFloorSwitch
              ? 'Indoor navigation started from floor ${entryFloorOption.label}. Follow the ${_effectiveIndoorTransitionMode == null ? 'selected' : _preferredIndoorTransitionModeLabel() ?? 'selected'} transition to floor $destinationFloorLabel for room ${destinationRoom.roomCode}.'
              : 'Indoor navigation started on floor ${entryFloorOption.label}. Continue to room ${destinationRoom.roomCode}.',
        ),
      ),
    );

    await _maybeStartIndoorNavigationFromRooms();
  }

  String? _transitionTypeForMode(IndoorTransitionMode? mode) {
    return switch (mode) {
      IndoorTransitionMode.stairs => 'stairs',
      IndoorTransitionMode.elevator => 'elevator',
      IndoorTransitionMode.escalator => 'escalator',
      null => null,
    };
  }

  Future<String?> _resolveEntryRoomForIndoorHandoff({
    required String buildingCode,
    required String entryFloorAssetPath,
    required IndoorTransitionMode? transitionMode,
    required LatLng destinationCenter,
  }) async {
    final floorGeoJson = await _indoorRouteService.indoorRepository
        .loadGeoJsonAsset(entryFloorAssetPath);

    final nodes = _indoorRouteService.sameFloorRouter
        .buildNodesFromFloorGeoJson(floorGeoJson);

    final roomNodes = nodes
        .where((node) => node.nodeType == IndoorRoutingNodeType.room)
        .toList(growable: false);
    if (roomNodes.isEmpty) {
      return null;
    }

    final preferredTransitionType = _transitionTypeForMode(transitionMode);
    final transitionNodes = nodes
        .where((node) => node.isTransition)
        .where(
          (node) =>
              preferredTransitionType == null ||
              node.transitionType == preferredTransitionType,
        )
        .toList(growable: false);

    IndoorRoutingNode? anchorTransition;
    if (transitionNodes.isNotEmpty) {
      anchorTransition = transitionNodes.reduce((best, candidate) {
        final bestDistance = Geolocator.distanceBetween(
          best.center.latitude,
          best.center.longitude,
          destinationCenter.latitude,
          destinationCenter.longitude,
        );
        final candidateDistance = Geolocator.distanceBetween(
          candidate.center.latitude,
          candidate.center.longitude,
          destinationCenter.latitude,
          destinationCenter.longitude,
        );
        return candidateDistance < bestDistance ? candidate : best;
      });
    }

    final anchorPoint = anchorTransition?.center ?? destinationCenter;
    final entryRoom = roomNodes.reduce((best, candidate) {
      final bestDistance = Geolocator.distanceBetween(
        best.center.latitude,
        best.center.longitude,
        anchorPoint.latitude,
        anchorPoint.longitude,
      );
      final candidateDistance = Geolocator.distanceBetween(
        candidate.center.latitude,
        candidate.center.longitude,
        anchorPoint.latitude,
        anchorPoint.longitude,
      );
      return candidateDistance < bestDistance ? candidate : best;
    });

    final roomCode = entryRoom.roomCode;
    if (roomCode == null || roomCode.trim().isEmpty) {
      return null;
    }

    final exists = await _indoorRouteService.indoorRepository.roomExists(
      buildingCode,
      roomCode,
    );
    if (!exists) {
      return null;
    }

    return roomCode;
  }

  void _switchCampus(Campus newCampus) {
    if (_isIndoorNavigationActive) {
      _indoorNavigationController.stop();
    }

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
      _selectedPoi = null;
      _selectedPoiDetails = null;
      _selectedPoiCenter = null;
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
    await _maybeStartIndoorNavigationFromRooms();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = widget.initialCampus == Campus.loyola
        ? concordiaLoyola
        : concordiaSGW;

    final Campus labelCampus = _selectedCampus != Campus.none
        ? _selectedCampus
        : _currentCampus;
    String campusLabel = '';
    if (labelCampus == Campus.sgw) {
      campusLabel = 'SGW';
    } else if (labelCampus == Campus.loyola) {
      campusLabel = 'Loyola';
    }

    String? indoorMapStyle;
    if (_highContrastMode) {
      indoorMapStyle = _highContrastMapStyle;
    } else if (_showIndoor) {
      indoorMapStyle = _indoorMapStyle;
    }

    final selectedBuilding =
        widget.debugSelectedBuilding ?? _selectedBuildingPoly;
    final popupPos = _computePopupPosition(context);

    return Scaffold(
      body: Stack(
        children: [
          if (widget.debugDisableMap)
            const SizedBox.expand()
          else
            // Apply darker map styling in high-contrast mode.
            OutdoorMapView(
              initialTarget: initialTarget,
              showIndoorStyle: _highContrastMode || _showIndoor,
              indoorMapStyle: indoorMapStyle,
              onMapCreated: (c) => _mapController = c,
              onCameraMove: (pos) {
                _lastCameraTarget = pos.target;
                if (_selectedBuildingCenter != null ||
                    _selectedPoiCenter != null) {
                  _schedulePopupUpdate();
                }
              },
              onCameraMoveStarted: () {
                if (_selectedBuildingCenter == null &&
                    _selectedPoiCenter == null) {
                  return;
                }
                setState(() => _cameraMoving = true);
              },
              onCameraIdle: () {
                _syncToggleWithCameraCenter();
                if (_selectedBuildingCenter == null &&
                    _selectedPoiCenter == null) {
                  return;
                }
                setState(() => _cameraMoving = false);
                _updatePopupOffset();
              },
              markers: {..._createMarkers(), ..._roomLabelMarkers},
              circles: _createCircles(),
              polygons: {..._createBuildingPolygons(), ..._indoorPolygons},
              polylines: _routePolylines,
            ),

          if (_isIndoorNavigationActive)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: NavigationNextStepHeader(
                  modeLabel: 'Indoor',
                  nextStep: _currentIndoorStep,
                  highContrastMode: _highContrastMode,
                  onStop: _stopIndoorNavigation,
                  onShowSteps: _openIndoorSteps,
                  onPrevious: _goToPreviousIndoorStep,
                  onNext: _goToNextIndoorStep,
                  canGoPrevious: _indoorNavigationController.canGoPrevious,
                  canGoNext:
                      _indoorNavigationController.canGoNext ||
                      _isOriginIndoorHandoffPhase,
                  progressLabel:
                      '${_indoorNavigationController.currentStepIndex + 1}/${_indoorNavigationController.steps.length}',
                ),
              ),
            ),

          if (_isNavigating && !_isIndoorNavigationActive)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: NavigationNextStepHeader(
                  modeLabel: _selectedTravelMode.label,
                  nextStep: _getCurrentNavStep(),
                  highContrastMode: _highContrastMode,
                  onStop: _stopNavigation,
                  onShowSteps: _openStepsForSelectedMode,
                  onPrevious: _goToPreviousNavStep,
                  onNext: _goToNextNavStep,
                  canGoPrevious: _canGoToPreviousNavStep,
                  canGoNext: _canGoToNextNavStep,
                  progressLabel: _navProgressLabel,
                ),
              ),
            ),

          if (_showRoutePreview && !_isNavigating && !_isIndoorNavigationActive)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: RoutePreviewPanel(
                originText: _routeOriginText,
                destinationText: _routeDestinationText,
                highContrastMode: _highContrastMode,
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
                selectedTransitionMode: _preferredIndoorTransitionMode,
                onTransitionModeChanged: _onIndoorTransitionModeChanged,
                wheelchairRoutingDefaultEnabled:
                    _wheelchairRoutingDefaultEnabled,
                originBuildingCode: _routeOriginBuildingCode,
                destinationBuildingCode: _routeDestinationBuildingCode,
                isConcordiaBuilding: (buildingCode) {
                  return buildingPolygons.any(
                    (b) => b.code.toUpperCase() == buildingCode.toUpperCase(),
                  );
                },
              ),
            ),

          if (_showRoutePreview && !_isIndoorNavigationActive)
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: PointerInterceptor(
                child: Center(
                  child: RouteTravelModeBar(
                    selectedTravelMode: _selectedTravelMode,
                    highContrastMode: _highContrastMode,
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
                    shuttleNextBuses: _shuttleNextBuses,
                    shuttleWalkingFromDestinationMinutes:
                        _shuttleWalkingFromDestinationMinutes,
                    shuttleWalkingToDestinationMinutes:
                        _shuttleWalkingToDestinationMinutes,
                    shuttleNearestStop: _shuttleNearestStop,
                    onViewSchedule: _showShuttleScheduleModal,
                    shuttleRouteData: _shuttleRouteData,
                  ),
                ),
              ),
            ),

          if (!_showRoutePreview &&
              !_isNavigating &&
              !_isIndoorNavigationActive)
            OutdoorTopSearch(
              campusLabel: campusLabel,
              highContrastMode: _highContrastMode,
              controller: _searchController,
              onSubmitted: _onSearchSubmitted,
              suggestions: _searchSuggestions,
              onSuggestionSelected: _onSuggestionSelected,
              onFocus: _hideBuildingPopup,
              originRoomController: _originRoomController,
              destinationRoomController: _destinationRoomController,
              onOriginRoomSubmitted: _onOriginRoomSubmitted,
              onDestinationRoomSubmitted: _onDestinationRoomSubmitted,
              selectedTransitionMode: _preferredIndoorTransitionMode,
              onTransitionModeChanged: _onIndoorTransitionModeChanged,
              wheelchairRoutingDefaultEnabled: _wheelchairRoutingDefaultEnabled,
              selectedBuildingCode: _selectedBuildingPoly?.code,
              currentBuildingCode: _currentBuildingCode,
              userLocation: _currentLocation,
              isConcordiaBuilding: (buildingCode) {
                return buildingPolygons.any(
                  (b) => b.code.toUpperCase() == buildingCode.toUpperCase(),
                );
              },
              showIndoor: _showIndoor,
              floors: _indoorFloors,
              selectedAssetPath: _selectedIndoorFloorAsset,
              onFloorChanged: _onIndoorFloorChanged,
            ),

          if (selectedBuilding != null &&
              popupPos != null &&
              !_showIndoor &&
              !_showRoutePreview &&
              !_isIndoorNavigationActive)
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
              highContrastMode: _highContrastMode,
            ),

          if (!_showRoutePreview && !_isIndoorNavigationActive)
            if (selectedBuilding == null &&
                _selectedPoi != null &&
                popupPos != null)
              Positioned(
                left: popupPos.dx,
                top: popupPos.dy,
                child: PointerInterceptor(
                  child: BuildingInfoPopup(
                    title: _selectedPoiDetails?.name ?? _selectedPoi!.name,
                    description: _poiDescription(_selectedPoi!),
                    accessibility: false,
                    poiCategory: _selectedPoi!.category,
                    facilities: _poiFacilities(),
                    onMore: () => unawaited(_openSelectedPoiLink()),
                    onClose: _closePopup,
                    isLoggedIn: widget.isLoggedIn,
                    onGetDirections: () =>
                        unawaited(_getDirectionsToSelectedPoi()),
                    highContrastMode: _highContrastMode,
                    savedPlace: _selectedPoiSavedPlace(),
                  ),
                ),
              ),

          if (!_showRoutePreview && !_isIndoorNavigationActive)
            OutdoorBottomControls(
              currentLocation: _currentLocation,
              currentCampus: _currentCampus,
              highContrastMode: _highContrastMode,
              onGoToMyLocation: _goToMyLocation,
              onCenterOnUser: () {
                final loc = _currentLocation;
                if (loc == null) return;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(loc, 17),
                );
              },
            ),

          if (!_showRoutePreview && !_isIndoorNavigationActive)
            OutdoorBottomBar(
              showRoutePreview: _showRoutePreview,
              isNavigating: _isNavigating,
              highContrastMode: _highContrastMode,
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

  static const String _highContrastMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        { "color": "#1A1A1A" }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        { "color": "#8A8A8A" }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        { "color": "#111111" }
      ]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [
        { "color": "#161616" }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        { "color": "#2A2A2A" }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        { "color": "#242424" }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        { "color": "#202020" }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        { "color": "#0E1A1F" }
      ]
    },
    {
      "featureType": "poi",
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
    AppSettingsController.notifier.removeListener(_onAppSettingsChanged);
    _indoorNavigationController.removeListener(_onIndoorNavigationChanged);
    _indoorNavigationController.dispose();
    SavedDirectionsController.notifier.removeListener(
      _onSavedDirectionsRequested,
    );
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

  Future<void> initBuildingLabelIcons() async {
    final icons = <String, BitmapDescriptor>{};

    for (final building in buildingPolygons) {
      icons[building.code] = await resolveBuildingLabelIcon(building.code);
    }

    if (!mounted) return;

    setState(() {
      _buildingLabelIcons
        ..clear()
        ..addAll(icons);
      _buildingLabelIconsReady = true;
    });
  }

  Future<BitmapDescriptor> createBuildingLabelIcon(String text) async {
    const double horizontalPadding = 10;
    const double verticalPadding = 6;
    const double borderRadius = 12;
    const double fontSize = 14;

    final backgroundColor = _highContrastMode
        ? const Color(0xFFB8FFF1)
        : const Color(0xFF76263D);

    final borderColor = _highContrastMode ? Colors.black : Colors.white;

    final textColor = _highContrastMode ? Colors.black : Colors.white;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final width = textPainter.width + (horizontalPadding * 2);
    final height = textPainter.height + (verticalPadding * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(borderRadius),
    );

    final fillPaint = Paint()..color = backgroundColor;
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, strokePaint);

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      width.ceil(),
      height.ceil(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  bool shouldShowBuildingLabel(BuildingPolygon building) {
    final buildingCampus = detectCampus(building.center);

    if (_selectedCampus != Campus.none) {
      return buildingCampus == _selectedCampus;
    }

    if (_currentCampus != Campus.none) {
      return buildingCampus == _currentCampus;
    }

    return true;
  }

  void addBuildingLabelMarkers(Set<Marker> markers) {
    if (!_buildingLabelIconsReady) return;
    if (_showIndoor || _showRoutePreview || _isIndoorNavigationActive) return;

    for (final building in buildingPolygons) {
      if (!shouldShowBuildingLabel(building)) continue;

      final icon = _buildingLabelIcons[building.code];
      if (icon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('building_label_${building.code}'),
          position: building.center,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 50,
          consumeTapEvents: true,
          onTap: () => _onBuildingTapped(building),
        ),
      );
    }
  }

  String getBuildingLabel(BuildingPolygon building) {
    return (buildingInfoByCode[building.code]?.name ?? building.name)
        .replaceAll('Building', '')
        .replaceAll('Pavilion', '')
        .trim()
        .toUpperCase();
  }

  Future<BitmapDescriptor> resolveBuildingLabelIcon(String text) {
    final factory = widget.debugBuildingLabelIconFactory;
    if (factory != null) {
      return factory(text);
    }
    return createBuildingLabelIcon(text);
  }
}

class _ShuttleScheduleSheet extends StatelessWidget {
  final String nearestStop;
  final bool highContrastMode;

  const _ShuttleScheduleSheet({
    required this.nearestStop,
    required this.highContrastMode,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppUiColors.primary(highContrastEnabled: highContrastMode);
    final sheetBackground = highContrastMode
        ? AppUiColors.highContrastPrimary
        : Colors.white;
    final titleColor = highContrastMode ? Colors.black : accent;
    final primaryText = highContrastMode ? Colors.black : Colors.black87;
    final secondaryText = highContrastMode ? Colors.black54 : Colors.black54;
    final mutedText = highContrastMode ? Colors.black45 : Colors.black45;
    final nextHighlight = highContrastMode
        ? const Color(0xFF5EBFA7)
        : accent.withValues(alpha: 0.08);
    final nextBorder = highContrastMode
        ? Colors.black26
        : accent.withValues(alpha: 0.3);
    final nextBadgeBg = highContrastMode ? Colors.black : accent;
    final nextBadgeText = highContrastMode
        ? AppUiColors.highContrastPrimary
        : Colors.white;
    final stopChipColor = highContrastMode ? Colors.black : accent;
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
          decoration: BoxDecoration(
            color: sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
                child: Row(
                  children: [
                    Icon(Icons.directions_bus_filled, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Concordia Shuttle Schedule',
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isWeekday
                                ? 'Mon–Fri  ·  Every 30 min  ·  8:00 AM – 10:00 PM'
                                : 'Sat–Sun  ·  Every 15 min  ·  9:00 AM – 6:00 PM',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(Icons.close, color: titleColor),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StopChip(
                        label: 'SGW  (Hall Building)',
                        color: stopChipColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.sync_alt, size: 16, color: mutedText),
                      ),
                      _StopChip(label: 'Loyola', color: stopChipColor),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 1,
                color: highContrastMode ? Colors.black26 : null,
              ),

              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: times.length,
                  itemBuilder: (context, index) {
                    final t = times[index];
                    final now = DateTime.now();
                    final isPast = t.isBefore(now);
                    final isNext =
                        !isPast &&
                        (index == 0 || times[index - 1].isBefore(now));

                    late final Color busIconColor;
                    late final Color busTimeColor;

                    if (isPast) {
                      busIconColor = Colors.black26;
                      busTimeColor = Colors.black26;
                    } else if (isNext) {
                      busIconColor = titleColor;
                      busTimeColor = titleColor;
                    } else {
                      busIconColor = secondaryText;
                      busTimeColor = primaryText;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isNext ? nextHighlight : Colors.transparent,
                        border: isNext ? Border.all(color: nextBorder) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_bus_filled,
                            size: 16,
                            color: busIconColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            ConcordiaShuttleService.formatTime(t),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isNext
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: busTimeColor,
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: nextBadgeBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Next bus',
                                style: TextStyle(
                                  color: nextBadgeText,
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
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
