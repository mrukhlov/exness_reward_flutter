/// API Configuration
///
/// Production API is proxied at http://217.217.227.183/api/...
/// (nginx strips `/api` and forwards to the FastAPI container).
///
/// Override at build time:
///   flutter run --dart-define=API_URL=http://localhost:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://217.217.227.183/api',
  );

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
}
