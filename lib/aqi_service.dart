import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'aqi_model.dart';

// Service class handling public API requests, geocoding, and device location
class AqiService {
  // Base URLs for Open-Meteo free APIs
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const String _airQualityBaseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _nominatimReverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // Fetch AQI by city name using Geocoding API + Air Quality API
  Future<AqiModel> fetchAqiByCity(String cityName) async {
    final query = cityName.trim();
    if (query.isEmpty) {
      throw Exception('Please enter a city or location name.');
    }

    try {
      // Step 1: Geocoding - Convert city name to latitude and longitude
      final geocodingUri = Uri.parse(
        '$_geocodingBaseUrl?name=${Uri.encodeComponent(query)}&count=1&language=en&format=json',
      );

      final geoResponse = await http.get(geocodingUri).timeout(
        const Duration(seconds: 10),
      );

      if (geoResponse.statusCode != 200) {
        throw Exception('Failed to connect to Geocoding service (Status: ${geoResponse.statusCode})');
      }

      final geoData = jsonDecode(geoResponse.body) as Map<String, dynamic>;
      final results = geoData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        throw Exception('Location "$query" not found. Please check the spelling.');
      }

      final firstResult = results[0] as Map<String, dynamic>;
      final double lat = (firstResult['latitude'] as num).toDouble();
      final double lon = (firstResult['longitude'] as num).toDouble();
      final String foundCity = firstResult['name']?.toString() ?? query;
      final String admin1 = firstResult['admin1']?.toString() ?? '';
      final String country = firstResult['country']?.toString() ?? '';

      // Build readable location subtitle (e.g. "Andhra Pradesh, India")
      final List<String> detailsParts = [];
      if (admin1.isNotEmpty) detailsParts.add(admin1);
      if (country.isNotEmpty) detailsParts.add(country);
      final String locationDetails = detailsParts.join(', ');

      // Step 2: Fetch Air Quality data using coordinates
      return await _fetchAirQuality(
        lat: lat,
        lon: lon,
        cityName: foundCity,
        locationDetails: locationDetails.isNotEmpty ? locationDetails : '$lat, $lon',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: Unable to fetch air quality data.');
    }
  }

  // Fetch autocomplete suggestions for city search using Open-Meteo Geocoding
  Future<List<LocationSuggestion>> fetchCitySuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return [];
    }

    try {
      final geocodingUri = Uri.parse(
        '$_geocodingBaseUrl?name=${Uri.encodeComponent(trimmed)}&count=5&language=en&format=json',
      );

      final response = await http.get(geocodingUri).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return [];
      }

      return results
          .map((item) => LocationSuggestion.fromJson(item as Map<String, dynamic>))
          .where((s) => s.name.isNotEmpty)
          .toList();
    } catch (_) {
      // Graceful fallback for suggestion network hiccups
      return [];
    }
  }

  // Fetch AQI directly using known coordinates and location labels
  Future<AqiModel> fetchAqiByCoordinates({
    required double latitude,
    required double longitude,
    required String cityName,
    required String locationDetails,
  }) async {
    return await _fetchAirQuality(
      lat: latitude,
      lon: longitude,
      cityName: cityName,
      locationDetails: locationDetails,
    );
  }

  // Reverse geocoding helper using OpenStreetMap Nominatim API
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_nominatimReverseUrl?format=jsonv2&lat=$lat&lon=$lon&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: kIsWeb
            ? {}
            : {
                'User-Agent': 'AirAwareFlutterApp/1.0 (CollegeLabAssignment)',
              },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return parseNominatimAddress(data);
      }
    } catch (_) {
      // Non-blocking fallback
    }
    return null;
  }

  // Pure helper to extract a clean "City, State, Country" string from Nominatim JSON
  static String? parseNominatimAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return null;

    final dynamic cityVal = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['suburb'] ??
        address['county'];

    final dynamic stateVal = address['state'] ?? address['state_district'];
    final dynamic countryVal = address['country'];

    final List<String> parts = [];
    if (cityVal != null && cityVal.toString().trim().isNotEmpty) {
      parts.add(cityVal.toString().trim());
    }
    if (stateVal != null && stateVal.toString().trim().isNotEmpty) {
      parts.add(stateVal.toString().trim());
    }
    if (countryVal != null && countryVal.toString().trim().isNotEmpty) {
      parts.add(countryVal.toString().trim());
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  // Fetch AQI using device GPS location + automatic reverse geocoded human-readable name
  Future<AqiModel> fetchAqiForCurrentLocation() async {
    // Check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS on your device.');
    }

    // Check and request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied. You can search by city name instead.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings or search by city name.');
    }

    try {
      // Get current device position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // Default fallback location subtitle
      String locationSubtitle = 'Lat: ${lat.toStringAsFixed(2)}, Lon: ${lon.toStringAsFixed(2)}';

      // Attempt reverse geocoding to obtain human-readable name
      try {
        final humanReadable = await reverseGeocode(lat, lon);
        if (humanReadable != null && humanReadable.isNotEmpty) {
          locationSubtitle = humanReadable;
        }
      } catch (_) {
        // Non-blocking fallback
      }

      return await _fetchAirQuality(
        lat: lat,
        lon: lon,
        cityName: 'My Current Location',
        locationDetails: locationSubtitle,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to detect device location.');
    }
  }

  // Internal helper to call Open-Meteo Air Quality API
  Future<AqiModel> _fetchAirQuality({
    required double lat,
    required double lon,
    required String cityName,
    required String locationDetails,
  }) async {
    final aqiUri = Uri.parse(
      '$_airQualityBaseUrl?latitude=$lat&longitude=$lon&current=us_aqi,pm10,pm2_5',
    );

    final aqiResponse = await http.get(aqiUri).timeout(
      const Duration(seconds: 10),
    );

    if (aqiResponse.statusCode != 200) {
      throw Exception('Failed to fetch AQI data (Status: ${aqiResponse.statusCode})');
    }

    final aqiData = jsonDecode(aqiResponse.body) as Map<String, dynamic>;

    return AqiModel.fromJson(
      cityName: cityName,
      locationDetails: locationDetails,
      json: aqiData,
    );
  }
}
