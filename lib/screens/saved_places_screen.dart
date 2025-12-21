import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/geo_utils.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _apiService = ApiService();
  List<Venue> _savedVenues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favoriteVenues = await _apiService.getFavorites();
      setState(() {
        _savedVenues = favoriteVenues;
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Saved Places',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Content
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
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              _fetchFavorites();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _savedVenues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_border,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved places yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/discover'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD00B),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Discover Venues'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedVenues.length,
                      itemBuilder: (context, index) {
                        final venue = _savedVenues[index];
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

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          child: InkWell(
                            onTap: () => context.go('/venue/${venue.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: venue.image,
                                        height: 192,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              height: 192,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.favorite,
                                          color: Color(0xFFFFD00B),
                                        ),
                                        onPressed: () {
                                          favoritesProvider.toggleFavorite(
                                            venue.id,
                                          );
                                          _fetchFavorites();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${venue.type} • ${venue.priceLevel}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
