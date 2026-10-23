import 'package:flutter/foundation.dart' show kIsWeb;

/// API Configuration
///
/// Web (production): same-origin `/api` — works for https://rewards.myexlab.com/app
/// and http://217.217.227.183/app without mixed-content issues.
///
/// Mobile default: https://rewards.myexlab.com/api
///
/// Local dev override:
///   flutter run --dart-define=API_URL=http://localhost:8000
class ApiConfig {
  static const String _apiUrlFromEnvironment = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_apiUrlFromEnvironment.isNotEmpty) {
      return _apiUrlFromEnvironment;
    }
    if (kIsWeb) {
      return '/api';
    }
    return 'https://rewards.myexlab.com/api';
  }

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String invite = '/invite';
  static const String myInvites = '/invite';
  static String revokeInvite(String inviteId) => '/invite/$inviteId';
  static const String venues = '/venues';
  static const String venuesCategories = '/venues/categories';
  static const String venuesGrouped = '/venues/grouped';
  static const String favorites = '/users/favorites';
  static const String events = '/events';
  static const String venueRequests = '/venue-requests';
}
