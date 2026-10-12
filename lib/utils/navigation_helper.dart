import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/venue.dart';
import 'app_platform.dart';

class NavigationHelper {
  static Future<void> openDirections(BuildContext context, Venue venue) async {
    try {
      final lat = venue.lat;
      final lng = venue.lng;
      final address = venue.address ?? '';

      Uri url;
      bool launched = false;

      if (AppPlatform.isAndroid) {
        // Android: Try multiple URL schemes
        // 1. Try Google Maps navigation (most common)
        url = Uri.parse('google.navigation:q=$lat,$lng');
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            launched = true;
          }
        } catch (e) {
          debugPrint('⚠️ Google Maps navigation failed: $e');
        }

        // 2. If that failed, try geo: scheme (opens default map app)
        if (!launched) {
          final query = address.isNotEmpty
              ? Uri.encodeComponent(address)
              : '$lat,$lng';
          url = Uri.parse('geo:$lat,$lng?q=$query');
          try {
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              launched = true;
            }
          } catch (e) {
            debugPrint('⚠️ Geo scheme failed: $e');
          }
        }

        // 3. Last resort: use Google Maps web URL
        if (!launched) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (AppPlatform.isIOS) {
        // iOS: Prioritize Google Maps app, then fallback to Apple Maps or web
        // 1. Try Google Maps iOS app first (preferred)
        final googleMapsUrl = Uri.parse(
          'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
        );
        try {
          // Check if Google Maps app is installed
          if (await canLaunchUrl(googleMapsUrl)) {
            await launchUrl(
              googleMapsUrl,
              mode: LaunchMode.externalApplication,
            );
            launched = true;
          }
        } catch (e) {
          // Google Maps app not available, continue to fallback
        }

        // 2. If Google Maps app failed, try Apple Maps
        if (!launched) {
          final appleMapsUrl = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');
          try {
            if (await canLaunchUrl(appleMapsUrl)) {
              await launchUrl(
                appleMapsUrl,
                mode: LaunchMode.externalApplication,
              );
              launched = true;
            }
          } catch (e) {
            // Apple Maps failed, continue to web fallback
          }
        }

        // 3. Last resort: use Google Maps web URL (always works)
        if (!launched) {
          url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
          );
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        // Web or other platforms: use Google Maps web URL
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ Error opening directions: $e');
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open navigation. Please check if a maps app is installed.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
