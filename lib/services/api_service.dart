import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/venue.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/venue_category.dart';
import '../models/invite.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool isAuthCheck = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool isAuthCheck = false,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final headers = await _getHeaders(isAuthCheck: isAuthCheck);

    if (!isAuthCheck) {
      print('[API] $method $url');
    }

    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          response = await http.get(url, headers: headers);
      }

      if (!isAuthCheck) {
        print('[API] Response status: ${response.statusCode} for $url');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      // Handle error response
      String errorMessage = 'API error: ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          if (errorData['detail'] is List) {
            errorMessage = (errorData['detail'] as List)
                .map((d) => d['msg'] ?? d.toString())
                .join(', ');
          } else {
            errorMessage = errorData['detail'].toString();
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      } catch (e) {
        errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Request failed with status ${response.statusCode}';
      }

      final error = Exception(errorMessage);
      throw error;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Auth API
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      } catch (e) {
        throw Exception('Login error: ${response.statusCode}');
      }
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await _request(
      ApiConfig.register,
      method: 'POST',
      body: {'email': email, 'password': password, 'full_name': fullName},
    );
    return jsonDecode(response.body);
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _request(ApiConfig.me, isAuthCheck: true);
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        throw Exception('Authentication required');
      }
      rethrow;
    }
  }

  // Venues API
  Future<List<Venue>> getVenues({
    String? search,
    String? category,
    double? lat,
    double? lng,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final endpoint = '${ApiConfig.venues}$queryString';

    final response = await _request(endpoint);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Venue.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getVenuesGrouped({
    String? search,
    double? lat,
    double? lng,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final endpoint = '${ApiConfig.venuesGrouped}$queryString';

    final response = await _request(endpoint);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<Venue> getVenue(String venueId, {double? lat, double? lng}) async {
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final endpoint = '${ApiConfig.venues}/$venueId$queryString';

    final response = await _request(endpoint);
    return Venue.fromJson(jsonDecode(response.body));
  }

  Future<List<VenueCategory>> getCategories() async {
    final response = await _request(ApiConfig.venuesCategories);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => VenueCategory.fromJson(json)).toList();
  }

  // Favorites API
  Future<List<Venue>> getFavorites() async {
    final response = await _request(ApiConfig.favorites);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Venue.fromJson(json)).toList();
  }

  Future<void> addFavorite(String venueId) async {
    await _request('${ApiConfig.favorites}/$venueId', method: 'POST');
  }

  Future<void> removeFavorite(String venueId) async {
    await _request('${ApiConfig.favorites}/$venueId', method: 'DELETE');
  }

  // Events API
  Future<List<Event>> getEvents({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (eventType != null) queryParams['event_type'] = eventType;

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final endpoint = '${ApiConfig.events}$queryString';

    final response = await _request(endpoint);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Event.fromJson(json)).toList();
  }

  Future<Event> getEvent(String eventId) async {
    final response = await _request('${ApiConfig.events}/$eventId');
    return Event.fromJson(jsonDecode(response.body));
  }

  // Invite API
  Future<void> sendInvite(String email) async {
    await _request(ApiConfig.invite, method: 'POST', body: {'email': email});
  }

  Future<List<Invite>> getMyInvites() async {
    final response = await _request(ApiConfig.myInvites);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Invite.fromJson(json)).toList();
  }

  Future<void> revokeInvite(String inviteId) async {
    await _request(ApiConfig.revokeInvite(inviteId), method: 'DELETE');
  }
}
