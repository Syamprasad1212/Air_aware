import 'dart:async';
import 'package:flutter/material.dart';
import 'aqi_model.dart';
import 'aqi_service.dart';
import 'aqi_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final AqiService _aqiService = AqiService();

  AqiModel? _aqiData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUsingGps = false;
  String _currentCityQuery = 'Vijayawada';

  // Autocomplete state
  List<LocationSuggestion> _suggestions = [];
  bool _isFetchingSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Default initial location fetch for Vijayawada
    _searchController.text = _currentCityQuery;
    _fetchAqiForCity(_currentCityQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Handle search text changes with 350ms debounce
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _suggestions = [];
        _isFetchingSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isFetchingSuggestions = true;
      });

      final results = await _aqiService.fetchCitySuggestions(trimmed);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isFetchingSuggestions = false;
        });
      }
    });
  }

  // Fetch AQI by city name (standard search)
  Future<void> _fetchAqiForCity(String city) async {
    _debounceTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard safely
    setState(() {
      _suggestions = [];
      _isLoading = true;
      _errorMessage = null;
      _isUsingGps = false;
      _currentCityQuery = city;
    });

    try {
      final data = await _aqiService.fetchAqiByCity(city);
      setState(() {
        _aqiData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Fetch AQI directly using a selected autocomplete suggestion
  Future<void> _fetchAqiForSuggestion(LocationSuggestion suggestion) async {
    _debounceTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _suggestions = [];
      _searchController.text = suggestion.name;
      _isLoading = true;
      _errorMessage = null;
      _isUsingGps = false;
      _currentCityQuery = suggestion.name;
    });

    try {
      final data = await _aqiService.fetchAqiByCoordinates(
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        cityName: suggestion.name,
        locationDetails: suggestion.details.isNotEmpty
            ? suggestion.details
            : '${suggestion.latitude}, ${suggestion.longitude}',
      );
      setState(() {
        _aqiData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Fetch AQI using device GPS + automatic reverse geocoded human-readable name
  Future<void> _fetchAqiForLocation() async {
    _debounceTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _suggestions = [];
      _isLoading = true;
      _errorMessage = null;
      _isUsingGps = true;
    });

    try {
      final data = await _aqiService.fetchAqiForCurrentLocation();
      setState(() {
        _aqiData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Refresh current data
  void _refreshData() {
    if (_isUsingGps) {
      _fetchAqiForLocation();
    } else {
      _fetchAqiForCity(_currentCityQuery.isNotEmpty ? _currentCityQuery : 'Vijayawada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AirAware',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Air Quality Index • SDG 11',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchSection(),
              if (_suggestions.isNotEmpty) _buildSuggestionsList(),
              const SizedBox(height: 12),
              _buildUseLocationButton(),
              const SizedBox(height: 16),
              if (_isLoading) _buildLoadingView(),
              if (!_isLoading && _errorMessage != null) _buildErrorView(),
              if (!_isLoading && _errorMessage == null && _aqiData != null)
                _buildAqiContent(_aqiData!),
            ],
          ),
        ),
      ),
    );
  }

  // Search input bar
  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _fetchAqiForCity(value.trim());
          }
        },
        decoration: InputDecoration(
          hintText: 'Search city (e.g. Chennai, Hyderabad, Delhi)',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFetchingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.teal),
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    _fetchAqiForCity(_searchController.text.trim());
                  }
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Autocomplete Suggestions Dropdown List
  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_city, color: Colors.teal, size: 20),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: item.details.isNotEmpty
                ? Text(
                    item.details,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                : null,
            trailing: const Icon(Icons.north_west, size: 14, color: Colors.black38),
            onTap: () => _fetchAqiForSuggestion(item),
          );
        },
      ),
    );
  }

  // "Use My Location" action button
  Widget _buildUseLocationButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _fetchAqiForLocation,
      icon: const Icon(Icons.my_location, size: 18),
      label: const Text('Use My Location'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.teal.shade800,
        side: BorderSide(color: Colors.teal.shade400),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.teal.shade50,
      ),
    );
  }

  // Loading state indicator
  Widget _buildLoadingView() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Fetching latest air quality data...',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Error state display card
  Widget _buildErrorView() {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main AQI Data Content
  Widget _buildAqiContent(AqiModel data) {
    final category = AqiUtils.getCategory(data.aqi);
    final categoryColor = AqiUtils.getCategoryColor(data.aqi);
    final healthMessage = AqiUtils.getHealthMessage(data.aqi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Location Info Header
        _buildLocationCard(data),
        const SizedBox(height: 16),

        // Hero AQI Card with Dynamic Category Colour
        _buildAqiHeroCard(data.aqi, category, categoryColor, healthMessage),
        const SizedBox(height: 16),

        // Supporting Pollutants (PM2.5 & PM10)
        _buildPollutantsSection(data.pm25, data.pm10),
        const SizedBox(height: 20),

        // AQI Scale Reference Legend
        _buildAqiScaleLegend(data.aqi),
        const SizedBox(height: 20),

        // Refresh Action Button
        ElevatedButton.icon(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh AQI Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // Location Card
  Widget _buildLocationCard(AqiModel data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.teal, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.cityName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (data.locationDetails.isNotEmpty)
                  Text(
                    data.locationDetails,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Prominent Hero AQI Display Card
  Widget _buildAqiHeroCard(int aqi, String category, Color categoryColor, String healthMessage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top dynamic header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Text(
              'CURRENT AQI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Prominent AQI Number
                Text(
                  '$aqi',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: categoryColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Short Health Advisory Message
                Text(
                  healthMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Supporting Pollutants Grid (PM2.5 & PM10)
  Widget _buildPollutantsSection(double pm25, double pm10) {
    return Row(
      children: [
        Expanded(
          child: _buildPollutantCard(
            title: 'PM2.5',
            value: pm25.toStringAsFixed(1),
            unit: 'µg/m³',
            icon: Icons.grain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPollutantCard(
            title: 'PM10',
            value: pm10.toStringAsFixed(1),
            unit: 'µg/m³',
            icon: Icons.cloud_queue,
          ),
        ),
      ],
    );
  }

  // Individual Pollutant Card
  Widget _buildPollutantCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.teal.shade600),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AQI Scale Reference Legend
  Widget _buildAqiScaleLegend(int currentAqi) {
    final currentCategory = AqiUtils.getCategory(currentAqi);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AQI SCALE (US EPA Standard)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          // Scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: AqiUtils.aqiScaleList.map((item) {
                return Expanded(
                  child: Container(
                    height: 10,
                    color: item['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Scale items breakdown
          Column(
            children: AqiUtils.aqiScaleList.map((item) {
              final String name = item['name'] as String;
              final String range = item['range'] as String;
              final Color color = item['color'] as Color;

              // Check if current category matches this scale item
              final bool isSelected = (name == 'USG' && currentCategory == 'Unhealthy for Sensitive Groups') ||
                  (name == currentCategory);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2.5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected ? Border.all(color: color, width: 1) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
