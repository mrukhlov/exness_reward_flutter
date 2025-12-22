import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'marker_helper.dart';

/// Global cache for marker icons
/// Prevents reloading markers every time the map screen is opened
class MarkerCache {
  static final MarkerCache _instance = MarkerCache._internal();
  factory MarkerCache() => _instance;
  MarkerCache._internal();

  // Cache for Google Maps markers by category
  final Map<String, gmaps.BitmapDescriptor> _googleMarkersSelected = {};
  final Map<String, gmaps.BitmapDescriptor> _googleMarkersUnselected = {};

  // Cache for Apple Maps markers by category
  final Map<String, apple_maps.BitmapDescriptor> _appleMarkersSelected = {};
  final Map<String, apple_maps.BitmapDescriptor> _appleMarkersUnselected = {};

  // Cache for blue user location marker
  apple_maps.BitmapDescriptor? _blueUserMarkerIcon;

  bool _isPreloaded = false;

  /// Preload markers for all categories
  /// Should be called once when categories are fetched
  Future<void> preloadMarkers(List<String> categories) async {
    if (_isPreloaded) return;

    try {
      // Preload Google Maps markers
      for (final category in categories) {
        if (!_googleMarkersSelected.containsKey(category)) {
          _googleMarkersSelected[category] = await createCustomMarkerIcon(
            category: category,
            isSelected: true,
          );
        }
        if (!_googleMarkersUnselected.containsKey(category)) {
          _googleMarkersUnselected[category] = await createCustomMarkerIcon(
            category: category,
            isSelected: false,
          );
        }
      }

      // Preload Apple Maps markers
      for (final category in categories) {
        if (!_appleMarkersSelected.containsKey(category)) {
          _appleMarkersSelected[category] = await createCustomAppleMarkerIcon(
            category: category,
            isSelected: true,
          );
        }
        if (!_appleMarkersUnselected.containsKey(category)) {
          _appleMarkersUnselected[category] = await createCustomAppleMarkerIcon(
            category: category,
            isSelected: false,
          );
        }
      }

      _isPreloaded = true;
    } catch (e) {
      // If preloading fails, markers will be created on-demand
      print('Error preloading markers: $e');
    }
  }

  /// Get Google Maps marker icon for a category
  /// Creates it if not cached
  Future<gmaps.BitmapDescriptor> getGoogleMarkerIcon(
    String category,
    bool isSelected,
  ) async {
    final cache = isSelected ? _googleMarkersSelected : _googleMarkersUnselected;
    
    if (cache.containsKey(category)) {
      return cache[category]!;
    }

    // Create and cache if not found
    final icon = await createCustomMarkerIcon(
      category: category,
      isSelected: isSelected,
    );
    cache[category] = icon;
    return icon;
  }

  /// Get Apple Maps marker icon for a category
  /// Creates it if not cached
  Future<apple_maps.BitmapDescriptor> getAppleMarkerIcon(
    String category,
    bool isSelected,
  ) async {
    final cache = isSelected ? _appleMarkersSelected : _appleMarkersUnselected;
    
    if (cache.containsKey(category)) {
      return cache[category]!;
    }

    // Create and cache if not found
    final icon = await createCustomAppleMarkerIcon(
      category: category,
      isSelected: isSelected,
    );
    cache[category] = icon;
    return icon;
  }

  /// Get blue user location marker for Apple Maps
  Future<apple_maps.BitmapDescriptor> getBlueUserMarkerIcon() async {
    if (_blueUserMarkerIcon != null) {
      return _blueUserMarkerIcon!;
    }

    _blueUserMarkerIcon = await createBlueUserLocationMarker();
    return _blueUserMarkerIcon!;
  }

  /// Clear the cache (useful for testing or memory management)
  void clear() {
    _googleMarkersSelected.clear();
    _googleMarkersUnselected.clear();
    _appleMarkersSelected.clear();
    _appleMarkersUnselected.clear();
    _blueUserMarkerIcon = null;
    _isPreloaded = false;
  }

  /// Check if markers are preloaded
  bool get isPreloaded => _isPreloaded;
}

