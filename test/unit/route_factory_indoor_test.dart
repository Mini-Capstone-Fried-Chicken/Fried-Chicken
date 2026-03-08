import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/utils/route_factory_indoor.dart';
import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/indoor/ui/pages/indoor_page.dart';
import 'package:campus_app/app/campus_app.dart';

void main() {
  // Mock asset resolver
  String? mockFindAsset(String id) {
    if (id == "MB-1") return "assets/indoor_svg/MB-1.svg";
    if (id == "CC1") return "assets/indoor_svg/CC1.png";
    return null;
  }

  test('returns SignInPage for root "/"', () {
    final settings = const RouteSettings(name: "/");
    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);
    expect(route, isA<MaterialPageRoute>());
  });

  test('findAssetPath returns value for different case', () {
    // We can access the public method directly through an instance
    final widget = const CampusApp();
    final state = widget.createState() as CampusAppState;

    // Exact case
    expect(state.findAssetPath('MB-1'), 'assets/indoor_svg/MB-1.svg');

    // Lowercase version (tests for... toLowerCase loop)
    expect(state.findAssetPath('mb-1'), 'assets/indoor_svg/MB-1.svg');

    // Non-existent key
    expect(state.findAssetPath('UNKNOWN'), isNull);
  });

  testWidgets('returns IndoorPage for "/indoor-map" when asset exists', (
    WidgetTester tester,
  ) async {
    final settings = const RouteSettings(name: "/indoor-map");
    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => (route as MaterialPageRoute).builder(context),
        ),
      ),
    );
    expect(find.byType(IndoorPage), findsOneWidget);
  });

  testWidgets('returns error page for "/indoor-map" when asset missing', (
    WidgetTester tester,
  ) async {
    final settings = const RouteSettings(name: "/indoor-map");
    String? mockFail(String id) => null; // Always returns null
    final route = RouteFactoryIndoor.createRoute(settings, mockFail);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => (route as MaterialPageRoute).builder(context),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('returns IndoorPage for "/indoor/MB-1"', (
    WidgetTester tester,
  ) async {
    final settings = const RouteSettings(name: "/indoor/MB-1");
    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => (route as MaterialPageRoute).builder(context),
        ),
      ),
    );
    expect(find.byType(IndoorPage), findsOneWidget);
  });

  testWidgets('returns error page for "/indoor/UNKNOWN"', (
    WidgetTester tester,
  ) async {
    final settings = const RouteSettings(name: "/indoor/UNKNOWN");
    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => (route as MaterialPageRoute).builder(context),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets(
    'returns error page for "/indoor/empty" when asset path is empty',
    (WidgetTester tester) async {
      String? mockEmpty(String id) => "";
      final settings = const RouteSettings(name: "/indoor/empty");
      final route = RouteFactoryIndoor.createRoute(settings, mockEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => (route as MaterialPageRoute).builder(context),
          ),
        ),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    },
  );

  testWidgets('returns 404 for unknown route', (WidgetTester tester) async {
    final settings = const RouteSettings(name: "/random");
    final route = RouteFactoryIndoor.createRoute(settings, mockFindAsset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => (route as MaterialPageRoute).builder(context),
        ),
      ),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
