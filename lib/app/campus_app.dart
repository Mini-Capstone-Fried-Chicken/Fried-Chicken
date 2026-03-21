import "package:campus_app/app/app_shell.dart";
import "package:campus_app/features/auth/ui/login_page.dart";
import "package:campus_app/features/saved/saved_places_controller.dart";
import "package:campus_app/features/settings/app_settings.dart";
//import "package:campus_app/features/indoor/ui/pages/indoor_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:campus_app/utils/route_factory_indoor.dart";
import 'dart:async';

typedef RestoreSettingsCallback = Future<void> Function({bool force});

class CampusApp extends StatefulWidget {
  const CampusApp({super.key});

  @override
  State<CampusApp> createState() => CampusAppState();
}

class CampusAppState extends State<CampusApp> {
  StreamSubscription<User?>? _authStateSub;

  @visibleForTesting
  static Stream<User?> Function()? debugAuthStateChangesProvider;

  @visibleForTesting
  static RestoreSettingsCallback? debugRestoreSettings;

  @visibleForTesting
  static Future<void> Function()? debugReloadSavedPlaces;

  static const Map<String, String> indoorAssetsById = {
    // SVGs
    "MB-1": "assets/indoor_svg/MB-1.svg",
    "MB-S2": "assets/indoor_svg/MB-S2.svg",
    "Hall-8": "assets/indoor_svg/Hall-8.svg",
    "Hall-9": "assets/indoor_svg/Hall-9.svg",
    "VE-1": "assets/indoor_svg/VE-1.svg",
    "VE-2": "assets/indoor_svg/VE-2.svg",
    "VL-1": "assets/indoor_svg/VL-1.svg",
    "VL-2": "assets/indoor_svg/VL-2.svg",
    "h8": "assets/indoor_svg/h8.svg",

    // PNGs
    "CC1": "assets/indoor_svg/CC1.png",
    "Hall-1": "assets/indoor_svg/Hall-1.png",
    "Hall-2": "assets/indoor_svg/Hall-2.png",
    "LB-2": "assets/indoor_svg/LB-2.png",
    "LB-3": "assets/indoor_svg/LB-3.png",
    "LB-4": "assets/indoor_svg/LB-4.png",
    "LB-5": "assets/indoor_svg/LB-5.png",
  };

  String? findAssetPath(String id) {
    final direct = indoorAssetsById[id];
    if (direct != null) return direct;

    final lower = id.toLowerCase();
    for (final entry in indoorAssetsById.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  Stream<User?> _authStateChanges() {
    return debugAuthStateChangesProvider?.call() ??
        FirebaseAuth.instance.authStateChanges();
  }

  void _handleAuthStateChanged(User? _) {
    final restoreSettings = debugRestoreSettings ?? AppSettingsController.restore;
    final reloadSavedPlaces =
        debugReloadSavedPlaces ?? SavedPlacesController.reloadForCurrentUser;
    unawaited(restoreSettings(force: true));
    unawaited(reloadSavedPlaces());
  }

  @override
  void initState() {
    super.initState();
    _authStateSub = _authStateChanges().listen(_handleAuthStateChanged);
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Campus Guide",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF76263D)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ValueListenableBuilder<AppSettingsState>(
          valueListenable: AppSettingsController.notifier,
          builder: (context, settings, _) {
            final mediaQuery = MediaQuery.of(context);
            final baseScale = mediaQuery.textScaler.scale(1.0);
            final multiplier = settings.largeTextModeEnabled ? 1.4 : 1.0;
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(baseScale * multiplier),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },

      // Auth gate
      home: StreamBuilder<User?>(
        stream: _authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user != null) {
            return const AppShell(isLoggedIn: true);
          }
          return const SignInPage();
        },
      ),

      onGenerateRoute: (settings) {
        return RouteFactoryIndoor.createRoute(settings, findAssetPath);
      },
    );
  }
}
