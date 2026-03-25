import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../navigation_steps.dart';
import 'indoor_navigation_session.dart';

class IndoorManualNavigationController extends ChangeNotifier {
  IndoorNavigationSession? _session;
  int _currentStepIndex = 0;
  String? _displayedFloorAssetPath;

  IndoorNavigationSession? get session => _session;
  bool get isActive => _session != null;
  int get currentStepIndex => _currentStepIndex;
  String? get displayedFloorAssetPath => _displayedFloorAssetPath;

  List<NavigationStep> get steps => _session?.steps ?? const [];

  NavigationStep? get currentStep {
    if (_session == null || steps.isEmpty) {
      return null;
    }
    if (_currentStepIndex < 0 || _currentStepIndex >= steps.length) {
      return null;
    }
    return steps[_currentStepIndex];
  }

  bool get canGoNext =>
      _session != null && _currentStepIndex < steps.length - 1;

  bool get canGoPrevious => _session != null && _currentStepIndex > 0;

  Set<Polyline> get currentFloorPolylines {
    final session = _session;
    final assetPath = _displayedFloorAssetPath;
    if (session == null || assetPath == null) {
      return const <Polyline>{};
    }
    return session.polylinesByFloorAsset[assetPath] ?? const <Polyline>{};
  }

  void start(IndoorNavigationSession session) {
    _session = session;
    _currentStepIndex = 0;
    _syncDisplayedFloorWithCurrentStep();
    notifyListeners();
  }

  void stop() {
    _session = null;
    _currentStepIndex = 0;
    _displayedFloorAssetPath = null;
    notifyListeners();
  }

  void nextStep() {
    if (!canGoNext) {
      return;
    }
    _currentStepIndex += 1;
    _syncDisplayedFloorWithCurrentStep();
    notifyListeners();
  }

  void previousStep() {
    if (!canGoPrevious) {
      return;
    }
    _currentStepIndex -= 1;
    _syncDisplayedFloorWithCurrentStep();
    notifyListeners();
  }

  void setDisplayedFloorAssetPath(String assetPath) {
    if (_displayedFloorAssetPath == assetPath) {
      return;
    }
    _displayedFloorAssetPath = assetPath;
    notifyListeners();
  }

  void _syncDisplayedFloorWithCurrentStep() {
    final currentStep = this.currentStep;
    final session = _session;
    if (currentStep?.indoorFloorAssetPath != null) {
      _displayedFloorAssetPath = currentStep!.indoorFloorAssetPath;
      return;
    }
    _displayedFloorAssetPath = session?.initialFloorAssetPath;
  }
}
