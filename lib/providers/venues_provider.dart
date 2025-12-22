import 'package:flutter/foundation.dart';
import '../models/venue.dart';
import '../services/api_service.dart';
import '../utils/marker_cache.dart';

class VenuesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MarkerCache _markerCache = MarkerCache();

  List<Venue> _venues = [];
  List<String> _categories = ['All'];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  List<Venue> get venues => _venues;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasVenues => _venues.isNotEmpty;
  bool get isStale {
    if (_lastFetchTime == null) return true;
    // Consider data stale after 5 minutes
    return DateTime.now().difference(_lastFetchTime!).inMinutes > 5;
  }

  /// Fetch venues and categories, and preload markers
  Future<void> fetchVenues({
    String? search,
    double? lat,
    double? lng,
    bool forceRefresh = false,
  }) async {
    // Don't fetch if data is fresh and not forcing refresh
    if (!forceRefresh && !isStale && hasVenues) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch categories first
      final apiCategories = await _apiService.getCategories();
      final categoryNames = ['All', ...apiCategories.map((cat) => cat.name)];

      // Preload markers for all categories (only once)
      if (!_markerCache.isPreloaded) {
        await _markerCache.preloadMarkers(
          apiCategories.map((cat) => cat.name).toList(),
        );
      }

      // Fetch venues
      final apiVenues = await _apiService.getVenues(
        search: search,
        lat: lat,
        lng: lng,
      );

      _venues = apiVenues;
      _categories = categoryNames;
      _lastFetchTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch venues grouped by category (for venue list screen)
  Future<void> fetchVenuesGrouped({
    String? search,
    double? lat,
    double? lng,
    String sortBy = 'name',
    bool forceRefresh = false,
  }) async {
    // Don't fetch if data is fresh and not forcing refresh
    if (!forceRefresh && !isStale && hasVenues) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch categories first
      final apiCategories = await _apiService.getCategories();
      final categoryNames = ['All', ...apiCategories.map((cat) => cat.name)];

      // Preload markers for all categories (only once)
      if (!_markerCache.isPreloaded) {
        await _markerCache.preloadMarkers(
          apiCategories.map((cat) => cat.name).toList(),
        );
      }

      // Fetch venues grouped by category
      final groupedVenues = await _apiService.getVenuesGrouped(
        search: search,
        lat: lat,
        lng: lng,
        sortBy: sortBy,
      );

      // Flatten grouped venues
      final allVenues = <Venue>[];
      for (final group in groupedVenues) {
        final venuesList = group['venues'] as List<dynamic>?;
        if (venuesList != null) {
          for (final venueJson in venuesList) {
            allVenues.add(Venue.fromJson(venueJson as Map<String, dynamic>));
          }
        }
      }

      _venues = allVenues;
      _categories = categoryNames;
      _lastFetchTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear venues data
  void clear() {
    _venues = [];
    _categories = ['All'];
    _error = null;
    _lastFetchTime = null;
    notifyListeners();
  }
}

