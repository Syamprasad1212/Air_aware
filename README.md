# AirAware

**AirAware** is a lightweight, responsive Flutter mobile application designed to display real-time Air Quality Index (AQI) data with colour-coded categories and pollutant measurements. It connects to open public APIs to empower citizens with environmental awareness.

---

## Problem Statement
> "Develop an air quality index viewer with colour-coded categories from a public AQI API."

---

## SDG Alignment
**SDG 11 — Sustainable Cities and Communities**  
Air pollution is a major environmental health challenge in urban areas. By providing instant, clear, and colour-coded air quality information, **AirAware** enables citizens and community members to make informed daily decisions, minimize health risks, and support sustainable urban living.

---

## Features
- **Real-Time AQI Viewer:** Large, prominent numerical AQI display.
- **Colour-Coded Categories:** Instant visual feedback according to US EPA health categories.
- **City Search:** Search air quality for any global city or town.
- **Autocomplete Suggestions:** Debounced dynamic city suggestions as you type.
- **Use My Location (GPS):** Auto-detects device coordinates with permission handling.
- **Automatic Reverse Geocoding:** Converts GPS coordinates into human-readable city, state, and country names.
- **Supporting Pollutants:** Real-time **PM2.5** and **PM10** concentration readings ($\mu\text{g/m}^3$).
- **Visual AQI Scale Legend:** Clear segmented reference bar showing all AQI ranges.
- **Refresh Capability:** Re-queries the active city or GPS location on demand.
- **Robust Error Handling:** User-friendly loading indicators and error cards with retry options.

---

## Technology Stack
- **Framework:** [Flutter](https://flutter.dev/) (Material 3 UI)
- **Language:** [Dart](https://dart.dev/)
- **Air Quality API:** [Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api) (Free, no API key required)
- **Geocoding API:** [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api)
- **Reverse Geocoding:** [OpenStreetMap Nominatim API](https://nominatim.openstreetmap.org/)
- **Device Location:** `geolocator` package (GPS)
- **Networking:** `http` package with JSON decoding via `dart:convert`

---

## AQI Categories (US EPA Standard)

| AQI Range | Category | Colour | Health Advice |
|---|---|---|---|
| **0 – 50** | Good | Green (`#2E7D32`) | Air quality is satisfactory; little to no health risk. |
| **51 – 100** | Moderate | Yellow (`#F9A825`) | Acceptable quality; sensitive individuals should take care. |
| **101 – 150** | Unhealthy for Sensitive Groups | Orange (`#EF6C00`) | Sensitive groups may experience health effects. |
| **151 – 200** | Unhealthy | Red (`#D32F2F`) | General public may begin to experience health effects. |
| **201 – 300** | Very Unhealthy | Purple (`#7B1FA2`) | Health alert: Serious risk of health effects for everyone. |
| **301 – 500+** | Hazardous | Maroon (`#7E0023`) | Emergency warning: Entire population is likely affected. |

---

## Project Structure

```
lib/
├── main.dart           # App entry point & MaterialApp configuration
├── home_page.dart      # Main single-screen UI & state handling
├── aqi_service.dart    # Networking (Open-Meteo APIs, Nominatim & Geolocator)
├── aqi_model.dart      # AqiModel and LocationSuggestion data models
└── aqi_utils.dart      # US EPA AQI category logic, colours & health messages
```

---

## How to Run

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (version $\ge$ 3.0.0).
- An Android Device (with USB debugging enabled) or Android Emulator.

### Steps
1. **Clone the repository:**
   ```bash
   git clone <REPOSITORY_URL>
   cd air_aware
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the application:**
   ```bash
   flutter run
   ```

---

## Build APK

To generate a release Android APK:
```bash
flutter build apk --release
```
The output file will be generated at:  
`build/app/outputs/flutter-apk/app-release.apk`

---

## SDG 11 Relevance
**AirAware** directly contributes to **Target 11.6** of SDG 11 (reducing the adverse per capita environmental impact of cities, including air quality). By democratizing air quality metrics with intuitive colour codes, the app fosters greater environmental transparency and promotes healthy, resilient communities.
