import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

class PopularPlacesScreen extends StatefulWidget {
  const PopularPlacesScreen({super.key});

  @override
  State<PopularPlacesScreen> createState() => _PopularPlacesScreenState();
}

class _PopularPlacesScreenState extends State<PopularPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  List<TouristPlace> _places = [];
  List<TouristPlace> _filteredPlaces = [];
  bool _isLoading = false; // Start with no loading
  bool _hasLocationPermission = false;
  String? _locationError = "Enable location access to view nearby places."; // Start with error message

  @override
  void initState() {
    super.initState();
    // Start with empty places - only load after permission is granted
    _places = [];
    _filteredPlaces = [];
    _requestLocationPermission();
    _searchController.addListener(_filterPlaces);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Request location permission when screen opens
  Future<void> _requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.request();
      
      if (status.isGranted) {
        setState(() {
          _hasLocationPermission = true;
          _locationError = null; // Clear any previous error
          _isLoading = true; // Start loading only when permission is granted
        });
        await _getCurrentLocationAndLoadPlaces();
      } else {
        setState(() {
          _hasLocationPermission = false;
          _locationError = "Enable location access to view nearby places.";
          _isLoading = false;
          _places = []; // Ensure places are empty
          _filteredPlaces = [];
        });
      }
    } catch (e) {
      setState(() {
        _hasLocationPermission = false;
        _locationError = "Enable location access to view nearby places.";
        _isLoading = false;
        _places = []; // Ensure places are empty on error
        _filteredPlaces = [];
      });
    }
  }

  // Get current location and load nearby places dynamically
  Future<void> _getCurrentLocationAndLoadPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double userLat = position.latitude;
      double userLon = position.longitude;

      print("User Location: $userLat , $userLon");

      final nearbyPlaces = await _fetchPlacesFromAPI(userLat, userLon);

      setState(() {
        _places = nearbyPlaces;
        _filteredPlaces = List.from(_places);
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _locationError = "Failed to get location.";
        _isLoading = false;
      });
    }
  }

  // Load nearby places dynamically based on user location
  Future<void> _loadNearbyPlaces(double userLat, double userLon) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would call a backend API with user coordinates
    // The API would return places within 5-10 km radius of the user's location
    final nearbyPlaces = await _fetchPlacesFromAPI(userLat, userLon);

    setState(() {
      _places = nearbyPlaces;
      _filteredPlaces = List.from(_places);
      _isLoading = false;
    });
  }

  // Simulate API call to fetch places based on location
  Future<List<TouristPlace>> _fetchPlacesFromAPI(
      double userLat,
      double userLon,
      ) async {

    final response = await http.post(
      Uri.parse(ApiConfig.nearbyPlaces),
      body: {
        "latitude": userLat.toString(),
        "longitude": userLon.toString(),
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((place) {
        return TouristPlace(
          name: place["name"],
          category: place["category"],
          latitude: place["latitude"],
          longitude: place["longitude"],
          imageUrl: place["image"] ?? "",
          description: place["description"] ?? "",
          distance: place["distance"],
        );
      }).toList();
    } else {
      throw Exception("Failed to load places");
    }
  }

  // Filter places based on search and category
  void _filterPlaces() {
    setState(() {
      _filteredPlaces = _places.where((place) {
        bool matchesSearch = place.name.toLowerCase()
            .contains(_searchController.text.toLowerCase());
        bool matchesFilter = _selectedFilter == 'All' || 
            place.category == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only show search and filter if we have location permission
        if (_hasLocationPermission && _locationError == null) 
          _buildSearchAndFilterSection(),
        Expanded(
          child: _buildBodyContent(),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    // Always show location permission error if permission is not granted
    if (!_hasLocationPermission || _locationError != null) {
      return _buildLocationPermissionError();
    }

    // Show loading only if we have permission and are loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state only if we have permission but no places
    if (_filteredPlaces.isEmpty) {
      return _buildEmptyState();
    }

    // Show places grid only if we have permission and places
    return _buildPlacesGrid();
  }

  Widget _buildLocationPermissionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _locationError ?? "Enable location to see nearby places",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _requestLocationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No nearby places found in this area',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or check your location',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Search bar and filter chips
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search nearby places',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('Tourist Places', 'Tourist Places'),
                const SizedBox(width: 8),
                _buildFilterChip('Hospitals', 'Hospitals'),
                const SizedBox(width: 8),
                _buildFilterChip('Police Stations', 'Police Stations'),
                const SizedBox(width: 8),
                _buildFilterChip('Restaurants', 'Restaurants'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == filter,
      onSelected: (isSelected) {
        setState(() {
          _selectedFilter = isSelected ? filter : 'All';
          _filterPlaces();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2196F3),
      labelStyle: TextStyle(
        color: _selectedFilter == filter 
            ? Colors.white 
            : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // Grid of tourist places
  Widget _buildPlacesGrid() {
    if (_filteredPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No places found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _filteredPlaces.length,
        itemBuilder: (context, index) {
          final place = _filteredPlaces[index];
          return _buildPlaceCard(place);
        },
      ),
    );
  }

  // Individual place card
  Widget _buildPlaceCard(TouristPlace place) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔥 IMAGE SECTION
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: place.imageUrl.isNotEmpty
                ?Image.network(
              place.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 160,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 40),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  place.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text("${place.distance.toStringAsFixed(1)} km away"),
                    const Spacer(),

                    GestureDetector(
                      onTap: () => _openNavigation(place),
                      child: const Icon(
                        Icons.directions,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tourist Places':
        return Icons.tour;
      case 'Hospitals':
        return Icons.local_hospital;
      case 'Police Stations':
        return Icons.local_police;
      case 'Restaurants':
        return Icons.restaurant;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tourist Places':
        return Colors.purple;
      case 'Hospitals':
        return Colors.red;
      case 'Police Stations':
        return Colors.blue;
      case 'Restaurants':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openNavigation(TouristPlace place) async {
    final Uri googleMapUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}",
    );

    await launchUrl(
      googleMapUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  // Place details dialog
  void _showPlaceDetails(TouristPlace place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${place.category}'),
            const SizedBox(height: 8),
            Text('Distance: ${place.distance.toStringAsFixed(1)} km'),
            const SizedBox(height: 8),
            Text(place.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to place
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }

}

// Tourist place model
class TouristPlace {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String description;
  final double distance; // Distance from user in km

  TouristPlace({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.description,
    required this.distance,
  });
}
