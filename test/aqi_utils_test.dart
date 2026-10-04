import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_aware/aqi_utils.dart';
import 'package:air_aware/aqi_model.dart';
import 'package:air_aware/aqi_service.dart';

void main() {
  group('US EPA AQI Boundary Value and Logic Verification', () {
    test('Boundary 0 to 50 -> Good', () {
      expect(AqiUtils.getCategory(0), 'Good');
      expect(AqiUtils.getCategory(50), 'Good');
      expect(AqiUtils.getCategoryColor(50), const Color(0xFF2E7D32));
    });

    test('Boundary 51 to 100 -> Moderate', () {
      expect(AqiUtils.getCategory(51), 'Moderate');
      expect(AqiUtils.getCategory(100), 'Moderate');
      expect(AqiUtils.getCategoryColor(100), const Color(0xFFF9A825));
    });

    test('Boundary 101 to 150 -> Unhealthy for Sensitive Groups', () {
      expect(AqiUtils.getCategory(101), 'Unhealthy for Sensitive Groups');
      expect(AqiUtils.getCategory(150), 'Unhealthy for Sensitive Groups');
      expect(AqiUtils.getCategoryColor(150), const Color(0xFFEF6C00));
    });

    test('Boundary 151 to 200 -> Unhealthy', () {
      expect(AqiUtils.getCategory(151), 'Unhealthy');
      expect(AqiUtils.getCategory(200), 'Unhealthy');
      expect(AqiUtils.getCategoryColor(200), const Color(0xFFD32F2F));
    });

    test('Boundary 201 to 300 -> Very Unhealthy', () {
      expect(AqiUtils.getCategory(201), 'Very Unhealthy');
      expect(AqiUtils.getCategory(300), 'Very Unhealthy');
      expect(AqiUtils.getCategoryColor(300), const Color(0xFF7B1FA2));
    });

    test('Boundary 301+ -> Hazardous', () {
      expect(AqiUtils.getCategory(301), 'Hazardous');
      expect(AqiUtils.getCategory(500), 'Hazardous');
      expect(AqiUtils.getCategoryColor(500), const Color(0xFF7E0023));
    });
  });

  group('Autocomplete LocationSuggestion parsing', () {
    test('LocationSuggestion.fromJson parses correctly with full details', () {
      final json = {
        'name': 'Chennai',
        'latitude': 13.0878,
        'longitude': 80.2785,
        'admin1': 'Tamil Nadu',
        'country': 'India',
      };
      final suggestion = LocationSuggestion.fromJson(json);
      expect(suggestion.name, 'Chennai');
      expect(suggestion.details, 'Tamil Nadu, India');
      expect(suggestion.latitude, 13.0878);
      expect(suggestion.longitude, 80.2785);
    });

    test('LocationSuggestion.fromJson handles missing optional fields gracefully', () {
      final json = {
        'name': 'Singapore',
        'latitude': 1.2897,
        'longitude': 103.8501,
      };
      final suggestion = LocationSuggestion.fromJson(json);
      expect(suggestion.name, 'Singapore');
      expect(suggestion.details, '');
      expect(suggestion.latitude, 1.2897);
    });
  });

  group('Nominatim Reverse Geocoding Address parsing', () {
    test('parseNominatimAddress constructs clean City, State, Country string', () {
      final json = {
        'address': {
          'city': 'Vijayawada',
          'state': 'Andhra Pradesh',
          'country': 'India',
          'postcode': '520001',
        }
      };
      final parsed = AqiService.parseNominatimAddress(json);
      expect(parsed, 'Vijayawada, Andhra Pradesh, India');
    });

    test('parseNominatimAddress falls back to town/village if city is absent', () {
      final json = {
        'address': {
          'town': 'Gannavaram',
          'state': 'Andhra Pradesh',
          'country': 'India',
        }
      };
      final parsed = AqiService.parseNominatimAddress(json);
      expect(parsed, 'Gannavaram, Andhra Pradesh, India');
    });

    test('parseNominatimAddress returns null on missing address', () {
      final json = <String, dynamic>{};
      final parsed = AqiService.parseNominatimAddress(json);
      expect(parsed, isNull);
    });
  });
}
