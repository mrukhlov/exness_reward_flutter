import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/venues_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/category_icons.dart';
import '../utils/marker_cache.dart';
import '../utils/marker_helper.dart';
import '../utils/geo_utils.dart';

/// Cluster data class to represent a group of venues
class _Cluster {
  final List<Venue> venues;
  final double lat;
  final double lng;

  _Cluster(this.venues, this.lat, this.lng);

  int get count => venues.length;
}

class MapScreen extends StatefulWidget {
  final String? selectedVenueId;

  const MapScreen({super.key, this.selectedVenueId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<gmaps.GoogleMapController> _mapController =
      Completer<gmaps.GoogleMapController>();
  final MapController _flutterMapController = MapController();
  Completer<apple_maps.AppleMapController> _appleMapController =
      Completer<apple_maps.AppleMapController>();

  String _activeCategory = 'All';
  String _searchQuery = '';
  String? _selectedVenueId;
  final MarkerCache _markerCache = MarkerCache();
  final TextEditingController _searchController = TextEditingController();
  // Local cache mapping venue ID + selection state to icon (populated from global cache)
  final Map<String, gmaps.BitmapDescriptor> _markerIcons = {};
  final Map<String, apple_maps.BitmapDescriptor> _appleMarkerIcons = {};
  apple_maps.BitmapDescriptor?
  _blueUserMarkerIcon; // Cache for blue user location marker
  // Store Apple Maps annotations in state to update them directly without rebuilding map
  Set<apple_maps.Annotation> _appleMapAnnotations = {};
  bool _markersReady = false;
  bool _showUserLocation =
      false; // Track if user location marker should be shown
  double? _currentZoom;
  double? _currentLat;
  double? _currentLng;
  bool _themeListenerAdded = false; // Track if ThemeProvider listener is added
  bool _venuesListenerAdded =
      false; // Track if VenuesProvider listener is added
  int _appleMapRebuildKey = 0; // Counter to force Apple Map rebuilds
  latlong.LatLng _currentCenter = const latlong.LatLng(34.678, 33.043);
  int _lastZoomLevel =
      0; // Track zoom level for marker scaling (rounded to avoid constant updates)
  bool _appleMapControllerReady =
      false; // Track if Apple Maps controller is ready
  bool _isDisposing = false; // Track if widget is disposing

  // Clustering configuration
  static const double _clusterZoomThreshold =
      14.0; // Show clusters below this zoom level
  static const double _clusterDistanceThreshold =
      0.01; // Distance threshold for clustering (in degrees)

  static const gmaps.CameraPosition _initialPosition = gmaps.CameraPosition(
    target: gmaps.LatLng(34.678, 33.043),
    zoom: 13,
  );

  static const apple_maps.CameraPosition _initialApplePosition =
      apple_maps.CameraPosition(
        target: apple_maps.LatLng(34.678, 33.043),
        zoom: 13,
      );

  /// Safely get Apple Maps controller, returns null if not ready or disposing
  /// CRITICAL: Always re-check mounted and _isDisposing after any await
  /// This prevents "awaiting a zombie" completer issue
  Future<apple_maps.AppleMapController?> _getAppleMapController() async {
    // 1. Immediate rejection - check all conditions upfront
    if (_isDisposing || !mounted || !_appleMapControllerReady) {
      return null;
    }

    // 2. Only await if we know it's actually finished
    // This prevents awaiting a completer that's still being set up
    if (!_appleMapController.isCompleted) {
      return null;
    }

    try {
      final controller = await _appleMapController.future;

      // 3. Post-await verification (The "Wait, are you still there?" check)
      // Widget might be disposed during the await
      if (_isDisposing || !mounted) {
        return null;
      }

      return controller;
    } on PlatformException catch (e) {
      // Suppress "methods called on terminated view" errors
      debugPrint(
        'PlatformException getting Apple Maps controller (suppressed): ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('Error getting Apple Maps controller: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set selected venue if provided from route
    if (widget.selectedVenueId != null) {
      _selectedVenueId = widget.selectedVenueId;
    }
    // Initialize search controller
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    // Load marker icons when venues are available from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarkerIcons();
      _tryAnimateToSelectedVenue();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to ThemeProvider changes to reload markers when map provider changes
    // Only add listener once to avoid duplicates
    if (!_themeListenerAdded) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.addListener(_onThemeProviderChanged);
      _themeListenerAdded = true;
    }
    if (!_venuesListenerAdded) {
      final venuesProvider = Provider.of<VenuesProvider>(
        context,
        listen: false,
      );
      venuesProvider.addListener(_onVenuesProviderChanged);
      _venuesListenerAdded = true;
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVenueId != oldWidget.selectedVenueId) {
      if (widget.selectedVenueId != null) {
        setState(() {
          _selectedVenueId = widget.selectedVenueId;
        });
        
        // Ensure markers are rebuilt to reflect selection
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        if (Platform.isIOS && themeProvider.useAppleMaps) {
             _appleMapAnnotations = _buildAppleMapsAnnotations();
        }

        // Animate to the new venue
        _tryAnimateToSelectedVenue();
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;

    // Reset controller ready flag
    _appleMapControllerReady = false;

    // Don't complete the completer if it's not completed yet
    // This prevents trying to use a deallocated controller
    if (!_appleMapController.isCompleted) {
      // Create a new completer to prevent any pending futures from completing
      _appleMapController = Completer<apple_maps.AppleMapController>();
    }

    // Remove listener if it was added
    if (_themeListenerAdded) {
      try {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        themeProvider.removeListener(_onThemeProviderChanged);
      } catch (e) {
        // Ignore errors if context is not available
      }
      _themeListenerAdded = false;
    }
    if (_venuesListenerAdded) {
      try {
        final venuesProvider = Provider.of<VenuesProvider>(
          context,
          listen: false,
        );
        venuesProvider.removeListener(_onVenuesProviderChanged);
      } catch (e) {
        // Ignore errors if context is not available
      }
      _venuesListenerAdded = false;
    }
    _searchController.dispose();
    super.dispose();
  }

  void _onThemeProviderChanged() {
    // Reload markers when map provider changes
    // Use WidgetsBinding to ensure we're in a safe state
    if (mounted && !_isDisposing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposing) {
          // Reset controller state before rebuilding
          _appleMapControllerReady = false;

          // Recreate the completer to avoid using deallocated controller
          // This prevents the unowned reference crash
          if (_appleMapController.isCompleted) {
            _appleMapController = Completer<apple_maps.AppleMapController>();
          }

          // Increment rebuild key to force Apple Map widget rebuild
          setState(() {
            _markersReady = false;
            _appleMapRebuildKey++;
          });
          // Reload icons for the new provider
          _loadMarkerIcons(forceReload: true);
        }
      });
    }
  }

  void _onVenuesProviderChanged() {
    // Reload markers when venues change
    if (mounted && !_isDisposing) {
      _loadMarkerIcons(forceReload: false);
    }
  }

  Future<void> _loadMarkerIcons({bool forceReload = false}) async {
    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);

    // Wait for venues to be available. Check categories too as we strictly need them.
    if ((!venuesProvider.hasVenues && venuesProvider.categories.length <= 1) ||
        !mounted ||
        !_markerCache.isPreloaded) {
      if (mounted && _markerCache.isPreloaded) {
        // Try again after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _loadMarkerIcons(forceReload: forceReload);
        });
      }
      return;
    }

