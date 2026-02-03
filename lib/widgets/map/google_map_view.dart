import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:provider/provider.dart';
import '../../models/venue.dart';
import '../../utils/marker_cache.dart';
import '../../utils/clustering_helper.dart';
import '../../providers/theme_provider.dart';
import 'unified_map_controller.dart';

class GoogleMapView extends StatefulWidget {
  final List<Venue> venues;
  final String? selectedVenueId;
  final Function(String) onVenueSelected;
  final Function(double lat, double lng, double zoom) onCameraMove;
  final VoidCallback onMapTap;
  final Function(UnifiedMapController) onMapCreated;
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final bool isDark;

  const GoogleMapView({
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
    required this.isDark,
  });

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView>
    implements UnifiedMapController {
  final Completer<gmaps.GoogleMapController> _mapController = Completer();

  // Local state
  late double _currentLat;
  late double _currentLng;
  late double _currentZoom;
  int _lastZoomLevel = 0;

  // Caches
  final Map<String, gmaps.BitmapDescriptor> _markerIcons = {};
  final Map<int, gmaps.BitmapDescriptor> _clusterIconsByCount = {};
  final MarkerCache _markerCache = MarkerCache();
  bool _markersReady = false;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
    _currentZoom = widget.initialZoom;
    _lastZoomLevel = widget.initialZoom.round();

    _loadMarkerIcons();
    _preloadClusterIcons();
  }

  @override
  void didUpdateWidget(GoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.venues != oldWidget.venues) {
      _loadMarkerIcons();
    }
  }

  // --- UnifiedMapController Implementation ---

  @override
  Future<void> animateTo(double lat, double lng, double zoom) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: gmaps.LatLng(lat, lng), zoom: zoom),
      ),
    );
  }

  @override
  Future<void> zoomIn() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(gmaps.CameraUpdate.zoomIn());
  }

  @override
  Future<void> zoomOut() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(gmaps.CameraUpdate.zoomOut());
  }

  // --- Internal Helpers ---

  Future<void> _loadMarkerIcons() async {
    if (!mounted) return;

    final categories = <String>{};
    for (final venue in widget.venues) {
      categories.add(venue.category.isNotEmpty ? venue.category : venue.type);
    }

    for (final category in categories) {
      try {
        _markerIcons['${category}_selected'] = await _markerCache
            .getGoogleMarkerIcon(category, true);
        _markerIcons['${category}_unselected'] = await _markerCache
            .getGoogleMarkerIcon(category, false);
      } catch (e) {
        debugPrint('Error loading icon for $category: $e');
      }
    }

    if (mounted) {
      setState(() {
        _markersReady = true;
      });
    }
  }

  Future<void> _preloadClusterIcons() async {
    for (int count = 2; count <= 50; count++) {
      if (!_clusterIconsByCount.containsKey(count)) {
        try {
          final icon = await ClusteringHelper.createClusterIcon(count);
          if (mounted) {
            setState(() {
              _clusterIconsByCount[count] = icon;
            });
          }
        } catch (_) {}
      }
    }
  }

  gmaps.BitmapDescriptor _getClusterIcon(int count) {
    return _clusterIconsByCount[count] ??
        gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueYellow,
        );
  }

  Set<gmaps.Marker> _buildMarkers() {
    final markers = <gmaps.Marker>{};
    if (!_markersReady) return markers;

    final clusters = ClusteringHelper.createClusters(
      widget.venues,
      _currentZoom,
    );

    for (final cluster in clusters) {
      if (cluster.count == 1) {
        final venue = cluster.venues.first;
        final isSelected = widget.selectedVenueId == venue.id;
        final category = venue.category.isNotEmpty
            ? venue.category
            : venue.type;
        final iconKey = '${category}_${isSelected ? 'selected' : 'unselected'}';

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
            onTap: () {
              widget.onVenueSelected(venue.id);
              animateTo(venue.lat, venue.lng, _currentZoom);
            },
          ),
        );
      } else {
        // Cluster
        final clusterId =
            'cluster_${cluster.lat}_${cluster.lng}_${cluster.count}';
        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId(clusterId),
            position: gmaps.LatLng(cluster.lat, cluster.lng),
            icon: _getClusterIcon(cluster.count),
            zIndexInt: 5,
            onTap: () async {
              final targetZoom = (_currentZoom + 2.0).clamp(10.0, 18.0);
              await animateTo(cluster.lat, cluster.lng, targetZoom);
            },
          ),
        );
      }
    }
    return markers;
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return gmaps.GoogleMap(
      key: ValueKey('google_map_view'),
      mapType: gmaps.MapType.normal,
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.initialLat, widget.initialLng),
        zoom: widget.initialZoom,
      ),
      markers: _buildMarkers(),
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          widget.onMapCreated(this);
        }
      },
      onTap: (_) => widget.onMapTap(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onCameraMove: (position) {
        _currentLat = position.target.latitude;
        _currentLng = position.target.longitude;
        _currentZoom = position.zoom;

        widget.onCameraMove(_currentLat, _currentLng, _currentZoom);

        final roundedZoom = _currentZoom.round();
        if (roundedZoom != _lastZoomLevel) {
          _lastZoomLevel = roundedZoom;
          if (mounted) setState(() {}); // Rebuild for clustering
        }
      },
      style: themeProvider.useCustomMapStyle
          ? _getMapStyle(widget.isDark)
          : null,
    );
  }
}
