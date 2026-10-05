# AirAware — Complete Codebase Learning & Line-by-Line Documentation

> **Purpose of this document:** This is a study guide for understanding the actual AirAware repository, not just a marketing README. It explains the architecture, every important source file, execution flow, state variables, functions, API calls, JSON parsing, location flow, UI construction, AQI categorisation, Android permissions, dependencies, and the reasoning behind the code.

---

## 1. Project in one sentence

**AirAware is a Flutter mobile application that gets a location, converts that location into coordinates when necessary, requests current US AQI + PM2.5 + PM10 data from Open-Meteo, converts the API response into Dart models, and renders the result with AQI-category colours and health advice.**

---

# 2. What happens when the app runs?

The simplest mental model is:

```text
Flutter starts
    ↓
main.dart
    ↓
MaterialApp
    ↓
HomePage
    ↓
initState()
    ↓
Default search = Vijayawada
    ↓
AqiService.fetchAqiByCity()
    ↓
Open-Meteo Geocoding API
    ↓
latitude + longitude
    ↓
Open-Meteo Air Quality API
    ↓
JSON response
    ↓
AqiModel.fromJson()
    ↓
HomePage state is updated
    ↓
AqiUtils interprets AQI
    ↓
UI displays:
  location
  AQI
  category
  health message
  PM2.5
  PM10
  AQI scale
```

There are **three main ways to obtain AQI data**:

```text
1. Search by city
   City name
      ↓
   Geocoding API
      ↓
   coordinates
      ↓
   AQI API

2. Select autocomplete suggestion
   Search text
      ↓
   Geocoding API
      ↓
   selected suggestion already contains coordinates
      ↓
   AQI API directly

3. Use My Location
   GPS
      ↓
   latitude + longitude
      ↓
   reverse geocoding
      ↓
   readable location name
      ↓
   AQI API
```

---

# 3. Repository structure

The important application code is:

```text
lib/
├── main.dart
├── home_page.dart
├── aqi_service.dart
├── aqi_model.dart
└── aqi_utils.dart
```

Android-specific configuration:

```text
android/
├── app/
│   ├── build.gradle.kts
│   └── src/main/AndroidManifest.xml
└── ...
```

Dependency configuration:

```text
pubspec.yaml
```

The five Dart files have very clear responsibilities:

| File | Responsibility |
|---|---|
| `main.dart` | Starts the Flutter application |
| `home_page.dart` | UI + screen state + user interactions |
| `aqi_service.dart` | APIs, GPS and networking |
| `aqi_model.dart` | Converts JSON into Dart objects |
| `aqi_utils.dart` | AQI categories, colours and health advice |

A useful architecture is:

```text
UI Layer
└── home_page.dart

Service / Data Access Layer
└── aqi_service.dart

Model Layer
└── aqi_model.dart

Business / Presentation Rules
└── aqi_utils.dart

Application Entry
└── main.dart
```

---

# 4. Technology stack

- Flutter
- Dart
- Material UI
- `http`
- `geolocator`
- Open-Meteo Geocoding API
- Open-Meteo Air Quality API
- OpenStreetMap Nominatim reverse geocoding
- Android GPS/location permissions
- JSON serialization manually implemented with factory constructors

The project does **not** use a database, Firebase, authentication system, state-management package, or custom backend.

---

# 5. Dependencies

From `pubspec.yaml`:

```yaml
flutter:
  sdk: flutter
cupertino_icons: ^1.0.8
http: ^1.6.0
geolocator: ^14.1.1
```

### `flutter`

The Flutter SDK itself.

### `cupertino_icons`

Provides Cupertino/iOS-style icons. The current main UI mostly uses Material icons.

### `http`

Used for:

```dart
http.get(...)
```

It performs HTTP GET requests to the public APIs.

### `geolocator`

Used for:

- checking whether location services are enabled
- checking permissions
- requesting permissions
- retrieving the device's current coordinates

### `flutter_lints`

Development-only lint rules. It helps identify common Dart/Flutter code-quality issues.

---

# 6. `main.dart` — application entry point

The file is intentionally tiny.

## Conceptual line-by-line explanation

### Import

```dart
import 'package:flutter/material.dart';
```

Imports Flutter's Material Design framework.

This gives access to things such as:

- `MaterialApp`
- `ThemeData`
- `Color`
- `Widget`
- `BuildContext`
- Material icons
- Material components

---

### Home page import

```dart
import 'home_page.dart';
```

Imports the application's main screen.

This separates application startup from screen implementation.

---

### `main()`

```dart
void main() {
  runApp(const AirAwareApp());
}
```

`main()` is the Dart entry point.

`runApp()` tells Flutter:

> Start rendering this widget as the root of the application.

`const AirAwareApp()` creates the root widget.

---

### Root widget

```dart
class AirAwareApp extends StatelessWidget
```

The root application widget is stateless because it does not itself store changing application data.

The changing AQI/search/location state lives inside `HomePage`.

---

### Constructor

```dart
const AirAwareApp({super.key});
```

The widget can be constructed as a compile-time constant when possible.

`super.key` forwards the widget key to Flutter's parent class.

---

### `build()`

```dart
Widget build(BuildContext context)
```

Flutter calls `build()` whenever this widget needs to describe its UI.

---

### `MaterialApp`

The app configures:

- Material 3
- application title
- colour scheme
- `HomePage` as the first screen

The important conceptual relationship is:

```text
AirAwareApp
    ↓
MaterialApp
    ↓
HomePage
```

---

# 7. `aqi_model.dart` — data models

This file contains two models:

```text
AqiModel
LocationSuggestion
```

---

## 7.1 `AqiModel`

```dart
class AqiModel {
```

Represents one AQI result.

It prevents the UI from directly dealing with raw JSON.

---

### Properties

```dart
final String cityName;
final String locationDetails;
final int aqi;
final double pm25;
final double pm10;
```

Each property represents one piece of data.

