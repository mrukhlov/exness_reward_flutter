import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/category_icons.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _apiService = ApiService();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  String _activeCategory = 'All';
  String _searchQuery = '';
  List<Venue> _venues = [];
  List<String> _categories = ['All'];
  String? _selectedVenueId;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(34.678, 33.043),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Fetch categories
      final apiCategories = await _apiService.getCategories();
      final categoryNames = ['All', ...apiCategories.map((cat) => cat.name)];

      // Fetch venues
      final apiVenues = await _apiService.getVenues(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        lat: locationProvider.latitude,
        lng: locationProvider.longitude,
      );

      setState(() {
        _categories = categoryNames;
        _venues = apiVenues;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  List<Venue> get _filteredVenues {
    return _venues.where((venue) {
      final matchesCategory =
          _activeCategory == 'All' || venue.category == _activeCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          venue.name.toLowerCase().contains(query) ||
          venue.category.toLowerCase().contains(query) ||
          (venue.address?.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Set<Marker> get _markers {
    return _filteredVenues.map((venue) {
      final isSelected = _selectedVenueId == venue.id;
      return Marker(
        markerId: MarkerId(venue.id),
        position: LatLng(venue.lat, venue.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          setState(() => _selectedVenueId = venue.id);
          _animateToVenue(venue);
        },
      );
    }).toSet();
  }

  Future<void> _animateToVenue(Venue venue) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(venue.lat, venue.lng), zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    Venue? selectedVenue;
    if (_selectedVenueId != null) {
      try {
        selectedVenue = _venues.firstWhere((v) => v.id == _selectedVenueId);
      } catch (e) {
        selectedVenue = null;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            onTap: (_) => setState(() => _selectedVenueId = null),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // Search & Categories
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _fetchData();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search venues...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isActive = _activeCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getCategoryIcon(category),
                                    size: 16,
                                    color: isActive
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category),
                                ],
                              ),
                              selected: isActive,
                              onSelected: (selected) {
                                setState(() => _activeCategory = category);
                              },
                              backgroundColor: Colors.white.withOpacity(0.9),
                              selectedColor: const Color(0xFFFFD00B),
                              labelStyle: TextStyle(
                                color: isActive
                                    ? Colors.black
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Map Controls
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: () async {
                    final controller = await _mapController.future;
                    await controller.animateCamera(CameraUpdate.zoomIn());
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  onPressed: () async {
                    final controller = await _mapController.future;
                    await controller.animateCamera(CameraUpdate.zoomOut());
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  onPressed: () async {
                    if (locationProvider.latitude != null &&
                        locationProvider.longitude != null) {
                      final controller = await _mapController.future;
                      await controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              locationProvider.latitude!,
                              locationProvider.longitude!,
                            ),
                            zoom: 15,
                          ),
                        ),
                      );
                    }
                  },
                  backgroundColor: const Color(0xFFFFD00B),
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ],
            ),
          ),
          // Venue Detail Card
          if (_selectedVenueId != null && selectedVenue != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      selectedVenue.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image),
                    ),
                  ),
                  title: Text(selectedVenue.name),
                  subtitle: Text(selectedVenue.address ?? ''),
                  trailing: IconButton(
                    icon: Icon(
                      favoritesProvider.isFavorite(selectedVenue.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    color: favoritesProvider.isFavorite(selectedVenue.id)
                        ? Colors.red
                        : Colors.grey,
                    onPressed: () {
                      if (selectedVenue != null) {
                        favoritesProvider.toggleFavorite(selectedVenue.id);
                      }
                    },
                  ),
                  onTap: () {
                    if (selectedVenue != null) {
                      context.go('/venue/${selectedVenue.id}');
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
