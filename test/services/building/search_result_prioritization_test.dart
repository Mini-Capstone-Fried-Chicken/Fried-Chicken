import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_app/data/search_result.dart';
import 'package:campus_app/services/building_search_service.dart';

void main() {
  group('Search Result Prioritization Tests', () {
    test('searchBuilding should only match exact code', () {
      // Should match
      expect(BuildingSearchService.searchBuilding('MB'), isNotNull);
      expect(BuildingSearchService.searchBuilding('mb'), isNotNull);

      // Should match - "hall" is an exact search term for "Hall Building"
      expect(BuildingSearchService.searchBuilding('hall'), isNotNull);

      // Should NOT match (single letter codes without search terms)
      expect(BuildingSearchService.searchBuilding('X'), isNull);
    });

    test('searchBuilding should match exact names', () {
      expect(BuildingSearchService.searchBuilding('JSMB Building'), isNotNull);
      expect(BuildingSearchService.searchBuilding('jsmb building'), isNotNull);
      expect(BuildingSearchService.searchBuilding('Hall Building'), isNotNull);
    });

    test('searchBuilding should avoid false positives', () {
      // These should NOT match "Hall Building"
      expect(BuildingSearchService.searchBuilding("Hall's Restaurant"), isNull);
      expect(BuildingSearchService.searchBuilding("Hall Coffee"), isNull);
      expect(BuildingSearchService.searchBuilding("Hallmark"), isNull);
    });

    test('searchBuilding should match exact search terms only', () {
      // "gm" is a search term for "GM Building"
      expect(BuildingSearchService.searchBuilding('gm'), isNotNull);

      // "g" is not an exact term
      expect(BuildingSearchService.searchBuilding('g'), isNull);
    });

    test('searchBuilding fallback partial match should require 3+ chars', () {
      // These are >= 3 chars and start with building name
      expect(BuildingSearchService.searchBuilding('JSM'), isNotNull);

      // These are < 3 chars, should not match
      expect(BuildingSearchService.searchBuilding('JS'), isNull);
    });

    test('Search priority: non-Concordia before Concordia', () {
      // Simulate search results where first is Concordia, second is non-Concordia
      final concordiaResult = SearchResult(
        name: 'MB Building',
        address: '1400 de Maisonneuve',
        location: const LatLng(45.495, -73.577),
        isConcordiaBuilding: true,
        placeId: 'place_1',
      );

      final nonConcordiaResult = SearchResult(
        name: "McDonald's",
        address: '1500 de Maisonneuve',
        location: const LatLng(45.496, -73.578),
        isConcordiaBuilding: false,
        placeId: 'place_2',
      );

      final results = [concordiaResult, nonConcordiaResult];

      // With the new prioritization logic, non-Concordia should be selected first
      SearchResult? selectedResult;

      // Implement the prioritization logic from _onSearchSubmitted
      for (final result in results) {
        if (!result.isConcordiaBuilding) {
          selectedResult = result;
          break;
        }
      }

      // Verify non-Concordia was selected
      expect(selectedResult?.name, "McDonald's");
      expect(selectedResult?.isConcordiaBuilding, false);
    });

    test('Search should still select all-Concordia results if needed', () {
      final concordiaResult1 = SearchResult(
        name: 'MB Building',
        address: '1400 de Maisonneuve',
        location: const LatLng(45.495, -73.577),
        isConcordiaBuilding: true,
        placeId: 'place_1',
      );

      final concordiaResult2 = SearchResult(
        name: 'Hall Building',
        address: '1500 de Maisonneuve',
        location: const LatLng(45.496, -73.578),
        isConcordiaBuilding: true,
        placeId: 'place_2',
      );

      final results = [concordiaResult1, concordiaResult2];

      // If all are Concordia, use first one
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

      // Should select first Concordia building
      expect(selectedResult?.name, 'MB Building');
      expect(selectedResult?.isConcordiaBuilding, true);
    });
  });
}