| Property | Meaning |
|---|---|
| `cityName` | Main location label |
| `locationDetails` | State/country or coordinates |
| `aqi` | Current US AQI |
| `pm25` | PM2.5 concentration |
| `pm10` | PM10 concentration |

They are `final`, meaning once an `AqiModel` object is created, these values cannot be changed.

That is useful because API results are treated as immutable snapshots.

---

## 7.2 Constructor

```dart
AqiModel({
  required this.cityName,
  required this.locationDetails,
  required this.aqi,
  required this.pm25,
  required this.pm10,
});
```

`required` means every field must be supplied.

Example:

```dart
AqiModel(
  cityName: 'Vijayawada',
  locationDetails: 'Andhra Pradesh, India',
  aqi: 73,
  pm25: 18.4,
  pm10: 34.2,
);
```

---

# 8. `AqiModel.fromJson()` — API response conversion

This is one of the most important pieces of the project.

```dart
factory AqiModel.fromJson({
  required String cityName,
  required String locationDetails,
  required Map<String, dynamic> json,
})
```

A `factory` constructor is used because the object is being created from an external representation.

The API gives JSON.

The application wants a Dart object.

So:

```text
JSON
 ↓
fromJson()
 ↓
AqiModel
```

---

## Extracting `current`

```dart
final current = json['current'] as Map<String, dynamic>? ?? {};
```

The Open-Meteo response contains a `current` object.

The `as Map<String, dynamic>?` cast tells Dart to treat it as a map if present.

`?? {}` means:

> If `current` is missing/null, use an empty map.

This prevents a null value from immediately crashing the application.

---

## Extracting AQI

```dart
final aqiValue = (current['us_aqi'] as num?)?.toInt() ?? 0;
```

Important concepts:

- `current['us_aqi']` reads the JSON value.
- `as num?` allows either integer or floating-point numeric JSON.
- `?.toInt()` converts it into an integer if present.
- `?? 0` gives a fallback.

So:

```text
us_aqi exists → convert to int
us_aqi missing → use 0
```

---

## Extracting PM2.5

```dart
final pm25Value =
    (current['pm2_5'] as num?)?.toDouble() ?? 0.0;
```

Same concept, but PM values are represented as `double`.

---

## Extracting PM10

```dart
final pm10Value =
    (current['pm10'] as num?)?.toDouble() ?? 0.0;
```

Again, missing data falls back to `0.0`.

---

## Creating the final model

The parsed values are returned as:

```dart
AqiModel(...)
```

This is the boundary between external JSON and internal application data.

---

# 9. `LocationSuggestion`

This model represents one autocomplete result.

Properties:

```dart
final String name;
final String details;
final double latitude;
final double longitude;
```

Example conceptual object:

```text
name = Vijayawada
details = Andhra Pradesh, India
latitude = 16.5062
longitude = 80.6480
```

The key design decision is that a suggestion stores coordinates.

That means selecting a suggestion does **not** need to geocode the same city again.

Instead:

```text
Suggestion selected
       ↓
coordinates already available
       ↓
AQI API directly
```

---

# 10. `LocationSuggestion.fromJson()`

It extracts:

```text
name
admin1
country
latitude
longitude
```

Then builds:

```text
details = admin1 + country
```

For example:

```text
admin1 = Andhra Pradesh
country = India

details = Andhra Pradesh, India
```

This is displayed under the city name in the suggestion list.

---

# 11. `aqi_utils.dart` — AQI rules

This file contains presentation/business rules.

It does not make network calls.

It answers questions like:

```text
What category is AQI 120?
What colour should AQI 120 use?
What health message should AQI 120 show?
```

---

# 12. `AqiUtils.getCategory()`

The ranges are:

```text
0–50       Good
51–100     Moderate
101–150    Unhealthy for Sensitive Groups
151–200    Unhealthy
201–300    Very Unhealthy
301+       Hazardous
```

The implementation uses an ordered `if / else if` chain.

For example:

```dart
if (aqi <= 50) {
  return 'Good';
}
```

If AQI is 35:

```text
35 <= 50
true
→ Good
```

If AQI is 130:

```text
130 <= 50 → false
130 <= 100 → false
130 <= 150 → true
→ Unhealthy for Sensitive Groups
```

The ordering is important.

---

# 13. `getCategoryColor()`

The same AQI ranges are mapped to colours.

```text
Good                    → green
Moderate                → amber
Unhealthy for Sensitive → orange
Unhealthy               → red
Very Unhealthy          → purple
Hazardous               → dark red/maroon
```

The UI uses the returned colour for:

- AQI number
- category badge
- hero card border
- hero card shadow
- AQI header
- AQI legend selection

This creates a consistent visual language.

---

# 14. `getHealthMessage()`

The same AQI range logic returns a short health advisory.

This is an example of separating content logic from UI code.

Instead of writing:

```dart
if (aqi <= 50) ...
```

inside the widget, the widget simply does:

```dart
final healthMessage = AqiUtils.getHealthMessage(data.aqi);
```

That makes `home_page.dart` easier to read.

---

# 15. `aqiScaleList`

The constant list contains the six AQI categories.

Each item contains:

```text
name
range
color
```

Example concept:

```dart
{
  'name': 'Good',
  'range': '0-50',
  'color': ...
}
```

The UI loops over this list to generate the AQI scale.

This is better than duplicating six separate UI blocks.

---

# 16. `aqi_service.dart` — networking and location layer

This is the data-access layer.

It handles:

```text
Open-Meteo Geocoding
Open-Meteo Air Quality
Open-Meteo autocomplete
Nominatim reverse geocoding
GPS
location permissions
```

---

# 17. Imports in `aqi_service.dart`

```dart
import 'dart:convert';
```

Provides:

```dart
jsonDecode()
```

for converting JSON strings into Dart objects.

---

```dart
import 'package:http/http.dart' as http;
```

Provides HTTP networking.

The alias `http` makes calls explicit:

```dart
http.get(...)
```

---

```dart
import 'package:geolocator/geolocator.dart';
```

Provides:

- GPS position
- permission APIs
- location service checks
- location settings

---