    final venues = venuesProvider.venues;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final useAppleMaps = Platform.isIOS && themeProvider.useAppleMaps;

    try {
      // Clear icon caches when switching providers or forcing reload
      if (forceReload) {
        if (useAppleMaps) {
          _appleMarkerIcons.clear();
        } else {
          _markerIcons.clear();
        }
      }

      // Collect all unique categories from venues AND provider to ensure coverage
      final categories = <String>{...venuesProvider.categories};
      // Also add from venues just in case there are types not element of categories
      for (final venue in venues) {
        categories.add(venue.category.isNotEmpty ? venue.category : venue.type);
      }

      if (useAppleMaps) {
        // Load Apple Maps marker icons from cache by Category
        for (final category in categories) {
          try {
            final selectedKey = '${category}_selected';
            final unselectedKey = '${category}_unselected';

            _appleMarkerIcons[selectedKey] = await _markerCache
                .getAppleMarkerIcon(category, true);
            _appleMarkerIcons[unselectedKey] = await _markerCache
                .getAppleMarkerIcon(category, false);
          } catch (e) {
            debugPrint('Error loading icon for category $category: $e');
          }
        }
      } else {
        // Load Google Maps marker icons from cache by Category
        for (final category in categories) {
          try {
            final selectedKey = '${category}_selected';
            final unselectedKey = '${category}_unselected';

            _markerIcons[selectedKey] = await _markerCache.getGoogleMarkerIcon(
              category,
              true,
            );
            _markerIcons[unselectedKey] = await _markerCache
                .getGoogleMarkerIcon(category, false);
          } catch (e) {
            debugPrint('Error loading icon for category $category: $e');
          }
        }
      }

      if (mounted) {
        debugPrint(
          '✅ _loadMarkerIcons completed. Setting _markersReady=true. Counts: Apple=${_appleMarkerIcons.length}, Google=${_markerIcons.length}',
        );
        setState(() {
          _markersReady = true;
          // Build and store annotations for Apple Maps
          if (useAppleMaps) {
            _appleMapAnnotations = _buildAppleMapsAnnotations();
            _appleMapRebuildKey++;
          }
        });
        // Preload cluster icons
        _preloadClusterIcons();
        // Try to animate to selected venue after markers are ready
        _tryAnimateToSelectedVenue();
      }
    } catch (e, stack) {
      debugPrint('CRITICAL ERROR in _loadMarkerIcons: $e');
      debugPrint('Stack trace: $stack');
      // If loading fails, mark as ready anyway - will use default markers
      if (mounted) {
        setState(() {
          _markersReady = true;
        });
      }
    }
  }

  void _tryAnimateToSelectedVenue() {
    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);
    final targetId = _selectedVenueId ?? widget.selectedVenueId;
    if (venuesProvider.hasVenues && targetId != null) {
      try {
        final venue = venuesProvider.venues.firstWhere(
          (v) => v.id == targetId,
        );
        _animateToVenue(venue);
      } catch (e) {
        // Venue not found, ignore
      }
    }
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

  /// Check if tap position is near the last clicked annotation (if any)
  /// Returns true if tap is within threshold distance of the selected annotation
  bool _isTapNearSelectedAnnotation(apple_maps.LatLng tapPosition) {
    // If no annotation is selected, return false
    if (_selectedVenueId == null) {
      return false;
    }

    // Threshold distance in degrees (approximately 100-200 meters depending on zoom)
    // This covers the marker size plus some tolerance
    const double threshold = 0.0001;

    try {
      final venuesProvider = Provider.of<VenuesProvider>(
        context,
        listen: false,
      );
      final selectedVenue = venuesProvider.venues.firstWhere(
        (v) => v.id == _selectedVenueId,
      );

      final latDiff = (tapPosition.latitude - selectedVenue.lat).abs();
      final lngDiff = (tapPosition.longitude - selectedVenue.lng).abs();

      // Simple distance check - if both lat and lng differences are within threshold
      return latDiff < threshold && lngDiff < threshold;
    } catch (e) {
      // Venue not found, return false
      return false;
    }
  }

  /// Group nearby venues into clusters based on zoom level
  List<_Cluster> _createClusters(List<Venue> venues, double? zoom) {
    // If zoomed in enough, don't cluster (show individual markers)
    if (zoom != null && zoom >= _clusterZoomThreshold) {
      return venues.map((v) => _Cluster([v], v.lat, v.lng)).toList();
    }

    // Calculate distance threshold based on zoom level
    // Lower zoom = larger threshold (more clustering)
    final distanceThreshold = zoom != null
        ? _clusterDistanceThreshold * (15.0 - zoom) / 5.0
        : _clusterDistanceThreshold * 2.0;

    final clusters = <_Cluster>[];
    final processed = <int>{};

    for (int i = 0; i < venues.length; i++) {
      if (processed.contains(i)) continue;

      final venue = venues[i];
      final clusterVenues = <Venue>[venue];
      processed.add(i);

      // Find nearby venues to cluster together
      for (int j = i + 1; j < venues.length; j++) {
        if (processed.contains(j)) continue;

        final otherVenue = venues[j];
        final distance =
            ((venue.lat - otherVenue.lat).abs() +
            (venue.lng - otherVenue.lng).abs());

        if (distance < distanceThreshold) {
          clusterVenues.add(otherVenue);
          processed.add(j);
        }
      }

      // Calculate cluster center (average of all venues in cluster)
      final avgLat =
          clusterVenues.map((v) => v.lat).reduce((a, b) => a + b) /
          clusterVenues.length;
      final avgLng =
          clusterVenues.map((v) => v.lng).reduce((a, b) => a + b) /
          clusterVenues.length;

      clusters.add(_Cluster(clusterVenues, avgLat, avgLng));
    }

    return clusters;
  }

  /// Create a cluster marker icon with count
  Future<gmaps.BitmapDescriptor> _createClusterIcon(int count) async {
    final size = 80.0; // Increased to match individual marker size
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 1;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius, shadowPaint);

    // Draw circle background (white for clusters)
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw count text
    final textStyle = TextStyle(
      fontSize: count < 10 ? 28.0 : 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: count.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return gmaps.BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Set<gmaps.Marker> get _markers {
    final markers = <gmaps.Marker>{};

    if (!_markersReady) {
      return markers; // Return empty set until icons are loaded
    }

    // Don't add custom user location marker - both Google Maps and Apple Maps
    // use built-in user location indicators (myLocationEnabled / showsUserLocation)
    // Custom marker is only used for FlutterMap/OpenStreetMap fallback

    // User location is handled by myLocationEnabled property on GoogleMap widget
    // No custom marker needed

    // Create clusters based on zoom level
    final clusters = _createClusters(_filteredVenues, _currentZoom);

    // Create markers for clusters or individual venues
    for (final cluster in clusters) {
      if (cluster.count == 1) {
        // Single venue - show individual marker
        final venue = cluster.venues.first;
        final isSelected = _selectedVenueId == venue.id;
        final category = venue.category.isNotEmpty
            ? venue.category
            : venue.type;
        final iconKey = '${category}_${isSelected ? 'selected' : 'unselected'}';

        // Get cached icon or use default marker as fallback
        final icon =
            _markerIcons[iconKey] ??
            gmaps.BitmapDescriptor.defaultMarkerWithHue(
              isSelected
                  ? gmaps.BitmapDescriptor.hueYellow
                  : gmaps.BitmapDescriptor.hueRed,
            );

        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(venue.id),
            position: gmaps.LatLng(venue.lat, venue.lng),
            icon: icon,
            zIndexInt: isSelected ? 10 : 1,
            onTap: () async {
              if (!mounted) return;
              final previousSelected = _selectedVenueId;
              setState(() {
                _selectedVenueId = venue.id;
              });

              // Update icons for both previously selected and newly selected markers
              if (previousSelected != null && previousSelected != venue.id) {
                final venuesProvider = Provider.of<VenuesProvider>(
                  context,
                  listen: false,
                );
                final prevVenue = venuesProvider.venues.firstWhere(
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
          ),
        );
      } else {
        // Multiple venues - show cluster marker
        final clusterId =
            'cluster_${cluster.lat}_${cluster.lng}_${cluster.count}';

        // Get cluster icon (cached or default)
        final clusterIcon = _getClusterIcon(cluster.count);

        // Pre-create icon if not cached yet (async, will update on next rebuild)
        if (!_clusterIconsByCount.containsKey(cluster.count)) {
          _createClusterIcon(cluster.count).then((icon) {
            if (mounted) {
              setState(() {
                _clusterIconsByCount[cluster.count] = icon;
              });
            }
          });
        }

        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(clusterId),
            position: gmaps.LatLng(cluster.lat, cluster.lng),
            icon: clusterIcon,
            zIndexInt: 5,
            onTap: () async {
              // Zoom to cluster center when cluster is tapped
              if (_mapController.isCompleted) {
                final controller = await _mapController.future;
                // Calculate appropriate zoom level based on cluster size
                // Zoom in more for smaller clusters, less for larger ones
                final targetZoom = _currentZoom != null
                    ? (_currentZoom! + 2.0).clamp(10.0, 18.0)
                    : 15.0;

                await controller.animateCamera(
                  gmaps.CameraUpdate.newCameraPosition(
                    gmaps.CameraPosition(
                      target: gmaps.LatLng(cluster.lat, cluster.lng),
                      zoom: targetZoom,
                    ),
                  ),
                );

                // Update current position
                if (mounted) {
                  setState(() {
                    _currentLat = cluster.lat;
                    _currentLng = cluster.lng;
                    _currentZoom = targetZoom;
                  });
                }
              }
            },
          ),
        );
      }
    }

    return markers;
  }

  /// Cache for cluster icons by count (reusable across clusters)
  final Map<int, gmaps.BitmapDescriptor> _clusterIconsByCount = {};

  /// Get or create cluster icon for a given count
  gmaps.BitmapDescriptor _getClusterIcon(int count) {
    // Check cache first
    if (_clusterIconsByCount.containsKey(count)) {
      return _clusterIconsByCount[count]!;
    }

    // Return default icon temporarily, will be replaced when async creation completes
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(
      gmaps.BitmapDescriptor.hueYellow,
    );
  }

  /// Pre-create cluster icons for common counts
  Future<void> _preloadClusterIcons() async {
    // Pre-create icons for counts 2-50
    for (int count = 2; count <= 50; count++) {
      if (!_clusterIconsByCount.containsKey(count)) {
        try {
          final icon = await _createClusterIcon(count);
          if (mounted) {
            setState(() {
              _clusterIconsByCount[count] = icon;
            });
          }
        } catch (e) {
          // Ignore errors, will use default icon
        }
      }
    }
  }

  Future<void> _updateMarkerIcon(
    String venueId,
    String category,
    bool isSelected,
  ) async {
    if (!mounted) return;
    final key = '${category}_${isSelected ? 'selected' : 'unselected'}';

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final useAppleMaps = Platform.isIOS && themeProvider.useAppleMaps;
    if (useAppleMaps) {
      // Get icon from cache (already preloaded)
      final icon = await _markerCache.getAppleMarkerIcon(category, isSelected);
      if (mounted) {
        setState(() {
          _appleMarkerIcons[key] = icon;
        });
      }
    } else {
      // Get icon from cache (already preloaded)
      final icon = await _markerCache.getGoogleMarkerIcon(category, isSelected);
      if (mounted) {
        setState(() {
          _markerIcons[key] = icon;
        });
      }
    }
  }

  /// Handle Apple Map annotation tap - update annotations directly without rebuilding map
  /// This approach swaps icons directly in the annotations Set, preserving camera position
  Future<void> _handleAppleMapAnnotationTap(Venue venue) async {
    if (!mounted) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final useAppleMaps = Platform.isIOS && themeProvider.useAppleMaps;

    if (useAppleMaps) {
      if (mounted) {
        setState(() {
          // Update selected venue ID
          // This will cause _buildAppleMapsAnnotations to be called during rebuild
          // _buildAppleMapsAnnotations reads _selectedVenueId and picks the correct icon (yellow vs white)
          // from the already-loaded category keys in _appleMarkerIcons.
          _selectedVenueId = venue.id;
          
          // Force annotation rebuild immediately
          _appleMapAnnotations = _buildAppleMapsAnnotations();
        });
      }
    }
  }

  Future<void> _animateToVenue(Venue venue) async {
    debugPrint('🎬 _animateToVenue called for ${venue.name} (${venue.lat}, ${venue.lng})');
    if (_isDisposing || !mounted) {
      debugPrint('❌ _animateToVenue aborted: disposed or not mounted');
      return;
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // Check if using Apple Maps on iOS
    if (Platform.isIOS && themeProvider.useAppleMaps) {
      debugPrint('🍎 Using Apple Maps controller');
      final controller = await _getAppleMapController();
      
      if (controller == null) {
        debugPrint('❌ Apple Maps controller is NULL');
        return;
      }
      
      if (!mounted || _isDisposing) return;

      try {
        // Use newLatLng to only change position without affecting zoom
        debugPrint('🚀 Animating camera...');
        await controller.animateCamera(
          apple_maps.CameraUpdate.newLatLng(
            apple_maps.LatLng(venue.lat, venue.lng),
          ),
        );
        debugPrint('✅ Animation accepted by controller');

        // CRITICAL: Re-check after animateCamera await
        if (!mounted || _isDisposing) return;

        // Update current position
        _currentLat = venue.lat;
        _currentLng = venue.lng;
      } on PlatformException catch (e) {
        debugPrint('Suppressed Apple Maps interaction error: $e');
      } catch (e) {
        debugPrint('Error animating to venue in Apple Maps: $e');
      }
    } else {
      // For Google Maps
      debugPrint('🗺️ Using Google Maps controller');
      final controller = await _mapController.future;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLng(gmaps.LatLng(venue.lat, venue.lng)),
      );
      // Update current position
      _currentLat = venue.lat;
      _currentLng = venue.lng;
    }
  }

  Future<void> _openDirections(Venue venue) async {
    try {
      final lat = venue.lat;
      final lng = venue.lng;
      final address = venue.address ?? '';

      Uri url;
      bool launched = false;

      if (Platform.isAndroid) {
        // Android: Try multiple URL schemes
        // 1. Try Google Maps navigation (most common)
        url = Uri.parse('google.navigation:q=$lat,$lng');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
          }
        } catch (e) {
          print('⚠️ Google Maps navigation failed: $e');
        }

        // 2. If that failed, try geo: scheme (opens default map app)
        if (!launched) {
          final query = address.isNotEmpty
              ? Uri.encodeComponent(address)
              : '$lat,$lng';
          url = Uri.parse('geo:$lat,$lng?q=$query');
          try {
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              launched = true;
            }
          } catch (e) {
            print('⚠️ Geo scheme failed: $e');
          }
        }

        // 3. Last resort: use Google Maps web URL
        if (!launched) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        // iOS: Prioritize Google Maps app, then fallback to Apple Maps or web
        // 1. Try Google Maps iOS app first (preferred)
        final googleMapsUrl = Uri.parse(
          'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
        );
        try {
          // Check if Google Maps app is installed
          if (await canLaunchUrl(googleMapsUrl)) {
            await launchUrl(
              googleMapsUrl,
              mode: LaunchMode.externalApplication,
            );
            launched = true;
          } else {
            // Google Maps not installed, try launching anyway (might prompt to install)
            // Or fall through to next option
          }
        } catch (e) {
          // Google Maps app not available, continue to fallback
        }

        // 2. If Google Maps app failed, try Apple Maps
        if (!launched) {
          final appleMapsUrl = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');
          try {
            if (await canLaunchUrl(appleMapsUrl)) {
              await launchUrl(
                appleMapsUrl,
                mode: LaunchMode.externalApplication,
              );
              launched = true;
            }
          } catch (e) {
            // Apple Maps failed, continue to web fallback
          }
        }

        // 3. Last resort: use Google Maps web URL (always works)
        if (!launched) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        // Web or other platforms: use Google Maps web URL
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('⚠️ Error opening directions: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open navigation. Please check if a maps app is installed.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
    "stylers": [{"color": "#ffffff"}]
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
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#e0e0e0"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e8e8e8"}]
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
    "stylers": [{"color": "#e0e0e0"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
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
    "stylers": [{"color": "#e0e0e0"}]
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Use current position if available, otherwise use initial position
    final cameraPosition =
        (_currentLat != null && _currentLng != null && _currentZoom != null)
        ? gmaps.CameraPosition(
            target: gmaps.LatLng(_currentLat!, _currentLng!),
            zoom: _currentZoom!,
          )
        : _initialPosition;

    // Use key to force rebuild when provider changes
    return gmaps.GoogleMap(
      key: ValueKey('google_map_${themeProvider.useAppleMaps}'),
      mapType: gmaps.MapType.normal,
      initialCameraPosition: cameraPosition,
      markers: _markers,
      onMapCreated: (gmaps.GoogleMapController controller) async {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          // If we have a current position, animate to it to preserve camera position
          if (_currentLat != null &&
              _currentLng != null &&
              _currentZoom != null) {
            await controller.animateCamera(
              gmaps.CameraUpdate.newCameraPosition(
                gmaps.CameraPosition(
                  target: gmaps.LatLng(_currentLat!, _currentLng!),
                  zoom: _currentZoom!,
                ),
              ),
            );
          } else {
            _currentZoom = _initialPosition.zoom;
            _currentLat = _initialPosition.target.latitude;
            _currentLng = _initialPosition.target.longitude;
          }
          print('✅ Google Map created successfully');
          print('📍 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
        }
      },
      onTap: (_) {
        if (mounted) {
          setState(() => _selectedVenueId = null);
        }
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMoveStarted: () {
        print('📍 Camera move started');
      },
      onCameraMove: (gmaps.CameraPosition position) {
        final newZoom = position.zoom;
        final roundedZoom = newZoom.round();

        // Update zoom level
        _currentZoom = newZoom;
        _currentLat = position.target.latitude;
        _currentLng = position.target.longitude;

        // Trigger rebuild when zoom changes significantly (for clustering)
        if (roundedZoom != _lastZoomLevel) {
          _lastZoomLevel = roundedZoom;
          if (mounted) {
            setState(() {
              // Trigger rebuild to update clusters
            });
          }
        }
      },
      onCameraIdle: () {
        print('📍 Camera idle - map tiles should be loaded');
      },
      style: themeProvider.useCustomMapStyle ? _getMapStyle(isDark) : null,
    );
  }

  Widget _buildAppleMap() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider.useAppleMaps) {
      // Use native Apple Maps
      // Note: Apple Maps doesn't support custom styling like Google Maps
      // It only supports mapType (standard, satellite, hybrid)
      // Custom map style setting only affects Google Maps
      // Use rebuild key to force complete widget rebuild when icons are loaded

      // Use current position if available, otherwise use initial position
      final cameraPosition =
          (_currentLat != null && _currentLng != null && _currentZoom != null)
          ? apple_maps.CameraPosition(
              target: apple_maps.LatLng(_currentLat!, _currentLng!),
              zoom: _currentZoom!,
            )
          : _initialApplePosition;

      return apple_maps.AppleMap(
        // ONLY rebuild the map if the provider itself changes.
        // Do not include markersReady or rebuildKey here.
        // This prevents destroying/recreating the native view unnecessarily
        key: ValueKey('apple_map_provider_${themeProvider.useAppleMaps}'),
        initialCameraPosition: cameraPosition,
        annotations: _appleMapAnnotations.isEmpty
            ? _buildAppleMapsAnnotations()
            : _appleMapAnnotations,
        onMapCreated: (apple_maps.AppleMapController controller) async {
          // Prevent multiple completions and operations during disposal
          if (_isDisposing || !mounted) {
            return;
          }

          if (!_appleMapController.isCompleted) {
            _appleMapController.complete(controller);

            // Short buffer for native initialization
            await Future.delayed(const Duration(milliseconds: 150));

            if (!mounted || _isDisposing) {
              return;
            }

            // Use setState to update the ready flag (better practice)
            if (mounted && !_isDisposing) {
              setState(() {
                _appleMapControllerReady = true;
              });
              // Try to animate to selected venue now that map is ready
              _tryAnimateToSelectedVenue();
            }

            // If we have a current position, animate to it to preserve camera position
            if (_currentLat != null &&
                _currentLng != null &&
                _currentZoom != null) {
              try {
                // Use the controller directly, not await a new future
                // We use a local variable to ensure the reference doesn't change mid-animation
                await controller.animateCamera(
                  apple_maps.CameraUpdate.newCameraPosition(
                    apple_maps.CameraPosition(
                      target: apple_maps.LatLng(_currentLat!, _currentLng!),
                      zoom: _currentZoom!,
                    ),
                  ),
                );

                // CRITICAL: Re-check after animateCamera await
                if (!mounted || _isDisposing) {
                  return;
                }
              } on PlatformException catch (e) {
                // Suppress "methods called on terminated view" errors
                debugPrint(
                  'PlatformException animating camera (suppressed): ${e.message}',
                );
              } catch (e) {
                debugPrint('Error animating camera on map created: $e');
              }
            } else {
              if (mounted && !_isDisposing) {
                _currentZoom = _initialApplePosition.zoom;
                _currentLat = _initialApplePosition.target.latitude;
                _currentLng = _initialApplePosition.target.longitude;
              }
            }
            if (mounted && !_isDisposing) {
              debugPrint('✅ Native Apple Map created successfully');
            }
          }
        },
        onTap: (apple_maps.LatLng position) {
          // Clear selection when tapping on empty map area
          // Since map onTap fires before annotation onTap, check if tap is near selected annotation first
          if (_isTapNearSelectedAnnotation(position)) {
            // Tap is near the selected annotation - let annotation handler take over
            print('Tap is near selected annotation, skipping map tap handler');
            return;
          }

          // Tap is not near the selected annotation - clear selection
          if (mounted) {
            setState(() {
              print('fire map onTap - clearing selection');
              // Rebuild annotations to show all markers as unselected (white)
              _selectedVenueId = null;
              _appleMapAnnotations = _buildAppleMapsAnnotations();
            });
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
            if (mounted) {
              setState(() => _selectedVenueId = null);
            }
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

    // Add user location marker (blue circle like Google Maps)
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (_showUserLocation &&
        locationProvider.latitude != null &&
        locationProvider.longitude != null) {
      // Use blue circle marker (create if not cached)
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
      final category = venue.category.isNotEmpty ? venue.category : venue.type;
      final iconKey = '${category}_${isSelected ? 'selected' : 'unselected'}';

      // Get cached icon or create a default one
      final icon = _appleMarkerIcons[iconKey];

      // Create a simple default icon if custom icon not available
      final markerIcon = icon ?? apple_maps.BitmapDescriptor.defaultAnnotation;

      // Build annotation with custom icon and onTap handler
      return apple_maps.Annotation(
        annotationId: apple_maps.AnnotationId('${venue.id}_${isSelected ? 's' : 'u'}'),
        position: apple_maps.LatLng(venue.lat, venue.lng),
        icon: markerIcon,
        onTap: () {
          _handleAppleMapAnnotationTap(venue);
        },
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
            if (mounted) {
              setState(() {
                _selectedVenueId = venue.id;
              });
            }
            // Update icons if needed
            if (previousSelected != null && previousSelected != venue.id) {
              final venuesProvider = Provider.of<VenuesProvider>(
                context,
                listen: false,
              );
              final prevVenue = venuesProvider.venues.firstWhere(
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
        final venuesProvider = Provider.of<VenuesProvider>(
          context,
          listen: false,
        );
        selectedVenue = venuesProvider.venues.firstWhere(
          (v) => v.id == _selectedVenueId,
        );
      } catch (e) {
        selectedVenue = null;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map - Must fill entire screen
          Positioned.fill(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                final useAppleMaps =
                    Platform.isIOS && themeProvider.useAppleMaps;
                return useAppleMaps ? _buildAppleMap() : _buildGoogleMap();
              },
            ),
          ),
          // Search & Categories
          Positioned(
            // top: MediaQuery.of(context).padding.top,
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E1E1E) : Colors.white)
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
                        controller: _searchController,
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
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    if (mounted) {
                                      setState(() => _searchQuery = '');
                                    }
                                  },
                                )
                              : null,
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
                        itemCount: Provider.of<VenuesProvider>(
                          context,
                          listen: false,
                        ).categories.length,
                        itemBuilder: (context, index) {
                          final category = Provider.of<VenuesProvider>(
                            context,
                            listen: false,
                          ).categories[index];
                          final isActive = _activeCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  setState(() => _activeCategory = category);
                                }
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
                      300 // Above venue detail card
                : 200, // Default position when no venue selected
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme Toggle (Google Maps with Custom Map Style only) - Above map provider toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    // Only show theme toggle when using Google Maps AND custom map style is enabled
                    if (Platform.isIOS && themeProvider.useAppleMaps) {
                      return const SizedBox.shrink();
                    }
                    if (!themeProvider.useCustomMapStyle) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 12),
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
                          onTap: () => themeProvider.toggleTheme(),
                          borderRadius: BorderRadius.circular(24),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            size: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Map Provider Toggle (iOS only) - Above zoom in button
                if (Platform.isIOS)
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 12),
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
                            onTap: () => themeProvider.toggleMapProvider(),
                            borderRadius: BorderRadius.circular(24),
                            child: themeProvider.useAppleMaps
                                ? Icon(
                                    Icons.apple,
                                    size: 24,
                                    color: isDark ? Colors.white : Colors.black,
                                  )
                                : Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                // Zoom In
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    final useAppleMaps =
                        Platform.isIOS && themeProvider.useAppleMaps;
                    return Container(
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
                          onTap: () async {
                            if (!mounted ||
                                _isDisposing ||
                                !_appleMapControllerReady) {
                              return;
                            }

                            try {
                              if (useAppleMaps) {
                                // Apple Maps - calculate new zoom level
                                final controller =
                                    await _getAppleMapController();

                                // CRITICAL: Re-check after await
                                if (controller == null ||
                                    !mounted ||
                                    _isDisposing) {
                                  return;
                                }

                                final lat =
                                    _currentLat ??
                                    _initialApplePosition.target.latitude;
                                final lng =
                                    _currentLng ??
                                    _initialApplePosition.target.longitude;
                                final currentZoom =
                                    _currentZoom ?? _initialApplePosition.zoom;

                                if (lat.isNaN ||
                                    lng.isNaN ||
                                    currentZoom.isNaN) {
                                  return;
                                }

                                final newZoom = (currentZoom + 1.0).clamp(
                                  3.0,
                                  20.0,
                                );

                                try {
                                  await controller.animateCamera(
                                    apple_maps.CameraUpdate.newCameraPosition(
                                      apple_maps.CameraPosition(
                                        target: apple_maps.LatLng(lat, lng),
                                        zoom: newZoom,
                                      ),
                                    ),
                                  );

                                  // CRITICAL: Re-check after animateCamera await
                                  if (!mounted || _isDisposing) {
                                    return;
                                  }
                                } on PlatformException catch (e) {
                                  // This catches the 'unowned reference' or 'view terminated' exception
                                  // before it bubbles up to a crash
                                  debugPrint(
                                    'Suppressed Apple Maps interaction error: $e',
                                  );
                                  return;
                                } catch (e) {
                                  debugPrint('Error zooming in Apple Maps: $e');
                                  return;
                                }

                                if (mounted && !_isDisposing) {
                                  setState(() {
                                    _currentZoom = newZoom;
                                    _currentLat = lat;
                                    _currentLng = lng;
                                  });
                                }
                              } else {
                                // Google Maps (works on both iOS and Android)
                                if (!_mapController.isCompleted) {
                                  return;
                                }
                                if (!mounted || _isDisposing) return;

                                final controller = await _mapController.future;

                                if (!mounted || _isDisposing) return;

                                await controller.animateCamera(
                                  gmaps.CameraUpdate.zoomIn(),
                                );
                              }
                            } catch (e, stackTrace) {
                              print('Error zooming in: $e');
                              print('Stack trace: $stackTrace');
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Icon(
                            Icons.add,
                            size: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Zoom Out
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    final useAppleMaps =
                        Platform.isIOS && themeProvider.useAppleMaps;
                    return Container(
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
                          onTap: () async {
                            if (!mounted ||
                                _isDisposing ||
                                !_appleMapControllerReady) {
                              return;
                            }

                            try {
                              if (useAppleMaps) {
                                // Apple Maps - calculate new zoom level
                                final controller =
                                    await _getAppleMapController();

                                // CRITICAL: Re-check after await
                                if (controller == null ||
                                    !mounted ||
                                    _isDisposing) {
                                  return;
                                }

                                final lat =
                                    _currentLat ??
                                    _initialApplePosition.target.latitude;
                                final lng =
                                    _currentLng ??
                                    _initialApplePosition.target.longitude;
                                final currentZoom =
                                    _currentZoom ?? _initialApplePosition.zoom;

                                if (lat.isNaN ||
                                    lng.isNaN ||
                                    currentZoom.isNaN) {
                                  return;
                                }

                                final newZoom = (currentZoom - 1.0).clamp(
                                  3.0,
                                  20.0,
                                );

                                try {
                                  await controller.animateCamera(
                                    apple_maps.CameraUpdate.newCameraPosition(
                                      apple_maps.CameraPosition(
                                        target: apple_maps.LatLng(lat, lng),
                                        zoom: newZoom,
                                      ),
                                    ),
                                  );

                                  // CRITICAL: Re-check after animateCamera await
                                  if (!mounted || _isDisposing) {
                                    return;
                                  }
                                } on PlatformException catch (e) {
                                  // This catches the 'unowned reference' or 'view terminated' exception
                                  // before it bubbles up to a crash
                                  debugPrint(
                                    'Suppressed Apple Maps interaction error: $e',
                                  );
                                  return;
                                } catch (e) {
                                  debugPrint(
                                    'Error zooming out Apple Maps: $e',
                                  );
                                  return;
                                }

                                if (mounted && !_isDisposing) {
                                  setState(() {
                                    _currentZoom = newZoom;
                                    _currentLat = lat;
                                    _currentLng = lng;
                                  });
                                }
                              } else {
                                // Google Maps (works on both iOS and Android)
                                if (!_mapController.isCompleted) {
                                  return;
                                }
                                if (!mounted) return;

                                final controller = await _mapController.future;

                                if (!mounted) return;

                                await controller.animateCamera(
                                  gmaps.CameraUpdate.zoomOut(),
                                );
                              }
                            } catch (e, stackTrace) {
                              print('Error zooming out: $e');
                              print('Stack trace: $stackTrace');
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Icon(
                            Icons.remove,
                            size: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
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
                          // Use appropriate map controller based on platform and provider
                          final themeProvider = Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          );
                          final useAppleMaps =
                              Platform.isIOS && themeProvider.useAppleMaps;

                          if (Platform.isIOS) {
                            if (useAppleMaps) {
                              // Show user location marker for Apple Maps (blue circle)
                              if (_blueUserMarkerIcon == null) {
                                _blueUserMarkerIcon = await _markerCache
                                    .getBlueUserMarkerIcon();
                              }
                              if (mounted) {
                                setState(() {
                                  _showUserLocation = true;
                                });
                              }

                              // Use native Apple Maps controller
                              if (!_appleMapControllerReady) {
                                return;
                              }

                              final controller = await _getAppleMapController();

                              // CRITICAL: Re-check after await
                              if (controller == null ||
                                  !mounted ||
                                  _isDisposing) {
                                return;
                              }

                              try {
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

                                // CRITICAL: Re-check after animateCamera await
                                if (!mounted || _isDisposing) {
                                  return;
                                }

                                // Update current position
                                _currentLat = locationProvider.latitude;
                                _currentLng = locationProvider.longitude;
                                _currentZoom = 15;
                              } on PlatformException catch (e) {
                                // This catches the 'unowned reference' or 'view terminated' exception
                                // before it bubbles up to a crash
                                debugPrint(
                                  'Suppressed Apple Maps interaction error: $e',
                                );
                              } catch (e) {
                                debugPrint(
                                  'Error animating to user location in Apple Maps: $e',
                                );
                              }
                            } else {
                              // Use Google Maps controller on iOS
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
                              // Update current position
                              _currentLat = locationProvider.latitude;
                              _currentLng = locationProvider.longitude;
                              _currentZoom = 15;
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
                            // Update current position
                            _currentLat = locationProvider.latitude;
                            _currentLng = locationProvider.longitude;
                            _currentZoom = 15;
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
              bottom: MediaQuery.of(context).padding.bottom + 15,
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
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD00B),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          selectedVenue.discount.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
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
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                                    if (selectedVenue != null) {
                                      _openDirections(selectedVenue);
                                    }
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
                              color:
                                  favoritesProvider.isFavorite(selectedVenue.id)
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
                                  favoritesProvider.isFavorite(selectedVenue.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color:
                                      favoritesProvider.isFavorite(
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
