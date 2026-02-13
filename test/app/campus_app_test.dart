import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/app/campus_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CampusApp Basic Tests', () {
    testWidgets('builds and shows loading initially', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('builds MaterialApp correctly', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
      expect(app.title, 'Campus Guide');
    });

    testWidgets('has correct theme', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, true);
    });
  });

  group('CampusApp Route Tests', () {
    testWidgets('handles root route', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/');
      await tester.pump();
    });

    testWidgets('handles /indoor-map route', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/indoor-map');
      await tester.pump();
    });

    testWidgets('handles /indoor/* with valid ID', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/indoor/MB-1');
      await tester.pump();
    });

    testWidgets('handles /indoor/* with invalid ID', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/indoor/INVALID');
      await tester.pumpAndSettle();

      expect(find.text('Indoor map not found'), findsOneWidget);
    });

    testWidgets('handles /indoor/* with empty ID', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/indoor/');
      await tester.pumpAndSettle();

      expect(find.text('Indoor map not found'), findsOneWidget);
    });

    testWidgets('handles /indoor/* case insensitive', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/indoor/mb-1');
      await tester.pump();
    });

    testWidgets('handles unknown route shows 404', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/unknown');
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
    });

    testWidgets('handles nested unknown route', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      Navigator.of(context).pushNamed('/some/nested/route');
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
    });

    testWidgets('multiple valid indoor routes', (tester) async {
      await tester.pumpWidget(const CampusApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));

      // Test multiple routes
      Navigator.of(context).pushNamed('/indoor/Hall-8');
      await tester.pump();
      Navigator.of(context).pop();
      await tester.pump();

      Navigator.of(context).pushNamed('/indoor/VE-1');
      await tester.pump();
    });
  });
}