```dart
import 'aqi_model.dart';
```

Allows the service to return:

```dart
AqiModel
```

and:

```dart
LocationSuggestion
```

---

# 18. API base URLs

Three constants are defined.

### Open-Meteo Geocoding

```text
https://geocoding-api.open-meteo.com/v1/search
```

Used to convert a city name into coordinates.

---

### Open-Meteo Air Quality

```text
https://air-quality-api.open-meteo.com/v1/air-quality
```

Used to retrieve current:

```text
US AQI
PM10
PM2.5
```

---

### Nominatim

```text
https://nominatim.openstreetmap.org/reverse
```

Used for:

```text
latitude + longitude
        ↓
human-readable address
```

---

# 19. `fetchAqiByCity()`

This is the standard city-search pipeline.

Signature:

```dart
Future<AqiModel> fetchAqiByCity(String cityName)
```

Because networking takes time, the function returns a `Future`.

Conceptually:

```text
Future<AqiModel>
```

means:

> An `AqiModel` will be available later.

---

## Step 1 — Clean the query

```dart
final query = cityName.trim();
```

Removes unnecessary spaces.

Example:

```text
"  Chennai  "
```

becomes:

```text
"Chennai"
```

---

## Empty query protection

If the query is empty:

```dart
throw Exception(...)
```

The UI catches the exception and displays it to the user.

---

# 20. City → coordinates

The service builds:

```text
/geocoding-api/v1/search
    ?name=...
    &count=1
    &language=en
    &format=json
```

### `Uri.encodeComponent(query)`

This is important.

It safely encodes user input for a URL.

For example, spaces and special characters should not be inserted into a URL raw.

---

## HTTP GET

```dart
final geoResponse = await http.get(...).timeout(
  const Duration(seconds: 10),
);
```

This means:

1. Send HTTP GET.
2. Wait for the response.
3. Stop waiting after 10 seconds.

Without a timeout, a network request could potentially remain pending for too long.

---

# 21. HTTP status handling

```dart
if (geoResponse.statusCode != 200)
```

HTTP 200 means the request succeeded.

Anything else is treated as an error.

The exception includes the status code, making debugging easier.

---

# 22. JSON decoding

```dart
final geoData =
    jsonDecode(geoResponse.body) as Map<String, dynamic>;
```

The HTTP response body is a string.

`jsonDecode()` converts it into Dart structures.

Conceptually:

```text
"{...JSON...}"
      ↓
Map<String, dynamic>
```

---

# 23. Checking search results

```dart
final results = geoData['results'] as List<dynamic>?;
```

Then:

```dart
if (results == null || results.isEmpty)
```

If the API did not find a location, a user-friendly exception is generated.

---

# 24. Extracting coordinates

From the first result:

```dart
final double lat =
    (firstResult['latitude'] as num).toDouble();

final double lon =
    (firstResult['longitude'] as num).toDouble();
```

The coordinates become the input for the Air Quality API.

---

# 25. Why geocoding is required

The AQI API is coordinate-based.

The user thinks in:

```text
"Chennai"
```

The API needs:

```text
13.0827
80.2707
```

So geocoding acts as a translation layer:

```text
Human location name
        ↓
Geocoding
        ↓
latitude + longitude
```

---

# 26. `fetchCitySuggestions()`

This powers autocomplete.

The UI calls it after the user types.

The service:

1. trims the query
2. rejects fewer than 2 characters
3. calls Open-Meteo Geocoding
4. requests up to 5 results
5. converts every result to `LocationSuggestion`
6. filters empty names
7. returns the list

---

# 27. Why the service itself checks two characters

The UI already checks query length, but the service also checks it.

This is defensive programming.

Even if another part of the app calls the service directly, the service will still avoid unnecessary requests.

---

# 28. Autocomplete timeout

Suggestions use:

```text
6 seconds
```

instead of the normal AQI request timeout.

Autocomplete should feel responsive.

If suggestions fail, it simply returns:

```dart
[]
```

instead of breaking the main screen.

---

# 29. `fetchAqiByCoordinates()`

This function is used when coordinates are already known.

That happens when:

- user selects an autocomplete result
- GPS provides coordinates

It directly calls `_fetchAirQuality()`.

This avoids duplicate geocoding.

---

# 30. `reverseGeocode()`

Reverse geocoding converts:

```text
latitude + longitude
```

into:

```text
city + state + country
```

This is mainly useful for the GPS flow.

---

## User-Agent header

The request sends:

```text
AirAwareFlutterApp/1.0 (CollegeLabAssignment)
```

This identifies the application to Nominatim.

---

# 31. `parseNominatimAddress()`

This is a pure parsing helper.

It checks possible city-level fields in this order:

```text
city
town
village
municipality
suburb
county
```

Why multiple fields?

Because different geographic locations may be represented differently by reverse-geocoding services.

Then it checks:

```text
state
state_district
```

and:

```text
country
```

Finally it joins available pieces:

```text
City, State, Country
```

Missing pieces are simply skipped.

---

# 32. GPS flow — `fetchAqiForCurrentLocation()`

This is the most important location function.

The flow is:

```text
Check GPS enabled
      ↓
Check permission
      ↓
Request permission if needed
      ↓
Get position
      ↓
Extract lat/lon
      ↓
Reverse geocode
      ↓
Call AQI API
```

---

## Check location services

```dart
Geolocator.isLocationServiceEnabled()
```

This checks whether GPS/location services are enabled at the device level.

If disabled, the user receives a clear message.

---

## Check permission

```dart
Geolocator.checkPermission()
```

Possible states include:

```text
denied
deniedForever
whileInUse
always
```

The app specifically handles denied and permanently denied states.

---

## Request permission

If permission is initially denied:

```dart
Geolocator.requestPermission()
```

asks the operating system.

If the user denies again, the app does not continue.

---

## Permanently denied

If permission is:

```text
LocationPermission.deniedForever
```

the app tells the user to enable permission in settings.

This avoids trying to request permission repeatedly when Android has permanently blocked it.

---

