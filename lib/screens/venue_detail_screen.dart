import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/venue.dart';
import '../providers/location_provider.dart';
import '../services/api_service.dart';
import '../widgets/venue_detail/venue_hero_image.dart';
import '../widgets/venue_detail/venue_header_buttons.dart';
import '../widgets/venue_detail/venue_title_section.dart';
import '../widgets/venue_detail/venue_exclusive_offer.dart';
import '../widgets/venue_detail/venue_contact_info.dart';
import '../widgets/venue_detail/venue_about_comments_section.dart';
import '../widgets/venue_detail/venue_action_buttons.dart';

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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFFD00B)),
              const SizedBox(height: 16),
              Text(
                'Loading venue...',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _venue == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Venue not found',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/discover');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD00B),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final venue = _venue!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                VenueHeroImage(imageUrl: venue.image, isDark: isDark),
                Transform.translate(
                  offset: const Offset(0, -64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VenueTitleSection(venue: venue, isDark: isDark),
                        const SizedBox(height: 32),
                        VenueExclusiveOffer(venue: venue, isDark: isDark),
                        const SizedBox(height: 24),
                        VenueContactInfo(venue: venue, isDark: isDark),
                        const SizedBox(height: 24),
                        VenueAboutCommentsSection(venue: venue, isDark: isDark),
                        const SizedBox(height: 24),
                        VenueActionButtons(venueId: venue.id),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          VenueHeaderButtons(venueId: venue.id),
        ],
      ),
    );
  }
}
