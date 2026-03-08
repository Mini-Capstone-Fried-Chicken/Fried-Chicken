import "package:flutter/material.dart";
import "package:campus_app/features/auth/ui/login_page.dart";
import "package:campus_app/features/indoor/ui/pages/indoor_page.dart";

class RouteFactoryIndoor {
  static Route<dynamic> createRoute(
    RouteSettings settings,
    String? Function(String) findAssetPath,
  ) {
    final name = settings.name ?? "/";

    if (name == "/") {
      return MaterialPageRoute(builder: (_) => const SignInPage());
    }

    if (name == "/indoor-map") {
      final assetPath = findAssetPath("MB-1");

      if (assetPath == null) {
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("MB-1 asset not found"))),
        );
      }

      return MaterialPageRoute(
        builder: (_) => IndoorPage(id: "MB-1", assetPath: assetPath),
      );
    }

    if (name.startsWith("/indoor/")) {
      final id = name.replaceFirst("/indoor/", "").trim();
      final assetPath = findAssetPath(id);

      if (assetPath == null || assetPath.isEmpty) {
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Indoor map not found"))),
        );
      }

      return MaterialPageRoute(
        builder: (_) => IndoorPage(id: id, assetPath: assetPath),
      );
    }

    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Center(child: Text("404"))),
    );
  }
}