# 33. Getting the current coordinates

```dart
Geolocator.getCurrentPosition(...)
```

uses:

```text
LocationAccuracy.medium
```

and:

```text
10-second time limit
```

Medium accuracy is a practical compromise for an AQI application because AQI lookup generally does not require extremely precise positioning.

---

# 34. Coordinate fallback

If reverse geocoding fails, the application still has:

```text
Lat: xx.xx, Lon: yy.yy
```

as the location subtitle.

This is an important resilience feature.

The AQI request can still work even when the human-readable address lookup fails.

---

# 35. `_fetchAirQuality()`

This is the central AQI API function.

Every successful path eventually reaches this function.

Inputs:

```text
lat
lon
cityName
locationDetails
```

It builds:

```text
?latitude=...
&longitude=...
&current=us_aqi,pm10,pm2_5
```

The `current` parameter explicitly asks the API for:

- `us_aqi`
- `pm10`
- `pm2_5`

---

# 36. Final API conversion

After the AQI HTTP request:

```dart
final aqiData =
    jsonDecode(aqiResponse.body) as Map<String, dynamic>;
```

Then:

```dart
return AqiModel.fromJson(...)
```

So the service never passes raw JSON to the UI.

That separation is important.

```text
API JSON
   ↓
AqiService
   ↓
AqiModel
   ↓
HomePage
```

---

# 37. Error propagation

The service generally throws exceptions.

The UI catches them.

This creates a clean boundary:

```text
Service:
  "Something went wrong."

UI:
  "How should I display that to the user?"
```

The service does not directly manipulate widgets.

---

# 38. `home_page.dart` — the main application screen

This is the largest file.

It contains:

- screen state
- search input
- autocomplete
- loading UI
- error UI
- GPS button
- AQI card
- pollutant cards
- AQI scale
- refresh logic

---

# 39. Why `StatefulWidget`?

`HomePage` extends:

```dart
StatefulWidget
```

because the screen changes over time.

Examples:

```text
loading → loaded
loading → error
search text changes
suggestions appear
AQI value changes
GPS mode changes
```

A stateless widget would not be appropriate for this mutable screen state.

---

# 40. `HomePage`

```dart
class HomePage extends StatefulWidget
```

Defines the public widget.

Its state is stored separately in:

```dart
_HomePageState
```

The underscore makes the class private to the Dart library.

---

# 41. State variables

The most important state is:

```dart
AqiModel? _aqiData;
```

Nullable because there may initially be no AQI result.

---

```dart
bool _isLoading = false;
```

Controls whether the loading UI is shown.

---

```dart
String? _errorMessage;
```

Nullable because normally there is no error.

---

```dart
bool _isUsingGps = false;
```

Tracks whether the current data source is GPS or city search.

This is important for refresh behavior.

---

```dart
String _currentCityQuery = 'Vijayawada';
```

Stores the city that should be refreshed when the app is not using GPS.

---

# 42. Autocomplete state

```dart
List<LocationSuggestion> _suggestions = [];
```

Contains current search suggestions.

---

```dart
bool _isFetchingSuggestions = false;
```

Controls the small spinner shown inside the search field.

---

```dart
Timer? _debounceTimer;
```

Used to prevent a network request on every keystroke.

---

# 43. `initState()`

`initState()` executes once when the state object is inserted into the widget tree.

The app:

```text
sets search box = Vijayawada
        ↓
fetches Vijayawada AQI
```

So the screen has useful data immediately after startup.

---

# 44. `dispose()`

The timer is cancelled:

```dart
_debounceTimer?.cancel();
```

The text controller is disposed:

```dart
_searchController.dispose();
```

This prevents resources from being unnecessarily retained.

---

# 45. Text controller

```dart
final TextEditingController _searchController
```

Controls the search field.

It allows the code to:

- read current text
- set text programmatically
- clear/update the search box

For example, when an autocomplete suggestion is selected:

```dart
_searchController.text = suggestion.name;
```

---

# 46. Debouncing — one of the most important concepts

When the user types:

```text
C
Ch
Che
Chen
Chenn
Chennai
```

without debouncing, the app could send six network requests.

Instead:

```text
User stops typing
      ↓
wait 350 ms
      ↓
make one request
```

The code:

```dart
_debounceTimer?.cancel();
```

cancels the previous pending timer.

Then:

```dart
Timer(const Duration(milliseconds: 350), ...)
```

starts a new one.

This is called **debouncing**.

---

# 47. Why `mounted` is checked

After an asynchronous request finishes, the widget may have been removed from the screen.

Therefore:

```dart
if (mounted) {
  setState(...)
}
```

prevents calling `setState()` on a disposed widget.

This is a very important Flutter lifecycle concept.

---

# 48. `_fetchAqiForCity()`

This function handles normal city searches.

First it:

```text
cancels debounce
hides keyboard
clears suggestions
sets loading = true
clears old error
sets GPS mode = false
stores current city
```

Then it calls:

```dart
_aqiService.fetchAqiByCity(city)
```

---

# 49. Why old error is cleared

When a new request begins:

```dart
_errorMessage = null;
```

This ensures the old error card disappears while the new request is running.

---

# 50. Success state

When the service returns:

```dart
_aqiData = data;
_isLoading = false;
```

The UI rebuilds.

Because `setState()` is used, Flutter knows the screen needs to be rendered again.

---

# 51. Failure state

If the request throws:

```dart
catch (e)
```

the code stores:

```dart
_errorMessage
```

and sets:

```dart
_isLoading = false
```

The UI then chooses the error view.

---

# 52. `_fetchAqiForSuggestion()`

Autocomplete selection is more efficient than normal city search.

A suggestion already contains:

```text
name
latitude
longitude
details
```

So the app directly calls:

```dart
fetchAqiByCoordinates(...)
```

This avoids:

```text
city → geocode → coordinates
```

because coordinates already exist.

---

# 53. `_fetchAqiForLocation()`

This is the UI wrapper around GPS functionality.

It:

```text
clears suggestions
sets loading
clears error
marks GPS mode
```

