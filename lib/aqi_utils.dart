import 'package:flutter/material.dart';

// Helper class containing US AQI category definitions, colours, and health advice
class AqiUtils {
  // Category Name based on US AQI standard
  static String getCategory(int aqi) {
    if (aqi <= 50) {
      return 'Good';
    } else if (aqi <= 100) {
      return 'Moderate';
    } else if (aqi <= 150) {
      return 'Unhealthy for Sensitive Groups';
    } else if (aqi <= 200) {
      return 'Unhealthy';
    } else if (aqi <= 300) {
      return 'Very Unhealthy';
    } else {
      return 'Hazardous';
    }
  }

  // Dynamic Category Colour
  static Color getCategoryColor(int aqi) {
    if (aqi <= 50) {
      return const Color(0xFF2E7D32); // Green (Good)
    } else if (aqi <= 100) {
      return const Color(0xFFF9A825); // Yellow / Amber (Moderate)
    } else if (aqi <= 150) {
      return const Color(0xFFEF6C00); // Orange (Unhealthy for Sensitive Groups)
    } else if (aqi <= 200) {
      return const Color(0xFFD32F2F); // Red (Unhealthy)
    } else if (aqi <= 300) {
      return const Color(0xFF7B1FA2); // Purple (Very Unhealthy)
    } else {
      return const Color(0xFF7E0023); // Dark Red / Maroon (Hazardous)
    }
  }

  // Short simple health advisory message
  static String getHealthMessage(int aqi) {
    if (aqi <= 50) {
      return 'Air quality is satisfactory and poses little or no health risk.';
    } else if (aqi <= 100) {
      return 'Air quality is acceptable. Sensitive individuals should consider limiting heavy outdoor exertion.';
    } else if (aqi <= 150) {
      return 'Members of sensitive groups may experience health effects. General public is less likely affected.';
    } else if (aqi <= 200) {
      return 'Everyone may begin to experience health effects. Sensitive groups should avoid prolonged outdoor exertion.';
    } else if (aqi <= 300) {
      return 'Health alert: Serious risk of health effects for everyone. Avoid outdoor physical activities.';
    } else {
      return 'Health warning of emergency conditions: Entire population is likely to be severely affected.';
    }
  }

  // List of scale items for the visual AQI legend
  static const List<Map<String, dynamic>> aqiScaleList = [
    {'name': 'Good', 'range': '0-50', 'color': Color(0xFF2E7D32)},
    {'name': 'Moderate', 'range': '51-100', 'color': Color(0xFFF9A825)},
    {'name': 'USG', 'range': '101-150', 'color': Color(0xFFEF6C00)},
    {'name': 'Unhealthy', 'range': '151-200', 'color': Color(0xFFD32F2F)},
    {'name': 'Very Unhealthy', 'range': '201-300', 'color': Color(0xFF7B1FA2)},
    {'name': 'Hazardous', 'range': '301+', 'color': Color(0xFF7E0023)},
  ];
}
