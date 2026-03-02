import "package:campus_app/app/app_shell.dart";
import "package:campus_app/features/auth/ui/login_page.dart";
import "package:campus_app/features/indoor/ui/pages/indoor_page.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

class CampusApp extends StatefulWidget {
  const CampusApp({super.key});

  @override
  State<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends State<CampusApp> {
  @override
  void initState() {
    super.initState();
    // Clear any existing Firebase Auth session to always start at login page
    FirebaseAuth.instance.signOut();
  }

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

  String? _findAssetPath(String id) {
    final direct = indoorAssetsById[id];
    if (direct != null) return direct;

    final lower = id.toLowerCase();
    for (final entry in indoorAssetsById.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
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
      home: _buildHome(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Widget _buildHome() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? "/";

    if (name == "/") {
      return _simpleRoute(const SignInPage());
    }

    if (name == "/indoor-map") {
      return _buildIndoorMapRoute("MB-1");
    }

    if (name.startsWith("/indoor/")) {
      final id = name.replaceFirst("/indoor/", "").trim();
      return _buildIndoorMapRoute(id);
    }

    return _simpleRoute(
      const Scaffold(body: Center(child: Text("404"))),
    );
  }

  Route<dynamic> _buildIndoorMapRoute(String id) {
    final assetPath = _findAssetPath(id);

    if (assetPath == null || assetPath.isEmpty) {
      return _simpleRoute(
        const Scaffold(body: Center(child: Text("Indoor map not found"))),
      );
    }

    return _simpleRoute(
      IndoorPage(id: id, assetPath: assetPath),
    );
  }

  Route<dynamic> _simpleRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
