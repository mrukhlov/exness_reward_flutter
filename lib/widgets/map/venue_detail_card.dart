import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/venue.dart';
import '../../providers/location_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/geo_utils.dart';
import '../../utils/navigation_helper.dart';

class VenueDetailCard extends StatelessWidget {
  final Venue venue;
  final bool isDark;

  const VenueDetailCard({super.key, required this.venue, required this.isDark});

  String _getVenueDistance(BuildContext context) {
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
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return GestureDetector(
      onTap: () {
        context.push('/venue/${venue.id}');
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
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                venue.discount.toUpperCase(),
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
                              venue.isOpen ? 'Open now' : 'Closed',
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
                        venue.name,
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
                        '${venue.type} • ${_getVenueDistance(context)} away',
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
                            venue.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${venue.reviews})',
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
                    imageUrl: venue.image,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 96,
                      height: 96,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                          NavigationHelper.openDirections(context, venue);
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
                    color: favoritesProvider.isFavorite(venue.id)
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
                        favoritesProvider.toggleFavorite(venue.id);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        favoritesProvider.isFavorite(venue.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: favoritesProvider.isFavorite(venue.id)
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
    );
  }
}