Then calls:

```dart
_aqiService.fetchAqiForCurrentLocation()
```

The service handles the actual GPS and permission work.

---

# 54. `_refreshData()`

This method is a key piece of state design.

It checks:

```dart
if (_isUsingGps)
```

If true:

```text
refresh = get current GPS position again
```

Otherwise:

```text
refresh = search the current city again
```

So the refresh button does not blindly reload the initial city.

---

# 55. Main `build()` method

The widget tree is approximately:

```text
Scaffold
└── AppBar
└── SafeArea
    └── SingleChildScrollView
        └── Column
            ├── Search
            ├── Suggestions
            ├── Use My Location
            └── Dynamic content
                ├── Loading
                ├── Error
                └── AQI content
```

This is the central UI structure.

---

# 56. Conditional rendering

The screen uses conditions such as:

```dart
if (_isLoading)
```

and:

```dart
if (!_isLoading && _errorMessage != null)
```

and:

```dart
if (!_isLoading && _errorMessage == null && _aqiData != null)
```

Therefore only the appropriate state is shown.

Conceptually:

```text
LOADING
   ↓
show spinner

ERROR
   ↓
show error card

SUCCESS
   ↓
show AQI content
```

---

# 57. Search UI

`_buildSearchSection()` creates the search box.

It contains:

- search icon
- text field
- suggestion loading spinner
- search/submit button

---

# 58. `onChanged`

Every text change calls:

```dart
_onSearchChanged
```

This starts the debounce process.

---

# 59. `onSubmitted`

Pressing the keyboard's search action triggers:

```dart
_fetchAqiForCity(...)
```

So the user can either:

```text
tap a suggestion
```

or:

```text
submit the typed city
```

---

# 60. Search arrow

The arrow button reads:

```dart
_searchController.text
```

and performs the same city search.

This gives the user three search interaction methods:

```text
autocomplete selection
keyboard submit
arrow button
```

---

# 61. Suggestions list

`_buildSuggestionsList()` renders:

```text
ListView.separated
```

Each suggestion becomes a:

```text
ListTile
```

with:

- city icon
- city name
- state/country
- trailing arrow
- tap handler

---

# 62. Why `shrinkWrap: true`?

The suggestions list is inside a `SingleChildScrollView`.

Using:

```dart
shrinkWrap: true
```

allows the list to take only the space required by its children.

---

# 63. Why `NeverScrollableScrollPhysics()`?

The outer page already scrolls.

Therefore the suggestions list is not given its own independent scrolling behavior.

This avoids nested-scroll conflicts.

---

# 64. Use My Location button

This button calls:

```dart
_fetchAqiForLocation
```

and is disabled while loading:

```dart
_isLoading ? null : ...
```

This reduces accidental duplicate requests.

---

# 65. Loading view

The loading view displays:

```text
CircularProgressIndicator
+
Fetching latest air quality data...
```

It gives immediate feedback during API/GPS operations.

---

# 66. Error view

The error card displays:

- error icon
- error message
- retry button

The retry button calls:

```dart
_refreshData()
```

So retry respects the current source.

---

# 67. `_buildAqiContent()`

This method converts raw model data into display-ready values:

```dart
final category = AqiUtils.getCategory(data.aqi);
final categoryColor = AqiUtils.getCategoryColor(data.aqi);
final healthMessage = AqiUtils.getHealthMessage(data.aqi);
```

Then builds:

```text
Location
AQI hero
Pollutants
AQI scale
Refresh
```

---

# 68. Location card

Displays:

```text
location icon
city name
location details
```

It uses:

```dart
Expanded
```

so long location names do not unnecessarily force the row beyond its available width.

---

# 69. AQI hero card

This is the main visual component.

It uses the AQI category colour dynamically.

For example:

```text
AQI = 42
→ Good
→ green
```

The same category colour appears throughout the card.

---

# 70. AQI number

The AQI number is intentionally large:

```text
64px
```

and uses:

```dart
FontWeight.w900
```

to make the current AQI the visual focal point.

---

# 71. Category badge

The category is converted to uppercase:

```dart
category.toUpperCase()
```

This creates a compact visual label.

---

# 72. Health message

The message comes from:

```dart
AqiUtils.getHealthMessage(data.aqi)
```

The UI itself does not contain AQI decision logic.

That keeps responsibilities separated.

---

# 73. Pollutant section

Two cards are displayed:

```text
PM2.5
PM10
```

Values are formatted to one decimal:

```dart
toStringAsFixed(1)
```

Example:

```text
18.376 → 18.4
```

---

# 74. Pollutant units

The application displays:

```text
µg/m³
```

which means micrograms per cubic metre.

The cards are arranged with:

```text
Expanded
+
Expanded
```

so each receives roughly half the available width.

---

# 75. AQI scale legend

The legend is generated from:

```dart
AqiUtils.aqiScaleList
```

rather than hard-coded UI blocks.

This is a good example of data-driven UI.

---

# 76. Dynamic AQI selection in the legend

The code calculates:

```dart
final currentCategory = AqiUtils.getCategory(currentAqi);
```

Then each legend item checks whether it is the current category.

If selected:

```text
background becomes tinted
border is added
text becomes bold
```

This lets the user visually see where the current AQI sits on the scale.

---

# 77. Special `USG` handling

The legend abbreviates:

```text
Unhealthy for Sensitive Groups
```

as:

```text
USG
```

So the code explicitly handles:

```dart
name == 'USG'
```

and compares it to the full AQI category.

This is necessary because the display label and actual category string are different.

---

# 78. Refresh button

There are two refresh controls:

1. App bar refresh icon
2. Large `Refresh AQI Data` button

Both call:

```dart
_refreshData()
```

The app bar button is disabled while loading.

---

# 79. Complete city-search flow

