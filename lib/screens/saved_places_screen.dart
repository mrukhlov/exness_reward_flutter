import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/api_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/saved_places/saved_places_header.dart';
import '../widgets/saved_places/saved_places_empty_state.dart';
import '../widgets/saved_places/saved_places_list_item.dart';

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
            const SavedPlacesHeader(),
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
                  ? const SavedPlacesEmptyState()
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

                        return SavedPlacesListItem(
                          venue: venue,
                          distance: distance,
                          onToggleFavorite: () {
                            favoritesProvider.toggleFavorite(venue.id);
                            _fetchFavorites();
                          },
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
