import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:provider/provider.dart';
import '../../models/venue.dart';
import '../../providers/location_provider.dart';
import '../../utils/marker_cache.dart';
import 'unified_map_controller.dart';

class AppleMapView extends StatefulWidget {
  final List<Venue> venues;
  final String? selectedVenueId;
  final Function(String) onVenueSelected;
  final Function(double lat, double lng, double zoom) onCameraMove;
  final VoidCallback onMapTap;
  final Function(UnifiedMapController) onMapCreated;
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final bool showUserLocation;

  const AppleMapView({
    super.key,
    required this.venues,
    required this.selectedVenueId,
    required this.onVenueSelected,
    required this.onCameraMove,
    required this.onMapTap,
    required this.onMapCreated,
    required this.initialLat,
    required this.initialLng,
    required this.initialZoom,
    this.showUserLocation = false,
  });

  @override
  State<AppleMapView> createState() => _AppleMapViewState();
}

class _AppleMapViewState extends State<AppleMapView>
    implements UnifiedMapController {
  Completer<apple_maps.AppleMapController> _appleMapController =
      Completer<apple_maps.AppleMapController>();

  bool _appleMapControllerReady = false;
  bool _isDisposing = false;

  // Local state for map position to handle the refresh hack
  late double _currentLat;
  late double _currentLng;
  late double _currentZoom;

  // Flags to prevent loops and conflicts
  bool _programmaticMove = false;
  bool _ignoreMapTap = false;

  // Cache for marker icons
  final Map<String, apple_maps.BitmapDescriptor> _appleMarkerIcons = {};
  final MarkerCache _markerCache = MarkerCache();
  apple_maps.BitmapDescriptor? _blueUserMarkerIcon;

  // Annotations set
  Set<apple_maps.Annotation> _appleMapAnnotations = {};

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
    _currentZoom = widget.initialZoom;

    // Load icons initially
    _loadMarkerIcons();
  }

  @override
  void didUpdateWidget(AppleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload icons if venues changed content (not just reference)
    if (!listEquals(widget.venues, oldWidget.venues)) {
      _loadMarkerIcons();
    }

    // Rebuild annotations if selection changed
    if (widget.selectedVenueId != oldWidget.selectedVenueId) {
      _updateAnnotations();
      // If selection changed externally, we might need to animate
      if (widget.selectedVenueId != null &&
          widget.selectedVenueId != oldWidget.selectedVenueId) {
        final venue = widget.venues.firstWhere(
          (v) => v.id == widget.selectedVenueId,
          orElse: () => widget.venues.first,
        );
        // Only animate if it's a valid venue found in the list
        if (widget.venues.contains(venue)) {
          animateTo(venue.lat, venue.lng, _currentZoom);
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _appleMapControllerReady = false;
    if (!_appleMapController.isCompleted) {
      _appleMapController = Completer<apple_maps.AppleMapController>();
    }
    super.dispose();
  }

  // --- UnifiedMapController Implementation ---

  @override
  Future<void> animateTo(double lat, double lng, double zoom) async {
    final controller = await _getAppleMapController();
    if (controller == null) return;

    try {
      _programmaticMove = true;
      await controller.animateCamera(
        apple_maps.CameraUpdate.newCameraPosition(
          apple_maps.CameraPosition(
            target: apple_maps.LatLng(lat, lng),
            zoom: zoom,
          ),
        ),
      );

      if (mounted && !_isDisposing) {
        _currentLat = lat;
        _currentLng = lng;
        _currentZoom = zoom;
        widget.onCameraMove(lat, lng, zoom);
      }
    } catch (e) {
      debugPrint('Error animating Apple Map: $e');
    }
  }

  @override
  Future<void> zoomIn() async {
    final newZoom = (_currentZoom + 1.0).clamp(3.0, 20.0);
    await animateTo(_currentLat, _currentLng, newZoom);
  }

  @override
  Future<void> zoomOut() async {
    final newZoom = (_currentZoom - 1.0).clamp(3.0, 20.0);
    await animateTo(_currentLat, _currentLng, newZoom);
  }

  // --- Internal Helpers ---

  Future<apple_maps.AppleMapController?> _getAppleMapController() async {
    if (_isDisposing || !mounted || !_appleMapControllerReady) return null;
    if (!_appleMapController.isCompleted) return null;

    try {
      final controller = await _appleMapController.future;
      if (_isDisposing || !mounted) return null;
      return controller;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadMarkerIcons() async {
    if (!mounted) return;

    final categories = <String>{};
    for (final venue in widget.venues) {
      categories.add(venue.category.isNotEmpty ? venue.category : venue.type);
    }

    for (final category in categories) {
      try {
        _appleMarkerIcons['${category}_selected'] = await _markerCache
            .getAppleMarkerIcon(category, true);
        _appleMarkerIcons['${category}_unselected'] = await _markerCache
            .getAppleMarkerIcon(category, false);
      } catch (e) {
        debugPrint('Error loading icon for $category: $e');
      }
    }

    if (mounted) {
      _updateAnnotations();
    }
  }

  void _updateAnnotations() {
    if (!mounted) return;

    setState(() {
      _appleMapAnnotations = _buildAppleMapsAnnotations();
    });
  }

  Set<apple_maps.Annotation> _buildAppleMapsAnnotations() {
    final annotations = <apple_maps.Annotation>{};

    // User Location
    if (widget.showUserLocation) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.latitude != null &&
          locationProvider.longitude != null) {
        annotations.add(
          apple_maps.Annotation(
            annotationId: apple_maps.AnnotationId('user_location'),
            position: apple_maps.LatLng(
              locationProvider.latitude!,
              locationProvider.longitude!,
            ),
            icon:
                _blueUserMarkerIcon ??
                apple_maps.BitmapDescriptor.defaultAnnotation,
          ),
        );
      }
    }

    if (widget.venues.isEmpty) return annotations;

    // Venues
    final venueAnnotations = widget.venues.map((venue) {
      final isSelected = widget.selectedVenueId == venue.id;
      final category = venue.category.isNotEmpty ? venue.category : venue.type;
      final iconKey = '${category}_${isSelected ? 'selected' : 'unselected'}';

      final icon =
          _appleMarkerIcons[iconKey] ??
          apple_maps.BitmapDescriptor.defaultAnnotation;

      // ID Trick: Append selection state to force redraw
      final annotationId = '${venue.id}_${isSelected ? 'sel' : 'unsel'}';

      return apple_maps.Annotation(
        annotationId: apple_maps.AnnotationId(annotationId),
        position: apple_maps.LatLng(venue.lat, venue.lng),
        icon: icon,
        onTap: () => _handleAnnotationTap(venue),
      );
    }).toSet();

    annotations.addAll(venueAnnotations);
    return annotations;
  }

  Future<void> _handleAnnotationTap(Venue venue) async {
    if (!mounted) return;

    // Use a flag to prevent map onTap from firing immediately after and clearing selection
    // Apple Maps sometimes fires map onTap after annotation onTap
    _ignoreMapTap = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ignoreMapTap = false;
    });

    // 1. Notify parent
    widget.onVenueSelected(venue.id);

    // 2. Animate to venue (using newLatLng to keep zoom)
    final controller = await _getAppleMapController();
    if (controller != null) {
      try {
        _programmaticMove = true;
        await controller.animateCamera(
          apple_maps.CameraUpdate.newLatLng(
            apple_maps.LatLng(venue.lat, venue.lng),
          ),
        );
        _currentLat = venue.lat;
        _currentLng = venue.lng;
      } catch (_) {}
    }

    // 3. Force refresh (The Hack)
    await _refreshMap();
  }

  Future<void> _refreshMap() async {
    if (!mounted || _isDisposing || !_appleMapControllerReady) return;

    // Avoid infinite loops if this refresh triggers onCameraIdle which triggers refresh
    if (_programmaticMove) return;

    final controller = await _getAppleMapController();
    if (controller == null) return;

    // Use current position derived from visible region to avoid tracking onCameraMove
    try {
      double lat = _currentLat;
      double lng = _currentLng;

      // Try to get more accurate center from visible region if possible
      try {
        final bounds = await controller.getVisibleRegion();
        lat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        lng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      } catch (_) {
        // Fallback to last known position
      }

      const double tinyOffset = 0.0000001;
      _programmaticMove = true;
      // Use moveCamera instead of animateCamera for the hack
      // This is instant and shouldn't block user interaction
      await controller.moveCamera(
        apple_maps.CameraUpdate.newLatLng(
          apple_maps.LatLng(lat + tinyOffset, lng + tinyOffset),
        ),
      );
      if (mounted) {
        _currentLat = lat + tinyOffset;
        _currentLng = lng + tinyOffset;
      }
    } catch (_) {
      // If error occurs, reset flag
      _programmaticMove = false;
    }
  }

  /// Synchronous check using distance threshold
  /// This is robust against race conditions between map tap and annotation tap
  bool _isTapNearSelectedAnnotation(apple_maps.LatLng tapPosition) {
    if (widget.selectedVenueId == null) return false;

    try {
      final selectedVenue = widget.venues.firstWhere(
        (v) => v.id == widget.selectedVenueId,
      );

      final latDiff = (tapPosition.latitude - selectedVenue.lat).abs();
      final lngDiff = (tapPosition.longitude - selectedVenue.lng).abs();

      // Threshold distance in degrees (approx 100-200m depending on zoom)
      // Tuned to cover the marker hit area
      const double threshold = 0.0001;

      return latDiff < threshold && lngDiff < threshold;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return apple_maps.AppleMap(
      key: ValueKey('apple_map_view'),
      initialCameraPosition: apple_maps.CameraPosition(
        target: apple_maps.LatLng(widget.initialLat, widget.initialLng),
        zoom: widget.initialZoom,
      ),
      annotations: _appleMapAnnotations,
      onMapCreated: (controller) async {
        if (_isDisposing || !mounted) return;
        if (!_appleMapController.isCompleted) {
          _appleMapController.complete(controller);

          // Pass THIS controller wrapper back to parent
          widget.onMapCreated(this);

          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted && !_isDisposing) {
            setState(() {
              _appleMapControllerReady = true;
            });
          }
        }
      },
      // Removed onCameraMove to improve drag performance
      // Removed onCameraIdle to fix kinetic scrolling issues
      onTap: (position) {
        // If we recently tapped a marker, ignore map taps (race condition fix)
        if (_ignoreMapTap) return;

        // Check if tap is near the selected annotation
        if (_isTapNearSelectedAnnotation(position)) {
          return;
        }

        widget.onMapTap();
        // Also refresh map to clear selection visually if needed
        _refreshMap();
      },
    );
  }
}