```text
User types "Chennai"
        ↓
_onSearchChanged()
        ↓
cancel previous debounce
        ↓
wait 350 ms
        ↓
fetchCitySuggestions()
        ↓
Open-Meteo Geocoding
        ↓
LocationSuggestion[]
        ↓
suggestions displayed
        ↓
User selects Chennai
        ↓
_fetchAqiForSuggestion()
        ↓
coordinates already known
        ↓
fetchAqiByCoordinates()
        ↓
_fetchAirQuality()
        ↓
Open-Meteo AQI API
        ↓
AqiModel.fromJson()
        ↓
setState()
        ↓
AQI UI
```

---

# 80. Complete direct city-search flow

If the user types a city and presses search:

```text
"Delhi"
   ↓
_fetchAqiForCity()
   ↓
fetchAqiByCity()
   ↓
Geocoding API
   ↓
Delhi coordinates
   ↓
AQI API
   ↓
AqiModel
   ↓
UI
```

Autocomplete is not required for this path.

---

# 81. Complete GPS flow

```text
Tap Use My Location
        ↓
_fetchAqiForLocation()
        ↓
fetchAqiForCurrentLocation()
        ↓
Check GPS enabled
        ↓
Check permission
        ↓
Request permission if necessary
        ↓
getCurrentPosition()
        ↓
latitude + longitude
        ↓
reverseGeocode()
        ↓
City, State, Country
        ↓
_fetchAirQuality()
        ↓
AQI API
        ↓
AqiModel
        ↓
UI
```

---

# 82. Complete refresh logic

### If current mode is city:

```text
Refresh
 ↓
_isUsingGps == false
 ↓
fetch current city again
```

### If current mode is GPS:

```text
Refresh
 ↓
_isUsingGps == true
 ↓
get current device location again
 ↓
fetch fresh AQI
```

This is why `_isUsingGps` is needed.

---

# 83. API architecture

The application uses three external endpoints.

## API 1 — Open-Meteo Geocoding

Purpose:

```text
city name → coordinates
```

Also used for autocomplete.

---

## API 2 — Open-Meteo Air Quality

Purpose:

```text
coordinates → current air quality
```

Requested values:

```text
US AQI
PM2.5
PM10
```

---

## API 3 — Nominatim

Purpose:

```text
coordinates → human-readable address
```

Used only in GPS mode.

---

# 84. Why two geocoding systems?

The application uses Open-Meteo for forward geocoding:

```text
city → coordinates
```

and Nominatim for reverse geocoding:

```text
coordinates → address
```

This is because they are being used for different directions of geographic conversion.

---

# 85. JSON data flow

The external API gives JSON.

The application transforms it:

```text
HTTP response body
      ↓
jsonDecode()
      ↓
Map<String, dynamic>
      ↓
AqiModel.fromJson()
      ↓
AqiModel
```

This is the core data transformation pipeline.

---

# 86. State machine of the screen

A useful mental model is:

```text
START
  |
  v
LOADING
  |
  +---- success ----> SUCCESS
  |
  +---- failure ----> ERROR
                         |
                         +---- retry ----> LOADING
```

During successful usage:

```text
SUCCESS
  |
  +---- search ----> LOADING
  |
  +---- GPS -------> LOADING
  |
  +---- refresh ---> LOADING
```

---

# 87. Android permissions

`AndroidManifest.xml` declares:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Required for API calls.

---

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Allows precise location access.

---

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

Allows approximate location access.

The `geolocator` package then handles runtime permission requests.

---

# 88. Android application configuration

The Android app label is:

```text
AirAware
```

The launcher icon is:

```text
@mipmap/ic_launcher
```

The main activity is:

```text
.MainActivity
```

and is marked:

```text
exported="true"
```

because it has the launcher intent filter.

---

# 89. Android activity behavior

The activity uses:

```text
singleTop
```

launch mode.

It also enables:

```text
hardwareAccelerated
```

which is useful for Flutter rendering.

`windowSoftInputMode="adjustResize"` helps the UI react when the keyboard opens.

---

# 90. Android Gradle configuration

The project uses Kotlin Gradle DSL:

```text
build.gradle.kts
```

The plugins include:

```text
com.android.application
kotlin-android
dev.flutter.flutter-gradle-plugin
```

Java/Kotlin target:

```text
Java 17
```

The application ID is:

```text
com.airaware.app.air_aware
```

---

# 91. Important architecture decisions

## Decision 1 — Service layer

Networking is not placed inside widgets.

Good:

```text
HomePage
   ↓
AqiService
```

instead of:

```text
HomePage
   ↓
http.get()
```

This makes the code easier to test and maintain.

---

## Decision 2 — Models

Raw JSON is converted into typed models.

Good:

```text
AqiModel
LocationSuggestion
```

instead of passing dynamic JSON everywhere.

---

## Decision 3 — Utility layer

AQI categories are centralised in:

```text
AqiUtils
```

So category logic is not duplicated throughout the UI.

---

## Decision 4 — Debouncing

Autocomplete uses 350 ms debounce to reduce unnecessary API requests.

---

## Decision 5 — Graceful reverse-geocoding failure

If Nominatim fails, the app still uses:

```text
Lat: xx.xx, Lon: yy.yy
```

and continues fetching AQI.

---

# 92. Important Dart concepts used

You should understand these before claiming full understanding of the project:

### `Future<T>`

Used for asynchronous operations.

### `async`

Allows use of `await`.

### `await`

Waits for a future result without blocking the normal asynchronous execution model.

### `factory`

Used to construct models from JSON.

### `final`

Reference cannot be reassigned after initialization.

### `const`

Compile-time constant where possible.

### `?.`

Null-aware access.

### `??`

Fallback when a value is null.

### `as`

Type casting.

### `required`

Named parameter must be provided.

### `List<T>`

Typed collection.

### `Map<String, dynamic>`

Common representation of decoded JSON objects.

### `setState()`

Tells Flutter that state changed and the widget should rebuild.

### `mounted`

Indicates that a `State` object is still attached to the widget tree.

### `dispose()`

Lifecycle cleanup method.

### `Timer`

Used here for debounce.

---

# 93. Important Flutter concepts used

You should understand:

