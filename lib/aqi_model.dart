// Simple data model to hold the Air Quality Index information
class AqiModel {
  final String cityName;
  final String locationDetails;
  final int aqi;
  final double pm25;
  final double pm10;

  AqiModel({
    required this.cityName,
    required this.locationDetails,
    required this.aqi,
    required this.pm25,
    required this.pm10,
  });

  // Factory constructor to parse AQI JSON data from Open-Meteo API
  factory AqiModel.fromJson({
    required String cityName,
    required String locationDetails,
    required Map<String, dynamic> json,
  }) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    
    // Extract US AQI (default to 0 if not available)
    final aqiValue = (current['us_aqi'] as num?)?.toInt() ?? 0;
    
    // Extract PM2.5 and PM10 pollutants
    final pm25Value = (current['pm2_5'] as num?)?.toDouble() ?? 0.0;
    final pm10Value = (current['pm10'] as num?)?.toDouble() ?? 0.0;

    return AqiModel(
      cityName: cityName,
      locationDetails: locationDetails,
      aqi: aqiValue,
      pm25: pm25Value,
      pm10: pm10Value,
    );
  }
}

// Simple model representing a city search autocomplete suggestion
class LocationSuggestion {
  final String name;
  final String details;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.name,
    required this.details,
    required this.latitude,
    required this.longitude,
  });

  // Factory constructor from Open-Meteo Geocoding result item
  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final admin1 = json['admin1']?.toString() ?? '';
    final country = json['country']?.toString() ?? '';
    
    final List<String> parts = [];
    if (admin1.isNotEmpty) parts.add(admin1);
    if (country.isNotEmpty) parts.add(country);

    return LocationSuggestion(
      name: name,
      details: parts.join(', '),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
