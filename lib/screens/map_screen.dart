import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/venues_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_platform.dart';
import '../widgets/map/map_search_bar.dart';
import '../widgets/map/category_filter_list.dart';
import '../widgets/map/venue_detail_card.dart';
import '../widgets/map/map_action_controls.dart';
import '../widgets/map/apple_map_view.dart';
import '../widgets/map/google_map_view.dart';
import '../widgets/map/unified_map_controller.dart';

class MapScreen extends StatefulWidget {
  final String? selectedVenueId;

  const MapScreen({super.key, this.selectedVenueId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // State
  String _activeCategory = 'All';
  String _searchQuery = '';
  String? _selectedVenueId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map State
  UnifiedMapController? _mapController;
  double _currentLat = 34.678;
  double _currentLng = 33.043;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedVenueId != null) {
      _selectedVenueId = widget.selectedVenueId;
    }

    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVenueId != oldWidget.selectedVenueId) {
      if (widget.selectedVenueId != null) {
        setState(() {
          _selectedVenueId = widget.selectedVenueId;
        });
        _animateToSelectedVenue();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _hideKeyboardAndUnfocus() {
    // Remove focus from search field
    _searchFocusNode.unfocus();
    // Hide keyboard
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  List<Venue> get _filteredVenues {
    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);
    return venuesProvider.venues.where((venue) {
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

  void _onMapCreated(UnifiedMapController controller) {
    _mapController = controller;
    // If we have a selection on load, animate to it
    if (_selectedVenueId != null) {
      // Small delay to ensure map is fully ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _animateToSelectedVenue();
      });
    }
  }

  void _animateToSelectedVenue() {
    if (_selectedVenueId == null || _mapController == null) return;

    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);
    try {
      final venue = venuesProvider.venues.firstWhere(
        (v) => v.id == _selectedVenueId,
      );
      _mapController!.animateTo(venue.lat, venue.lng, _currentZoom);
    } catch (_) {}
  }

  Future<void> _onMyLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    // Web browsers only prompt for geolocation from a user gesture.
    if (kIsWeb ||
        locationProvider.latitude == null ||
        locationProvider.longitude == null) {
      await locationProvider.refreshLocation();
    }
    if (!mounted) return;
    if (locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      await _mapController?.animateTo(
        locationProvider.latitude!,
        locationProvider.longitude!,
        15.0,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationProvider.error ??
                'Could not get your location. Allow location access in the browser.',
          ),
        ),
      );
    }
  }

  Widget _webOverlay(Widget child) {
    // HtmlElementView maps steal mouse events from Flutter overlays on web.
    if (kIsWeb) return PointerInterceptor(child: child);
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Venue? selectedVenue;
    if (_selectedVenueId != null) {
      try {
        final venuesProvider = Provider.of<VenuesProvider>(
          context,
          listen: false,
        );
        selectedVenue = venuesProvider.venues.firstWhere(
          (v) => v.id == _selectedVenueId,
        );
      } catch (_) {
        selectedVenue = null;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          Positioned.fill(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                // Apple Maps is iOS-only. Web uses Google Maps JS even on
                // iPhone Safari, where defaultTargetPlatform is iOS.
                final useAppleMaps =
                    AppPlatform.isIOS && themeProvider.useAppleMaps;

                if (useAppleMaps) {
                  return AppleMapView(
                    venues: _filteredVenues,
                    selectedVenueId: _selectedVenueId,
                    onVenueSelected: (id) =>
                        setState(() => _selectedVenueId = id),
                    onCameraMove: (lat, lng, zoom) {
                      _currentLat = lat;
                      _currentLng = lng;
                      _currentZoom = zoom;
                    },
                    onMapTap: () {
                      _hideKeyboardAndUnfocus();
                      setState(() => _selectedVenueId = null);
                    },
                    onMapCreated: _onMapCreated,
                    initialLat: _currentLat, // Preserve position on rebuild
                    initialLng: _currentLng,
                    initialZoom: _currentZoom,
                    showUserLocation: true,
                  );
                } else {
                  return GoogleMapView(
                    venues: _filteredVenues,
                    selectedVenueId: _selectedVenueId,
                    onVenueSelected: (id) =>
                        setState(() => _selectedVenueId = id),
                    onCameraMove: (lat, lng, zoom) {
                      _currentLat = lat;
                      _currentLng = lng;
                      _currentZoom = zoom;
                    },
                    onMapTap: () {
                      _hideKeyboardAndUnfocus();
                      setState(() => _selectedVenueId = null);
                    },
                    onMapCreated: _onMapCreated,
                    initialLat: _currentLat,
                    initialLng: _currentLng,
                    initialZoom: _currentZoom,
                    isDark: isDark,
                  );
                }
              },
            ),
          ),

          // Top Controls (Search & Categories)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _webOverlay(
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      MapSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        isDark: isDark,
                        searchQuery: _searchQuery,
                        onSearchChanged: (val) =>
                            setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 12),
                      CategoryFilterList(
                        activeCategory: _activeCategory,
                        isDark: isDark,
                        onCategorySelected: (cat) =>
                            setState(() => _activeCategory = cat),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Map Action Controls
          Positioned(
            right: 16,
            bottom: _selectedVenueId != null && selectedVenue != null
                ? MediaQuery.of(context).padding.bottom +
                      300 // Above venue detail card
                : 200, // Default position
            child: _webOverlay(
              MapActionControls(
                isDark: isDark,
                onZoomIn: () => _mapController?.zoomIn(),
                onZoomOut: () => _mapController?.zoomOut(),
                onMyLocation: _onMyLocation,
              ),
            ),
          ),

          // Venue Detail Card
          if (_selectedVenueId != null && selectedVenue != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 15,
              left: 16,
              right: 16,
              child: _webOverlay(
                VenueDetailCard(venue: selectedVenue, isDark: isDark),
              ),
            ),
        ],
      ),
    );
  }
}