```text
Widget tree
StatefulWidget
StatelessWidget
State
build()
initState()
dispose()
setState()
BuildContext
TextEditingController
Scaffold
SafeArea
SingleChildScrollView
Column
Row
Expanded
Container
Card
ListView
ListTile
TextField
Future
async/await
```

---

# 94. Why `setState()` matters

Example:

```dart
setState(() {
  _isLoading = true;
});
```

The value changes and Flutter rebuilds the affected widget tree.

Without `setState()`, changing a normal state variable would not automatically tell Flutter to update the UI.

---

# 95. Potential interview question: Why StatefulWidget?

**Answer:**

Because the page has changing state such as loading status, AQI data, errors, GPS mode and autocomplete suggestions. `StatefulWidget` allows the UI to rebuild when these values change.

---

# 96. Potential interview question: Why debounce autocomplete?

**Answer:**

Without debouncing, every keystroke could trigger a network request. A 350 ms debounce waits until the user pauses typing, reducing unnecessary API calls and improving responsiveness.

---

# 97. Potential interview question: Why use a service class?

**Answer:**

It separates networking and location logic from UI code. The widget manages presentation/state, while `AqiService` handles external APIs and GPS. This improves maintainability and makes the code easier to test.

---

# 98. Potential interview question: Why use models?

**Answer:**

The APIs return dynamic JSON. Models convert that unstructured response into strongly typed Dart objects such as `AqiModel` and `LocationSuggestion`, making the rest of the application safer and easier to understand.

---

# 99. Potential interview question: Why use coordinates for AQI?

**Answer:**

The Air Quality API accepts latitude and longitude. A city name therefore needs to be geocoded first. When autocomplete or GPS already provides coordinates, the app can skip that extra geocoding step.

---

# 100. Potential interview question: What happens if reverse geocoding fails?

**Answer:**

The app falls back to displaying latitude and longitude. It still proceeds with the AQI request, so reverse geocoding is treated as a helpful enhancement rather than a hard dependency.

---

# 101. Potential interview question: How is error handling implemented?

There are multiple layers:

```text
HTTP status checks
timeouts
try/catch
permission checks
empty-result checks
null fallbacks
UI error state
retry button
```

This makes the app more resilient to network and location failures.

---

# 102. Potential improvement areas

The current project works, but if you want to take it from a student project toward a more production-style architecture, consider:

### 1. Repository pattern

Current:

```text
HomePage → AqiService
```

Possible:

```text
HomePage
   ↓
ViewModel/Controller
   ↓
Repository
   ↓
API clients
```

### 2. Dedicated API response models

More complex APIs could benefit from separate response DTOs.

### 3. State management

For a larger application:

```text
Riverpod
Bloc
Provider
```

could replace manual `setState`.

### 4. Tests

Add tests for:

```text
AqiModel.fromJson()
LocationSuggestion.fromJson()
AqiUtils.getCategory()
AqiUtils.getCategoryColor()
AqiUtils.getHealthMessage()
parseNominatimAddress()
```

### 5. API abstraction

Separate:

```text
Geocoding client
Air quality client
Reverse geocoding client
```

if the application grows.

---

# 103. Testing strategy you should understand

Even though this project is small, the easiest unit-test targets are pure functions.

## AQI category

Test:

```text
0
50
51
100
101
150
151
200
201
300
301
```

These are boundary values.

---

## Nominatim parser

Test JSON containing:

```text
city
state
country
```

Then test:

```text
town
state
country
```

Then:

```text
village
country
```

Then missing fields.

---

## JSON model parser

Test:

```text
complete response
missing current
missing us_aqi
missing pm2_5
missing pm10
```

---

# 104. Boundary-condition reasoning

The AQI ranges use:

```dart
<=
```

Therefore:

```text
50  → Good
51  → Moderate

100 → Moderate
101 → USG

150 → USG
151 → Unhealthy

200 → Unhealthy
201 → Very Unhealthy

300 → Very Unhealthy
301 → Hazardous
```

These exact boundaries are worth remembering.

---

# 105. Full dependency graph

```text
main.dart
   │
   └── home_page.dart
          │
          ├── aqi_model.dart
          │
          ├── aqi_service.dart
          │       │
          │       ├── http
          │       ├── geolocator
          │       └── aqi_model.dart
          │
          └── aqi_utils.dart
```

---

# 106. Data dependency graph

```text
Open-Meteo Geocoding
        │
        └── coordinates
               │
               ▼
      Open-Meteo Air Quality
               │
               ├── US AQI
               ├── PM2.5
               └── PM10
               │
               ▼
          AqiModel
               │
               ▼
           HomePage
               │
               ├── AqiUtils.getCategory()
               ├── AqiUtils.getCategoryColor()
               └── AqiUtils.getHealthMessage()
```

---

# 107. Location dependency graph

```text
GPS
 │
 ├── permission
 │
 ├── current coordinates
 │
 └── Nominatim
       ↓
 human-readable location
       ↓
 Open-Meteo AQI
```

---

# 108. What you should be able to explain without looking at the code

After studying this repository, you should be able to answer:

1. What happens when the application starts?
2. Why is `HomePage` stateful?
3. How does city search work?
4. How does autocomplete work?
5. Why is there a debounce?
6. What does the 350 ms timer do?
7. How does city text become coordinates?
8. How are coordinates sent to the AQI API?
9. Which API provides AQI?
10. Which pollutants are requested?
11. How is JSON converted into a Dart model?
12. Why is `AqiModel` useful?
13. How does GPS permission work?
14. What happens if GPS is disabled?
15. What happens if permission is denied?
16. What happens if permission is permanently denied?
17. How does reverse geocoding work?
18. What happens if reverse geocoding fails?
19. How does refresh know whether to use GPS or city search?
20. How are AQI categories calculated?
21. How are AQI colours selected?
22. How is the health advice selected?
23. How does the AQI legend highlight the current category?
24. Why is `mounted` checked?
25. Why is `dispose()` needed?
26. Why is networking separated from UI?
27. What does `Future<AqiModel>` mean?
28. What does `async/await` do?
29. What are the Android permissions?
30. What happens when the network returns a non-200 status?

