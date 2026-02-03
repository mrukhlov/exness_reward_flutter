import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/venues_provider.dart';
import '../utils/geo_utils.dart';
import '../widgets/venue_list/venue_list_item.dart';
import '../widgets/venue_list/venue_filters.dart';
import '../widgets/venue_list/venue_search_bar.dart';
import '../widgets/venue_list/venue_category_filter.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final _searchController = TextEditingController();

  String _activeCategory = 'All';
  String _searchQuery = '';
  bool _sortByDistance = false;

  // Filter state
  bool _showFilters = false;
  String? _selectedPriceLevel;
  double _minRating = 0.0;
  bool _openNowOnly = false;
  bool _partnerOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _fetchData();
    });
    // Defer fetchData to after build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);

    await venuesProvider.fetchVenuesGrouped(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      lat: locationProvider.latitude,
      lng: locationProvider.longitude,
      sortBy: _sortByDistance ? 'distance' : 'name',
      forceRefresh: forceRefresh,
    );
  }

  List<Venue> get _filteredVenues {
    final venuesProvider = Provider.of<VenuesProvider>(context, listen: false);
    var filtered = venuesProvider.venues.where((venue) {
      // Category filter
      final matchesCategory =
          _activeCategory == 'All' || venue.category == _activeCategory;

      // Search filter
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          venue.name.toLowerCase().contains(query) ||
          venue.category.toLowerCase().contains(query) ||
          (venue.address?.toLowerCase().contains(query) ?? false) ||
          venue.type.toLowerCase().contains(query);

      // Price level filter
      final matchesPrice =
          _selectedPriceLevel == null ||
          venue.priceLevel == _selectedPriceLevel;

      // Rating filter
      final matchesRating = venue.rating >= _minRating;

      // Open now filter
      final matchesOpen = !_openNowOnly || venue.isOpen;

      // Partner filter
      final matchesPartner = !_partnerOnly || venue.isPartner;

      return matchesCategory &&
          matchesSearch &&
          matchesPrice &&
          matchesRating &&
          matchesOpen &&
          matchesPartner;
    }).toList();

    if (_sortByDistance) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      if (locationProvider.latitude != null &&
          locationProvider.longitude != null) {
        filtered.sort((a, b) {
          final distA = getDistanceKm(
            locationProvider.latitude!,
            locationProvider.longitude!,
            a.lat,
            a.lng,
          );
          final distB = getDistanceKm(
            locationProvider.latitude!,
            locationProvider.longitude!,
            b.lat,
            b.lng,
          );
          return distA.compareTo(distB);
        });
      }
    }

    return filtered;
  }

  bool get _hasActiveFilters {
    return _selectedPriceLevel != null ||
        _minRating > 0.0 ||
        _openNowOnly ||
        _partnerOnly;
  }

  void _resetFilters() {
    setState(() {
      _selectedPriceLevel = null;
      _minRating = 0.0;
      _openNowOnly = false;
      _partnerOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationProvider = Provider.of<LocationProvider>(context);
    final venuesProvider = Provider.of<VenuesProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _sortByDistance = !_sortByDistance);
                      _fetchData();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _sortByDistance
                            ? const Color(0xFFFFD00B)
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.near_me,
                        color: _sortByDistance
                            ? Colors.black
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Participating Venues',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/map'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.map,
                        color: Color(0xFFFFD00B),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search & Filters Section
            Container(
              color: isDark ? Colors.black : const Color(0xFFF9FAFB),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  VenueSearchBar(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    hasActiveFilters: _hasActiveFilters,
                    onFilterTap: () =>
                        setState(() => _showFilters = !_showFilters),
                    onClear: () {
                      _searchController.clear();
                      _fetchData();
                    },
                    onChanged: (_) => _fetchData(),
                  ),
                  if (_showFilters)
                    VenueFilters(
                      selectedPriceLevel: _selectedPriceLevel,
                      minRating: _minRating,
                      openNowOnly: _openNowOnly,
                      partnerOnly: _partnerOnly,
                      onPriceLevelChanged: (val) =>
                          setState(() => _selectedPriceLevel = val),
                      onRatingChanged: (val) =>
                          setState(() => _minRating = val),
                      onOpenNowChanged: (val) =>
                          setState(() => _openNowOnly = val),
                      onPartnerChanged: (val) =>
                          setState(() => _partnerOnly = val),
                      onReset: _resetFilters,
                    ),
                  VenueCategoryFilter(
                    categories: venuesProvider.categories,
                    activeCategory: _activeCategory,
                    onCategorySelected: (category) {
                      setState(() => _activeCategory = category);
                    },
                  ),
                ],
              ),
            ),
            // Venues List
            Expanded(
              child: venuesProvider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFFFFD00B),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading venues...',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : venuesProvider.error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              venuesProvider.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                _fetchData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD00B),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchData(forceRefresh: true);
                      },
                      color: const Color(0xFFFFD00B),
                      child: _filteredVenues.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No venues found',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVenues.length,
                              itemBuilder: (context, index) {
                                final venue = _filteredVenues[index];
                                final distance =
                                    locationProvider.latitude != null &&
                                        locationProvider.longitude != null
                                    ? calculateDistance(
                                        locationProvider.latitude!,
                                        locationProvider.longitude!,
                                        venue.lat,
                                        venue.lng,
                                      )
                                    : venue.distance;

                                return VenueListItem(
                                  venue: venue,
                                  distance: distance,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
