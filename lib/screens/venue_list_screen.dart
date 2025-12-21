import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../services/api_service.dart';
import '../utils/geo_utils.dart';
import '../utils/category_icons.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({super.key});

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();

  String _activeCategory = 'All';
  String _searchQuery = '';
  bool _sortByDistance = false;
  List<Venue> _venues = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Fetch categories
      final apiCategories = await _apiService.getCategories();
      final categoryNames = ['All', ...apiCategories.map((cat) => cat.name)];

      // Fetch venues grouped by category
      final groupedVenues = await _apiService.getVenuesGrouped(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        lat: locationProvider.latitude,
        lng: locationProvider.longitude,
        sortBy: _sortByDistance ? 'distance' : 'name',
      );

      // Flatten grouped venues
      final allVenues = <Venue>[];
      for (final group in groupedVenues) {
        final venues = group['venues'] as List;
        for (final venueJson in venues) {
          allVenues.add(Venue.fromJson(venueJson as Map<String, dynamic>));
        }
      }

      setState(() {
        _categories = categoryNames;
        _venues = allVenues;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Venue> get _filteredVenues {
    var filtered = _venues.where((venue) {
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Participating Venues',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _fetchData();
                },
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      backgroundColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      selectedColor: const Color(0xFFFFD00B),
                      labelStyle: TextStyle(
                        color: isActive ? Colors.black : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Venues List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD00B),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredVenues.isEmpty
                  ? Center(
                      child: Text(
                        'No venues found',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
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

                        return _VenueCard(venue: venue, distance: distance);
                      },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: () => context.go('/venue/${venue.id}'),
        borderRadius: BorderRadius.circular(16),
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
                  CachedNetworkImage(
                    imageUrl: venue.image,
                    height: 192,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 192,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 192,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  ),
                  if (venue.isPartner)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD00B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PARTNER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        venue.discount,
                        style: const TextStyle(
                          color: Color(0xFFFFD00B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${venue.type} • ${venue.priceLevel} • ${venue.category}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
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
                            venue.rating.toString(),
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
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
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
