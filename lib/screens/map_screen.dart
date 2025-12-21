import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/category_icons.dart';
import '../utils/marker_helper.dart';
import '../utils/geo_utils.dart';

class MapScreen extends StatefulWidget {
  final String? selectedVenueId;

  const MapScreen({super.key, this.selectedVenueId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _apiService = ApiService();
  final Completer<gmaps.GoogleMapController> _mapController =
      Completer<gmaps.GoogleMapController>();
  final MapController _flutterMapController = MapController();
  final Completer<apple_maps.AppleMapController> _appleMapController =
      Completer<apple_maps.AppleMapController>();

  String _activeCategory = 'All';
  String _searchQuery = '';
  List<Venue> _venues = [];
  List<String> _categories = ['All'];
  String? _selectedVenueId;
  final Map<String, gmaps.BitmapDescriptor> _markerIcons = {};
  final Map<String, apple_maps.BitmapDescriptor> _appleMarkerIcons = {};
  apple_maps.BitmapDescriptor? _blueUserMarkerIcon;
  bool _markersReady = false;
  bool _showUserLocation =
      false; // Track if user location marker should be shown
  double? _currentZoom;
  latlong.LatLng _currentCenter = const latlong.LatLng(34.678, 33.043);
  bool _useNativeAppleMaps =
      true; // Toggle between native Apple Maps and OpenStreetMap

  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(34.678, 33.043),
    zoom: 13,
  );

  static const apple_maps.CameraPosition _initialApplePosition =
      apple_maps.CameraPosition(
        target: apple_maps.LatLng(34.678, 33.043),
        zoom: 13,
      );

  @override
  void initState() {
    super.initState();
    // Set selected venue if provided from route
    if (widget.selectedVenueId != null) {
      _selectedVenueId = widget.selectedVenueId;
    }
    _fetchData();
  }

  Future<void> _loadMarkerIcons() async {
    // Pre-load marker icons for all venues
    // This improves performance by caching icons
    if (_venues.isEmpty || !mounted) return;

    if (Platform.isIOS && _useNativeAppleMaps) {
      // Load Apple Maps marker icons
      final appleIcons = <String, apple_maps.BitmapDescriptor>{};
      for (final venue in _venues) {
        final category = venue.category.isNotEmpty
            ? venue.category
            : venue.type;
        final key = '${venue.id}_selected';
        final unselectedKey = '${venue.id}_unselected';

        if (!appleIcons.containsKey(key)) {
          appleIcons[key] = await createCustomAppleMarkerIcon(
            category: category,
            isSelected: true,
          );
        }
        if (!appleIcons.containsKey(unselectedKey)) {
          appleIcons[unselectedKey] = await createCustomAppleMarkerIcon(
            category: category,
            isSelected: false,
          );
        }
      }

      if (mounted) {
        setState(() {
          _appleMarkerIcons.addAll(appleIcons);
          _markersReady = true;
        });
      }
    } else {
      // Load Google Maps marker icons
      final icons = <String, gmaps.BitmapDescriptor>{};
      for (final venue in _venues) {
        final category = venue.category.isNotEmpty
            ? venue.category
            : venue.type;
        final key = '${venue.id}_selected';
        final unselectedKey = '${venue.id}_unselected';

        if (!icons.containsKey(key)) {
          icons[key] = await createCustomMarkerIcon(
            category: category,
            isSelected: true,
          );
        }
        if (!icons.containsKey(unselectedKey)) {
          icons[unselectedKey] = await createCustomMarkerIcon(
            category: category,
            isSelected: false,
          );
        }
      }

      if (mounted) {
        setState(() {
          _markerIcons.addAll(icons);
          _markersReady = true;
        });
      }
    }
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

      // Load marker icons after venues are loaded
      _loadMarkerIcons();

      // If a venue was selected from route, animate to it after venues are loaded
      if (widget.selectedVenueId != null &&
          _selectedVenueId == widget.selectedVenueId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            final venue = _venues.firstWhere(
              (v) => v.id == widget.selectedVenueId,
            );
            _animateToVenue(venue);
          } catch (e) {
            // Venue not found, ignore
          }
        });
      }
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

  Set<gmaps.Marker> get _markers {
    final markers = <gmaps.Marker>{};

    if (!_markersReady) {
      return markers; // Return empty set until icons are loaded
    }

    // Add user location marker if enabled
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (_showUserLocation &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('user_location'),
          position: gmaps.LatLng(
            locationProvider.latitude!,
            locationProvider.longitude!,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue,
          ),
          zIndexInt: 100, // Always on top
        ),
      );
    }

    // Add venue markers
    final venueMarkers = _filteredVenues.map((venue) {
      final isSelected = _selectedVenueId == venue.id;
      final category = venue.category.isNotEmpty ? venue.category : venue.type;
      final iconKey = '${venue.id}_${isSelected ? 'selected' : 'unselected'}';

      // Get cached icon or create default
      final icon =
          _markerIcons[iconKey] ??
          gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          );

      return gmaps.Marker(
        markerId: gmaps.MarkerId(venue.id),
        position: gmaps.LatLng(venue.lat, venue.lng),
        icon: icon,
        zIndexInt: isSelected ? 10 : 1,
        onTap: () async {
          final previousSelected = _selectedVenueId;
          setState(() {
            _selectedVenueId = venue.id;
          });

          // Update icons for both previously selected and newly selected markers
          if (previousSelected != null && previousSelected != venue.id) {
            final prevVenue = _venues.firstWhere(
              (v) => v.id == previousSelected,
            );
            final prevCategory = prevVenue.category.isNotEmpty
                ? prevVenue.category
                : prevVenue.type;
            await _updateMarkerIcon(previousSelected, prevCategory, false);
          }
          await _updateMarkerIcon(venue.id, category, true);

          _animateToVenue(venue);
        },
      );
    }).toSet();

    markers.addAll(venueMarkers);
    return markers;
  }

  Future<void> _updateMarkerIcon(
    String venueId,
    String category,
    bool isSelected,
  ) async {
    if (!mounted) return;
    final key = '${venueId}_${isSelected ? 'selected' : 'unselected'}';

    if (Platform.isIOS && _useNativeAppleMaps) {
      // Update Apple Maps marker icon - always regenerate to ensure it updates
      final icon = await createCustomAppleMarkerIcon(
        category: category,
        isSelected: isSelected,
      );
      if (mounted) {
        setState(() {
          _appleMarkerIcons[key] = icon;
        });
      }
    } else if (!Platform.isIOS) {
      // Update Google Maps marker icon - always regenerate to ensure it updates
      final icon = await createCustomMarkerIcon(
        category: category,
        isSelected: isSelected,
      );
      if (mounted) {
        setState(() {
          _markerIcons[key] = icon;
        });
      }
    }
  }

  Future<void> _animateToVenue(Venue venue) async {
    if (Platform.isIOS) {
      if (_useNativeAppleMaps) {
        // For native Apple Maps - only move camera, don't change zoom
        final controller = await _appleMapController.future;
        // Use newLatLng to only change position without affecting zoom
        await controller.animateCamera(
          apple_maps.CameraUpdate.newLatLng(
            apple_maps.LatLng(venue.lat, venue.lng),
          ),
        );
      } else {
        // For OpenStreetMap (flutter_map)
        final zoom = _currentZoom ?? 13.0;
        _flutterMapController.move(latlong.LatLng(venue.lat, venue.lng), zoom);
        setState(() {
          _currentCenter = latlong.LatLng(venue.lat, venue.lng);
        });
      }
    } else {
      // For Google Maps - only move camera, don't change zoom
      final controller = await _mapController.future;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLng(gmaps.LatLng(venue.lat, venue.lng)),
      );
    }
  }

  String _getMapStyle(bool isDark) {
    if (isDark) {
      return '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';
    } else {
      return '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadada"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9c9c9"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  }
]
''';
    }
  }

  Widget _buildGoogleMap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return gmaps.GoogleMap(
      mapType: gmaps.MapType.normal,
      initialCameraPosition: _initialPosition,
      markers: _markers,
      onMapCreated: (gmaps.GoogleMapController controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          _currentZoom = _initialPosition.zoom;
          print('✅ Google Map created successfully');
        }
      },
      onTap: (_) => setState(() => _selectedVenueId = null),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMoveStarted: () {
        print('📍 Camera move started');
      },
      onCameraMove: (gmaps.CameraPosition position) {
        _currentZoom = position.zoom;
      },
      style: _getMapStyle(isDark),
    );
  }

  Widget _buildAppleMap() {
    if (_useNativeAppleMaps) {
      // Use native Apple Maps
      return apple_maps.AppleMap(
        initialCameraPosition: _initialApplePosition,
        annotations: _buildAppleMapsAnnotations(),
        onMapCreated: (apple_maps.AppleMapController controller) {
          if (!_appleMapController.isCompleted) {
            _appleMapController.complete(controller);
            _currentZoom = _initialApplePosition.zoom;
            print('✅ Native Apple Map created successfully');
          }
        },
        onTap: (apple_maps.LatLng position) async {
          // Find nearest venue to tapped position
          Venue? nearestVenue;
          double minDistance = double.infinity;

          for (final venue in _filteredVenues) {
            final distance =
                ((venue.lat - position.latitude).abs() +
                (venue.lng - position.longitude).abs());
            if (distance < minDistance) {
              minDistance = distance;
              nearestVenue = venue;
            }
          }

          if (nearestVenue != null && minDistance < 0.01) {
            // Close enough to select venue
            final previousSelected = _selectedVenueId;
            final venue = nearestVenue; // Local variable for null safety
            final category = venue.category.isNotEmpty
                ? venue.category
                : venue.type;

            setState(() {
              _selectedVenueId = venue.id;
            });

            // Update icons for both previously selected and newly selected markers
            if (previousSelected != null && previousSelected != venue.id) {
              final prevVenue = _venues.firstWhere(
                (v) => v.id == previousSelected,
              );
              final prevCategory = prevVenue.category.isNotEmpty
                  ? prevVenue.category
                  : prevVenue.type;
              _updateMarkerIcon(previousSelected, prevCategory, false);
            }
            _updateMarkerIcon(venue.id, category, true);

            _animateToVenue(venue);
          } else {
            setState(() => _selectedVenueId = null);
          }
        },
      );
    } else {
      // Use OpenStreetMap (flutter_map) as fallback
      final zoom = _currentZoom ?? 13.0;
      return FlutterMap(
        mapController: _flutterMapController,
        options: MapOptions(
          initialCenter: _currentCenter,
          initialZoom: zoom,
          onTap: (tapPosition, point) {
            setState(() => _selectedVenueId = null);
          },
          onMapEvent: (event) {
            if (event is MapEventMove) {
              _currentZoom = _flutterMapController.camera.zoom;
              _currentCenter = _flutterMapController.camera.center;
            }
          },
        ),
        children: [
          // OpenStreetMap tiles
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.exness.reward_flutter',
            maxZoom: 19,
            minZoom: 3,
          ),
          // Markers
          MarkerLayer(markers: _buildFlutterMapMarkers()),
        ],
      );
    }
  }

  Set<apple_maps.Annotation> _buildAppleMapsAnnotations() {
    final annotations = <apple_maps.Annotation>{};

    // Add user location marker if enabled
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (_showUserLocation &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      // Use blue marker icon (create if not already created)
      final blueMarker =
          _blueUserMarkerIcon ?? apple_maps.BitmapDescriptor.defaultAnnotation;

      annotations.add(
        apple_maps.Annotation(
          annotationId: apple_maps.AnnotationId('user_location'),
          position: apple_maps.LatLng(
            locationProvider.latitude!,
            locationProvider.longitude!,
          ),
          icon: blueMarker,
        ),
      );
    }

    if (!_markersReady || _filteredVenues.isEmpty) {
      return annotations;
    }

    // Add venue markers
    final venueAnnotations = _filteredVenues.map((venue) {
      final isSelected = _selectedVenueId == venue.id;
      final iconKey = '${venue.id}_${isSelected ? 'selected' : 'unselected'}';

      // Get cached icon or create a default one
      final icon = _appleMarkerIcons[iconKey];

      // Create a simple default icon if custom icon not available
      final markerIcon = icon ?? apple_maps.BitmapDescriptor.defaultAnnotation;

      // Build annotation with custom icon (no info window)
      return apple_maps.Annotation(
        annotationId: apple_maps.AnnotationId(venue.id),
        position: apple_maps.LatLng(venue.lat, venue.lng),
        icon: markerIcon,
      );
    }).toSet();

    annotations.addAll(venueAnnotations);
    return annotations;
  }

  List<Marker> _buildFlutterMapMarkers() {
    final markers = <Marker>[];

    // Add user location marker if enabled
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (_showUserLocation &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      markers.add(
        Marker(
          point: latlong.LatLng(
            locationProvider.latitude!,
            locationProvider.longitude!,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    if (!_markersReady) return markers;

    // Add venue markers
    final venueMarkers = _filteredVenues.map((venue) {
      final isSelected = _selectedVenueId == venue.id;
      final category = venue.category.isNotEmpty ? venue.category : venue.type;

      return Marker(
        point: latlong.LatLng(venue.lat, venue.lng),
        width: 72, // Increased marker size
        height: 72,
        child: GestureDetector(
          onTap: () async {
            final previousSelected = _selectedVenueId;
            setState(() {
              _selectedVenueId = venue.id;
            });
            // Update icons if needed
            if (previousSelected != null && previousSelected != venue.id) {
              final prevVenue = _venues.firstWhere(
                (v) => v.id == previousSelected,
              );
              final prevCategory = prevVenue.category.isNotEmpty
                  ? prevVenue.category
                  : prevVenue.type;
              await _updateMarkerIcon(previousSelected, prevCategory, false);
            }
            await _updateMarkerIcon(venue.id, category, true);
            _animateToVenue(venue);
          },
          child: Container(
            width: 42, // Increased marker size
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD00B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              getCategoryIcon(category),
              size: isSelected ? 28 : 20, // Increased icon size proportionally
              color: Colors.black,
            ),
          ),
        ),
      );
    }).toList();

    markers.addAll(venueMarkers);
    return markers;
  }

  String _getVenueDistance(Venue venue) {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      return calculateDistance(
        locationProvider.latitude!,
        locationProvider.longitude!,
        venue.lat,
        venue.lng,
      );
    }
    return venue.distance;
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          // Map - Must fill entire screen
          Positioned.fill(
            child: Platform.isIOS ? _buildAppleMap() : _buildGoogleMap(),
          ),
          // Search & Categories
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: TextEditingController(text: _searchQuery)
                          ..selection = TextSelection.collapsed(
                            offset: _searchQuery.length,
                          ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _fetchData();
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search venues...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 24,
                            color: isDark ? Colors.white : Colors.grey.shade600,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeCategory = category);
                              },
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFFFD00B)
                                      : (isDark
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white)
                                          .withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isActive
                                        ? const Color(0xFFFFD00B)
                                        : (isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey.shade200),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getCategoryIcon(category),
                                      size: 16,
                                      color: isActive
                                          ? Colors.black
                                          : (isDark
                                              ? Colors.white
                                              : Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Colors.black
                                            : (isDark
                                                ? Colors.white
                                                : Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
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
          // Map Controls - Position above venue detail card when visible
          Positioned(
            right: 16,
            bottom: _selectedVenueId != null && selectedVenue != null
                ? MediaQuery.of(context).padding.bottom +
                      200 // Above venue detail card
                : 200, // Default position when no venue selected
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.9)
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: Platform.isIOS
                          ? null
                          : () async {
                              final controller = await _mapController.future;
                              await controller.animateCamera(
                                gmaps.CameraUpdate.zoomIn(),
                              );
                            },
                      borderRadius: BorderRadius.circular(24),
                      child: Icon(
                        Icons.add,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Zoom Out
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E).withOpacity(0.9)
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: Platform.isIOS
                          ? null
                          : () async {
                              final controller = await _mapController.future;
                              await controller.animateCamera(
                                gmaps.CameraUpdate.zoomOut(),
                              );
                            },
                      borderRadius: BorderRadius.circular(24),
                      child: Icon(
                        Icons.remove,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // My Location
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD00B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                    if (locationProvider.latitude != null &&
                        locationProvider.longitude != null) {
                      // Show user location marker and create blue icon if needed
                      if (_blueUserMarkerIcon == null) {
                        _blueUserMarkerIcon =
                            await createBlueUserLocationMarker();
                      }
                      setState(() {
                        _showUserLocation = true;
                      });

                      if (Platform.isIOS) {
                        if (_useNativeAppleMaps) {
                          // Use native Apple Maps controller
                          final controller = await _appleMapController.future;
                          await controller.animateCamera(
                            apple_maps.CameraUpdate.newCameraPosition(
                              apple_maps.CameraPosition(
                                target: apple_maps.LatLng(
                                  locationProvider.latitude!,
                                  locationProvider.longitude!,
                                ),
                                zoom: 15,
                              ),
                            ),
                          );
                        } else {
                          // Use OpenStreetMap (flutter_map) controller
                          _flutterMapController.move(
                            latlong.LatLng(
                              locationProvider.latitude!,
                              locationProvider.longitude!,
                            ),
                            15,
                          );
                        }
                      } else {
                        final controller = await _mapController.future;
                        await controller.animateCamera(
                          gmaps.CameraUpdate.newCameraPosition(
                            gmaps.CameraPosition(
                              target: gmaps.LatLng(
                                locationProvider.latitude!,
                                locationProvider.longitude!,
                              ),
                              zoom: 15,
                            ),
                          ),
                        );
                      }
                    }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: const Icon(
                        Icons.my_location,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Venue Detail Card - Bottom Sheet
          if (_selectedVenueId != null && selectedVenue != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom - 15,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  if (selectedVenue != null) {
                    context.push('/venue/${selectedVenue.id}');
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Info and Image
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Discount Badge and Open Status
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD00B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        selectedVenue.discount.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedVenue.isOpen
                                          ? 'Open now'
                                          : 'Closed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Venue Name
                                Text(
                                  selectedVenue.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Type and Distance
                                Text(
                                  '${selectedVenue.type} • ${_getVenueDistance(selectedVenue)} away',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Rating
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Color(0xFFFFD00B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedVenue.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${selectedVenue.reviews})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right: Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: selectedVenue.image,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 96,
                                height: 96,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 96,
                                height: 96,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bottom Section: Actions
                      Row(
                        children: [
                          // Directions Button
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD00B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // TODO: Implement directions
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.directions,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Directions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Favorite Button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: favoritesProvider.isFavorite(
                                    selectedVenue.id,
                                  )
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (selectedVenue != null) {
                                    favoritesProvider.toggleFavorite(
                                      selectedVenue.id,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Icon(
                                  favoritesProvider.isFavorite(
                                        selectedVenue.id,
                                      )
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color: favoritesProvider.isFavorite(
                                        selectedVenue.id,
                                      )
                                      ? const Color(0xFFFFD00B)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