---

# 109. Five-minute explanation for an interview

You can explain the project like this:

> AirAware is a Flutter-based air-quality monitoring application. The user can either search for a city, select an autocomplete suggestion, or use the device's current location. For city search, I first use the Open-Meteo Geocoding API to convert the city name into latitude and longitude. Those coordinates are then sent to the Open-Meteo Air Quality API to retrieve the current US AQI, PM2.5 and PM10 values.
>
> I separated the code into a model layer, service layer, utility layer and UI layer. `AqiModel` handles the application data, `AqiService` handles networking, geocoding and GPS, and `AqiUtils` contains AQI categories, colours and health messages.
>
> For autocomplete, I added a 350 millisecond debounce so the application does not make an API request for every keystroke. Selecting a suggestion is also optimized because the suggestion already contains latitude and longitude, so the app can directly call the air-quality API.
>
> For the GPS feature, the application checks whether location services are enabled, handles runtime permissions, gets the current coordinates and uses Nominatim reverse geocoding to show a readable city, state and country. If reverse geocoding fails, the app falls back to displaying the coordinates while still fetching AQI data.
>
> The UI has explicit loading, error and success states, and refresh respects whether the current data came from GPS or a searched city.

---

# 110. The single most important architecture idea

Remember this:

```text
UI does not talk directly to raw JSON.

UI
 ↓
AqiService
 ↓
External APIs
 ↓
JSON
 ↓
AqiModel
 ↓
UI
```

And:

```text
AQI number
 ↓
AqiUtils
 ↓
category + colour + health advice
 ↓
UI
```

If you understand these two pipelines, you understand the core architecture of AirAware.

---

# 111. Source-file responsibility cheat sheet

| File | Think of it as |
|---|---|
| `main.dart` | Start the app |
| `home_page.dart` | What the user sees and does |
| `aqi_service.dart` | How the app gets data |
| `aqi_model.dart` | What the data looks like |
| `aqi_utils.dart` | How AQI values are interpreted |

---

# 112. Final learning order

Do **not** study the files randomly.

Use this order:

```text
1. main.dart
      ↓
2. aqi_model.dart
      ↓
3. aqi_utils.dart
      ↓
4. aqi_service.dart
      ↓
5. home_page.dart
```

Then study the complete flows:

```text
City Search
GPS
Autocomplete
Refresh
Error Handling
```

Finally study:

```text
AndroidManifest
build.gradle.kts
pubspec.yaml
```

This order makes the code much easier to understand.

---

# 113. Final mental model

If you remember only one diagram, remember this:

```text
                         AIR AWARE
                             │
                 ┌───────────┴───────────┐
                 │                       │
             City Search              GPS
                 │                       │
                 ▼                       ▼
          Open-Meteo Geo          Geolocator
                 │                       │
                 ▼                       ▼
          Latitude/Longitude      Latitude/Longitude
                 │                       │
                 │                Nominatim
                 │                       │
                 └───────────┬───────────┘
                             ▼
                  Open-Meteo Air Quality
                             │
                             ▼
                    JSON Response
                             │
                             ▼
                    AqiModel.fromJson
                             │
                             ▼
                         HomePage
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
             AQI          PM2.5           PM10
              │
              ▼
          AqiUtils
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
    Category Color Health
              │
              ▼
             UI
```

---

# 114. Bottom line

AirAware is a relatively small codebase, but it demonstrates several important real-world application concepts:

- Flutter widget architecture
- Stateful UI
- asynchronous programming
- REST API consumption
- JSON parsing
- typed data models
- geocoding
- reverse geocoding
- device GPS
- runtime permissions
- API timeouts
- error handling
- debounced search
- data-driven UI
- conditional rendering
- lifecycle management
- separation of UI and networking logic

The most important thing is not memorising every Flutter widget.

You should understand **why data moves from one layer to another**:

```text
User input
   ↓
HomePage
   ↓
AqiService
   ↓
External API
   ↓
JSON
   ↓
AqiModel
   ↓
AqiUtils
   ↓
HomePage UI
```

Once you can explain that flow and the individual functions inside it, you can genuinely explain how the AirAware application works.


---

# 115. Exact repository source inventory

The uploaded repository contains these primary application files:

| File | Lines |
|---|---:|
| `lib/main.dart` | 28 |
| `lib/aqi_model.dart` | 73 |
| `lib/aqi_utils.dart` | 65 |
| `lib/aqi_service.dart` | 261 |
| `lib/home_page.dart` | 746 |
| `android/app/src/main/AndroidManifest.xml` | 49 |
| `android/app/build.gradle.kts` | 44 |
| `pubspec.yaml` | 91 |

The application logic is therefore concentrated mainly in **five Dart files**. The generated documentation above explains the complete behavior and the purpose of the individual code sections in those files.

## Exact source reading method

For literal line-by-line study, open the corresponding source file beside this README and read it using the following order:

```text
main.dart
  → every import
  → main()
  → AirAwareApp
  → build()

aqi_model.dart
  → AqiModel fields
  → constructor
  → fromJson()
  → LocationSuggestion fields
  → constructor
  → fromJson()

aqi_utils.dart
  → getCategory()
  → getCategoryColor()
  → getHealthMessage()
  → aqiScaleList

aqi_service.dart
  → API constants
  → fetchAqiByCity()
  → fetchCitySuggestions()
  → fetchAqiByCoordinates()
  → reverseGeocode()
  → parseNominatimAddress()
  → fetchAqiForCurrentLocation()
  → _fetchAirQuality()

home_page.dart
  → controllers/state
  → initState()
  → dispose()
  → _onSearchChanged()
  → _fetchAqiForCity()
  → _fetchAqiForSuggestion()
  → _fetchAqiForLocation()
  → _refreshData()
  → build()
  → search UI
  → suggestion UI
  → location button
  → loading/error UI
  → AQI content
  → location card
  → hero AQI card
  → pollutant cards
  → AQI legend
```

