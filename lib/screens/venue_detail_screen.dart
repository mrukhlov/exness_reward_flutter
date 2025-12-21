import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/geo_utils.dart';

class VenueDetailScreen extends StatefulWidget {
  final String venueId;

  const VenueDetailScreen({super.key, required this.venueId});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final _apiService = ApiService();
  Venue? _venue;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVenue();
  }

  Future<void> _fetchVenue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      final venue = await _apiService.getVenue(
        widget.venueId,
        lat: locationProvider.latitude,
        lng: locationProvider.longitude,
      );

      setState(() {
        _venue = venue;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationProvider = Provider.of<LocationProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD00B)),
        ),
      );
    }

    if (_error != null || _venue == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Venue not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final venue = _venue!;
    final distance =
        locationProvider.latitude != null && locationProvider.longitude != null
        ? calculateDistance(
            locationProvider.latitude!,
            locationProvider.longitude!,
            venue.lat,
            venue.lng,
          )
        : venue.distance;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: venue.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 64),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? Colors.black : const Color(0xFFF9FAFB),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: favoritesProvider.isFavorite(venue.id)
                        ? const Color(0xFFFFD00B)
                        : Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    favoritesProvider.isFavorite(venue.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: favoritesProvider.isFavorite(venue.id)
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
                onPressed: () => favoritesProvider.toggleFavorite(venue.id),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD00B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      venue.discount,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Type & Distance
                  Row(
                    children: [
                      Text(
                        venue.type,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      Text(
                        venue.priceLevel,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const Icon(Icons.near_me, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 20,
                        color: Color(0xFFFFD00B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        venue.rating.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        ' (${venue.reviews} reviews)',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  if (venue.description != null) ...[
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      venue.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Address
                  if (venue.address != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, color: Color(0xFFFFD00B)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                venue.address!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Contact Info
                  if (venue.phone != null || venue.website != null) ...[
                    if (venue.phone != null)
                      ListTile(
                        leading: const Icon(
                          Icons.phone,
                          color: Color(0xFFFFD00B),
                        ),
                        title: const Text('Phone'),
                        subtitle: Text(venue.phone!),
                      ),
                    if (venue.website != null)
                      ListTile(
                        leading: const Icon(
                          Icons.language,
                          color: Color(0xFFFFD00B),
                        ),
                        title: const Text('Website'),
                        subtitle: Text(venue.website!),
                      ),
                  ],
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open in maps
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD00B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }
}
