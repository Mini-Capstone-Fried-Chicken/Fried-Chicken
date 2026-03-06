import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/utils/route_factory_indoor.dart';

void main() {
  String? mockFindAsset(String id) {
    if (id == "MB-1") {
      return "assets/indoor_svg/MB-1.svg";
    }
    return null;
  }

  // test root route
  test('returns SignInPage route for "/"', () {
    final settings = const RouteSettings(name: "/");

    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    expect(route, isA<MaterialPageRoute>());
  });

  // test indoor map route
  test('returns IndoorPage route for /indoor/MB-1', () {
    final settings = const RouteSettings(name: "/indoor/MB-1");

    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    expect(route, isA<MaterialPageRoute>());
  });

  // test invalid buidling
  test('returns error page when asset is not found', () {
    final settings = const RouteSettings(name: "/indoor/UNKNOWN");

    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    expect(route, isA<MaterialPageRoute>());
  });

  // test fallback route
  test('returns 404 page for unknown route', () {
    final settings = const RouteSettings(name: "/random");

    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    expect(route, isA<MaterialPageRoute>());
  });
}
