/// API Configuration
///
/// Backend API Server: http://34.42.207.250:8000
///
/// IMPORTANT: For Flutter development:
/// - The backend is deployed on GCP Compute Engine
/// - Use the public IP: http://34.42.207.250:8000
/// - For local development, you can use 'http://localhost:8000' if running API locally
///
/// For iOS Simulator/Android Emulator:
/// - Use the public IP: http://34.42.207.250:8000
/// - Or use '10.0.2.2:8000' for Android Emulator if running API locally

class ApiConfig {
  // Backend API URL - GCP Compute Engine instance
  static const String baseUrl = 'http://34.46.123.38:8000';

  // Alternative: Use environment variables
  // static const String baseUrl = const String.fromEnvironment(
  //   'API_URL',
  //   defaultValue: 'http://34.42.207.250:8000',
  // );

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String venues = '/venues';
  static const String venuesCategories = '/venues/categories';
  static const String venuesGrouped = '/venues/grouped';
  static const String favorites = '/users/favorites';
  static const String events = '/events';
}
