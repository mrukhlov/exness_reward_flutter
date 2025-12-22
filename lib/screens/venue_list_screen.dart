import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/venues_provider.dart';
import '../utils/geo_utils.dart';
import '../utils/category_icons.dart';

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
      return _activeCategory == 'All' || venue.category == _activeCategory;
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
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252525) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _fetchData(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search venues or cuisines...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchData();
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
                  ),
                  // Category Chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: venuesProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = venuesProvider.categories[index];
                        final isActive = _activeCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeCategory = category);
                            },
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFFFD00B)
                                    : (isDark
                                          ? const Color(0xFF252525)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(18),
                                border: isActive
                                    ? null
                                    : Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey.shade200,
                                      ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getCategoryIcon(category),
                                    size: 18,
                                    color: isActive
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isActive
                                          ? Colors.black
                                          : (isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade600),
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

                                return _VenueCard(
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

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final String distance;

  const _VenueCard({required this.venue, required this.distance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/venue/${venue.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 192,
                    child: CachedNetworkImage(
                      imageUrl: venue.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 192,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD00B),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 192,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 64),
                      ),
                    ),
                  ),
                  if (venue.isPartner)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD00B),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'PARTNER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount and Distance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        venue.discount,
                        style: const TextStyle(
                          color: Color(0xFFFFD00B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Venue Name
                  Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Type • Price Level • Category
                  Text(
                    '${venue.type} • ${venue.priceLevel} • ${venue.category}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade100,
                  ),
                  const SizedBox(height: 12),
                  // Rating and View Details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFD00B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            ' (${venue.reviews})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
